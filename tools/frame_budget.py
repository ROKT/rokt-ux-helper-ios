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
    tools/frame_budget.py DerivedData/Build/Products/Debug-iphonesimulator/RoktUXHelper.o
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


def recursive_builders() -> set[str]:
    """The builders that descend, read from the file that defines them.

    Taken from the source rather than from a list kept here, so a builder that starts recursing is
    counted from the commit that makes it recurse.
    """
    source = NODES_SOURCE.read_text()
    starts = [(m.start(), m.group(1)) for m in BUILDER_RE.finditer(source)]
    if not starts:
        raise SystemExit(f"error: no @inline(never) builders found in {NODES_SOURCE}")

    bounds = [s for s, _ in starts] + [len(source)]
    return {
        name
        for index, (_, name) in enumerate(starts)
        if "transformChildren(" in source[bounds[index] : bounds[index + 1]]
    }


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
