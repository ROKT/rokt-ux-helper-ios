#!/usr/bin/env python3
"""Check that a fully nested layout still fits on the stack the transform runs on.

Transforming a layout is a recursive descent, so the stack it needs is roughly the cost of one
level multiplied by how deep the tree is allowed to go. Every term in that product lives in this
repository: `WideStack.defaultStackSize` is the stack available, `LayoutDepthCounter.maxNestingDepth`
caps the depth, and the compiler decides what each level reserves. This script measures the last
one and multiplies out, so a regression fails a build while it is still a number rather than a
crash in a partner's app.

One level is three frames, all live while the next level runs: `transform(_:context:)`, the builder
for the node being descended through, and `transformChildren`. Builders that do not recurse, and
everything they call, are reached at one level and return before the descent continues, so they are
reported but not multiplied.

The budget is a quarter of the stack rather than all of it. The remaining three quarters hold the
deepest level's leaf work, the decode that shares the same stack, and headroom for a compiler that
lays frames out differently. Keeping the gate well below the fatal number is the point: the depth
cap multiplies a per-level regression by 64, so the margin is what buys a chance to notice.

Frame size comes from the `sub sp, sp, #N` instructions arm64 emits in a prologue. Measure a Debug
build: at `-Onone` the compiler gives every local a distinct slot, which is both the worst case and
what a partner debugging an integration actually runs.

Usage:
    tools/frame_budget.py DerivedData/Build/Products/Debug-iphoneos/RoktUXHelper.o
"""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess  # nosec B404 - fixed argv below, no shell and no caller-supplied arguments
import sys
from collections import OrderedDict

# Share of the transform's stack the descent itself may use; see the module docstring.
DEFAULT_BUDGET_SHARE = 0.25

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SERVICES_DIR = REPO_ROOT / "Sources" / "RoktUXHelper" / "Services"
TRANSFORMER_DIR = SERVICES_DIR / "LayoutTransformer"
TRANSFORMER_SOURCE = TRANSFORMER_DIR / "LayoutTransformer.swift"
NODES_SOURCE = TRANSFORMER_DIR / "LayoutTransformer+Nodes.swift"
INLINE_SOURCE = TRANSFORMER_DIR / "LayoutTransformer+Inline.swift"
WIDE_STACK_SOURCE = SERVICES_DIR / "WideStack.swift"

SYMBOL_RE = re.compile(r"^([A-Za-z_$][\w$.]*):$")
# otool -tvV renders an instruction as: <hex address> TAB <mnemonic> TAB <operands>
INSTRUCTION_RE = re.compile(r"^[0-9a-f]{8,16}\t(\S+)\t?(.*)$")
# `sub sp, sp, #0x120` and the shifted form `sub sp, sp, #1, lsl #12`
SUB_SP_RE = re.compile(r"^sp,\s*sp,\s*#(0x[0-9a-f]+|\d+)(?:,\s*lsl\s*#(\d+))?")

DEPTH_CAP_RE = re.compile(r"maxNestingDepth\s*=\s*(\d+)")
# `defaultStackSize = 8 * 1024 * 1024`
STACK_SIZE_RE = re.compile(r"defaultStackSize\s*=\s*([\d\s*]+)")
# Each builder starts at its @inline(never) attribute and runs to the next one.
BUILDER_RE = re.compile(r"@inline\(never\)\s*\n\s*func (transform\w+)\(")
# A function definition, optionally generic (`func f<T>(...)`). Stops at the opening paren of its
# parameter list; `_function_bodies` walks forward from there to find where the body itself starts.
FUNC_DEF_RE = re.compile(r"\bfunc\s+(\w+)\s*(?:<[^>]*>)?\s*\(")
NEXT_FUNC_RE = re.compile(r"\bfunc\s+\w+")
# A call, or an enum case pattern match (`.foo(`) — both look the same from a name and an open
# paren, and treating a case match as an edge in the call graph is harmless: it can only ever add
# a name that was never a real function, which `recursive_builders` filters out by intersecting
# with the builders it already found.
CALL_NAME_RE = re.compile(r"\b(\w+)\(")

DISPATCH_SYMBOL = (
    "LayoutTransformer.transform(_: DcuiSchema.LayoutSchemaModel, context:"
)
CHILDREN_SYMBOL = (
    "LayoutTransformer.transformChildren(_: [DcuiSchema.LayoutSchemaModel]?, context:"
)


def disassemble(object_path: str) -> str:
    # -arch arm64 because the prologue pattern below is arm64, and because a build for a generic
    # destination is multi-architecture: without it the same symbol is read once per slice.
    result = (
        subprocess.run(  # nosec B603 B607 - xcrun is resolved from the active toolchain
            ["xcrun", "otool", "-arch", "arm64", "-tvV", object_path],
            capture_output=True,
            text=True,
            check=True,
        )
    )
    return result.stdout


def frame_sizes(disassembly: str, prologue_window: int) -> "OrderedDict[str, int]":
    """Sum the stack reserved by each symbol's prologue, keyed by mangled symbol name."""
    sizes: OrderedDict[str, int] = OrderedDict()
    symbol: str | None = None
    instructions = 0

    for line in disassembly.splitlines():
        label = SYMBOL_RE.match(line)
        if label:
            symbol = label.group(1)
            instructions = 0
            sizes.setdefault(symbol, 0)
            continue

        if symbol is None:
            continue

        instruction = INSTRUCTION_RE.match(line)
        if not instruction:
            continue

        instructions += 1
        if instructions > prologue_window:
            continue

        mnemonic, operands = instruction.groups()
        if mnemonic != "sub":
            continue
        operand = SUB_SP_RE.match(operands)
        if not operand:
            continue

        immediate = int(operand.group(1), 0)
        if operand.group(2):
            immediate <<= int(operand.group(2))
        sizes[symbol] += immediate

    return sizes


def demangle(symbols: list[str]) -> dict[str, str]:
    if not symbols:
        return {}
    # otool prints Mach-O symbol names with the leading underscore the linker adds.
    stripped = [symbol.lstrip("_") for symbol in symbols]
    result = (
        subprocess.run(  # nosec B603 B607 - xcrun is resolved from the active toolchain
            ["xcrun", "swift-demangle", "-compact"],
            input="\n".join(stripped),
            capture_output=True,
            text=True,
            check=True,
        )
    )
    demangled = result.stdout.splitlines()
    # Demangling is line for line. Pairing a short result positionally would attribute one
    # symbol's frame size to a different symbol, so stop rather than report a wrong number.
    if len(demangled) != len(stripped):
        raise SystemExit(
            f"error: demangled {len(demangled)} names for {len(stripped)} symbols"
        )
    return {symbol: demangled[index] for index, symbol in enumerate(symbols)}


def depth_cap() -> int:
    match = DEPTH_CAP_RE.search(TRANSFORMER_SOURCE.read_text())
    if not match:
        raise SystemExit(f"error: no maxNestingDepth found in {TRANSFORMER_SOURCE}")
    return int(match.group(1))


def stack_size() -> int:
    match = STACK_SIZE_RE.search(WIDE_STACK_SOURCE.read_text())
    if not match:
        raise SystemExit(f"error: no defaultStackSize found in {WIDE_STACK_SOURCE}")
    size = 1
    for factor in match.group(1).split("*"):
        size *= int(factor.strip())
    return size


def _function_bodies(source: str) -> "dict[str, str]":
    """Map each function name in `source` to its body, matched brace by brace.

    A regex can find where a function starts but not, in general, where it ends: nested braces
    (closures, `switch`, control flow) need counting, not pattern matching. A definition with no
    body of its own — a protocol requirement, an `@objc` bridging overload — is recognised by the
    next `func` keyword arriving before any `{`, and is left out rather than mistakenly paired with
    some later function's body.
    """
    bodies: "dict[str, str]" = {}
    for match in FUNC_DEF_RE.finditer(source):
        name = match.group(1)

        # Walk past the parameter list by counting parens, so a default argument's own closure
        # (`= { }`) cannot be mistaken for the end of the parameter list.
        depth = 1
        pos = match.end()
        while pos < len(source) and depth > 0:
            if source[pos] == "(":
                depth += 1
            elif source[pos] == ")":
                depth -= 1
            pos += 1
        if depth != 0:
            continue

        next_func = NEXT_FUNC_RE.search(source, pos)
        brace_start = source.find("{", pos)
        if brace_start == -1 or (next_func and next_func.start() < brace_start):
            continue

        depth = 0
        end = brace_start
        for end in range(brace_start, len(source)):
            if source[end] == "{":
                depth += 1
            elif source[end] == "}":
                depth -= 1
                if depth == 0:
                    break
        else:
            continue
        bodies[name] = source[brace_start : end + 1]
    return bodies


def recursive_builders() -> set[str]:
    """The builders that descend, directly or through a forwarding helper, read from source.

    Taken from the source rather than from a list kept here, so a builder that starts recursing —
    including one that starts forwarding through a helper that itself recurses — is counted from
    the commit that makes it recurse. Resolved across the files that actually implement the descent
    rather than just the one that defines the builders, because some builders reach
    `transformChildren` indirectly: `transformNonInteractiveChildren` (`LayoutTransformer+Inline.swift`)
    and `getAccessibilityGrouped` (`LayoutTransformer.swift`) both call it on a builder's behalf.

    Deliberately not every `*.swift` file in the directory: it also holds style adapters
    (`StyleTransformer.swift`, `SchemaStyleAdapter.swift`, ...) that are unrelated to the descent but
    reuse common words as parameter names — `states(_:transform:)` in `SchemaStyleAdapter.swift`
    takes a closure literally named `transform` — and a call-graph resolver keyed on bare
    identifiers can't tell that apart from a call to `LayoutTransformer.transform`. Naming the three
    files that do participate avoids that collision rather than trying to resolve it.
    """
    nodes_source = NODES_SOURCE.read_text()
    starts = [(m.start(), m.group(1)) for m in BUILDER_RE.finditer(nodes_source)]
    if not starts:
        raise SystemExit(f"error: no @inline(never) builders found in {NODES_SOURCE}")
    builder_names = {name for _, name in starts}

    bodies = _function_bodies(nodes_source)
    for source in (TRANSFORMER_SOURCE, INLINE_SOURCE):
        if source == NODES_SOURCE:
            continue
        bodies.update(_function_bodies(source.read_text()))

    # A function reaches `transformChildren` if it calls it directly, or calls something that does.
    # Fixed-point rather than one hop, so a helper that itself forwards through another helper is
    # still resolved correctly regardless of how many hops away it is.
    reaches_children = {
        name for name, body in bodies.items() if "transformChildren(" in body
    }
    changed = True
    while changed:
        changed = False
        for name, body in bodies.items():
            if name in reaches_children:
                continue
            if any(callee in reaches_children for callee in CALL_NAME_RE.findall(body)):
                reaches_children.add(name)
                changed = True

    return builder_names & reaches_children


def largest(frames: dict[str, int], predicate) -> tuple[str, int]:
    matches = [(name, size) for name, size in frames.items() if predicate(name)]
    if not matches:
        return ("", 0)
    return max(matches, key=lambda entry: entry[1])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("object", help="Mach-O object or binary to disassemble")
    parser.add_argument(
        "--budget",
        type=int,
        default=None,
        # No literal percent sign: argparse %-formats help strings, and 3.14 validates them eagerly.
        help="stack the full-depth descent may use, in bytes "
        "(default: a quarter of WideStack.defaultStackSize)",
    )
    parser.add_argument(
        "--prologue-window",
        type=int,
        default=80,
        help="how many leading instructions of each symbol to scan (default 80)",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=10,
        help="how many off-path frames to list for information (default 10)",
    )
    args = parser.parse_args()

    available = stack_size()
    budget = (
        args.budget
        if args.budget is not None
        else int(available * DEFAULT_BUDGET_SHARE)
    )

    sizes = frame_sizes(disassemble(args.object), args.prologue_window)
    names = demangle(list(sizes))
    frames = {names.get(symbol, symbol): size for symbol, size in sizes.items()}

    dispatch = largest(frames, lambda name: DISPATCH_SYMBOL in name)
    children = largest(frames, lambda name: CHILDREN_SYMBOL in name)
    if not dispatch[0] or not children[0]:
        print(
            f"error: the transform entry points are not in {args.object}. "
            "Wrong object, or a stripped build?",
            file=sys.stderr,
        )
        return 2

    builders = recursive_builders()
    builder = largest(
        frames,
        lambda name: any(f"LayoutTransformer.{b}(" in name for b in builders),
    )
    if not builder[0]:
        print(
            f"error: none of the builders known to recurse are in {args.object}. "
            "Wrong object, or a stripped build?",
            file=sys.stderr,
        )
        return 2
    builder_name = next(b for b in builders if f"LayoutTransformer.{b}(" in builder[0])

    depth = depth_cap()
    per_level = dispatch[1] + builder[1] + children[1]
    total = per_level * depth

    # A zero total means no prologue was recognised, not a descent that costs nothing. Without
    # this the check would pass silently on any build it cannot actually read.
    if per_level == 0:
        print(
            f"error: recognised no stack allocation in {args.object}. Expected arm64 with debug "
            "symbols; an optimised or stripped build cannot be measured.",
            file=sys.stderr,
        )
        return 2

    print(f"{'bytes':>9}  frame reserved at every level")
    print(f"{dispatch[1]:>9,}  transform(_:context:)")
    print(
        f"{builder[1]:>9,}  {builder_name} "
        f"(largest of the {len(builders)} builders that descend)"
    )
    print(f"{children[1]:>9,}  transformChildren(_:context:)")
    print(f"{per_level:>9,}  per level")
    print(
        f"\n{per_level:,} x {depth} levels = {total:,} B, against a {budget:,} B budget "
        f"({total / budget:.0%}) — {DEFAULT_BUDGET_SHARE:.0%} of the {available:,} B "
        "stack the transform runs on"
    )

    on_path = {dispatch[0], builder[0], children[0]}
    off_path = sorted(
        (
            (size, name)
            for name, size in frames.items()
            if name not in on_path
            and size > 8192
            and ("LayoutTransformer" in name or "StyleTransformer" in name)
        ),
        reverse=True,
    )
    if off_path:
        print(
            f"\nReached once rather than once per level, so not multiplied above "
            f"({len(off_path)} transformer frames over 8 KB, largest {args.top} shown):"
        )
        for size, name in off_path[: args.top]:
            print(f"{size:>9,}  {name[:96]}")

    if total > budget:
        print(
            f"\nerror: a fully nested layout would reserve {total:,} B, over the "
            f"{budget:,} B budget.\n"
            "The depth cap and the cost of one level are multiplied together, so this fails "
            "either because a frame on the descent grew or because the cap was raised. Prefer "
            "splitting the function that grew, so that only one branch's locals are live at a "
            "time, over widening the stack: the budget leaves the rest of it for the deepest "
            "level's leaf work and for the decode that shares the same stack.",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
