#!/usr/bin/env python3
"""Unit tests for frame_budget.py's parsing and budget arithmetic.

Runs entirely offline: `disassemble()` and `demangle()` are mocked rather than shelling out to
`xcrun`, and `depth_cap()`/`stack_size()`/`recursive_builders()` read synthetic temp files instead
of this repository's real Swift sources, so a test failure always points at the checker's own logic
rather than at source drift elsewhere in the tree.

Usage:
    python3 -m unittest discover -s tools -p "test_*.py" -v
"""

import contextlib
import io
import pathlib
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import frame_budget  # noqa: E402 - import follows the sys.path fix-up above


class FrameSizesTests(unittest.TestCase):
    def test_normal_prologue_is_summed(self):
        disassembly = (
            "_symbolA:\n"
            "0000000100004000\tsub\tsp, sp, #0x120\n"
            "0000000100004004\tstp\tx29, x30, [sp, #0x110]\n"
        )
        sizes = frame_budget.frame_sizes(disassembly, prologue_window=80)
        self.assertEqual(sizes["_symbolA"], 0x120)

    def test_shifted_immediate_is_decoded(self):
        disassembly = "_symbolB:\n0000000100004000\tsub\tsp, sp, #1, lsl #12\n"
        sizes = frame_budget.frame_sizes(disassembly, prologue_window=80)
        self.assertEqual(sizes["_symbolB"], 1 << 12)

    def test_symbol_with_no_prologue_reports_zero(self):
        disassembly = "_symbolC:\n0000000100004000\tret\t\n"
        sizes = frame_budget.frame_sizes(disassembly, prologue_window=80)
        self.assertEqual(sizes["_symbolC"], 0)

    def test_sub_sp_past_the_window_is_ignored(self):
        disassembly = (
            "_symbolD:\n"
            "0000000100004000\tnop\t\n"
            "0000000100004004\tnop\t\n"
            "0000000100004008\tsub\tsp, sp, #0x40\n"
        )
        sizes = frame_budget.frame_sizes(disassembly, prologue_window=2)
        self.assertEqual(sizes["_symbolD"], 0)


class DemangleTests(unittest.TestCase):
    def test_empty_input_returns_empty_dict(self):
        self.assertEqual(frame_budget.demangle([]), {})

    @patch("frame_budget.subprocess.run")
    def test_maps_stripped_symbols_positionally(self, mock_run):
        mock_run.return_value.stdout = "Foo.bar()\nFoo.baz()\n"
        result = frame_budget.demangle(["_Foo3barSivg", "_Foo3bazSivg"])
        self.assertEqual(
            result, {"_Foo3barSivg": "Foo.bar()", "_Foo3bazSivg": "Foo.baz()"}
        )

    @patch("frame_budget.subprocess.run")
    def test_mismatched_line_count_raises(self, mock_run):
        mock_run.return_value.stdout = "OnlyOneLine\n"
        with self.assertRaises(SystemExit):
            frame_budget.demangle(["_symbolA", "_symbolB"])


class SourceParsingTests(unittest.TestCase):
    def setUp(self):
        tmp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(tmp_dir.cleanup)
        self._tmp_dir = pathlib.Path(tmp_dir.name)

    def _write(self, name: str, content: str) -> pathlib.Path:
        path = self._tmp_dir / name
        path.write_text(content)
        return path

    def test_depth_cap_parses_maxNestingDepth(self):
        source = self._write("Transformer.swift", "static let maxNestingDepth = 64\n")
        with patch.object(frame_budget, "TRANSFORMER_SOURCE", source):
            self.assertEqual(frame_budget.depth_cap(), 64)

    def test_depth_cap_missing_raises(self):
        source = self._write("Transformer.swift", "// no depth cap here\n")
        with patch.object(frame_budget, "TRANSFORMER_SOURCE", source):
            with self.assertRaises(SystemExit):
                frame_budget.depth_cap()

    def test_stack_size_parses_multiplication(self):
        source = self._write(
            "WideStack.swift", "static let defaultStackSize = 8 * 1024 * 1024\n"
        )
        with patch.object(frame_budget, "WIDE_STACK_SOURCE", source):
            self.assertEqual(frame_budget.stack_size(), 8 * 1024 * 1024)

    def test_stack_size_missing_raises(self):
        source = self._write("WideStack.swift", "// no stack size here\n")
        with patch.object(frame_budget, "WIDE_STACK_SOURCE", source):
            with self.assertRaises(SystemExit):
                frame_budget.stack_size()

    def _patch_recursion_sources(
        self, *, nodes: str, transformer: str = "", inline: str = ""
    ) -> None:
        """Patch NODES_SOURCE/TRANSFORMER_SOURCE/INLINE_SOURCE directly, since
        recursive_builders() reads those three names rather than globbing a directory — patching
        TRANSFORMER_DIR alone would leave it reading the real repo's Transformer/Inline files.
        """
        sources = {
            "NODES_SOURCE": self._write("Nodes.swift", nodes),
            "TRANSFORMER_SOURCE": self._write("Transformer.swift", transformer),
            "INLINE_SOURCE": self._write("Inline.swift", inline),
        }
        for name, path in sources.items():
            patcher = patch.object(frame_budget, name, path)
            patcher.start()
            self.addCleanup(patcher.stop)

    def test_recursive_builders_flags_only_descending_ones(self):
        self._patch_recursion_sources(
            nodes=(
                "@inline(never)\n"
                "func transformRow(_ node: RowModel) throws -> UIModel {\n"
                "    return try transformChildren(node.children, context: context)\n"
                "}\n"
                "@inline(never)\n"
                "func transformLeaf(_ node: LeafModel) throws -> UIModel {\n"
                "    return .leaf(node)\n"
                "}\n"
            )
        )
        self.assertEqual(frame_budget.recursive_builders(), {"transformRow"})

    def test_recursive_builders_raises_when_none_found(self):
        self._patch_recursion_sources(nodes="func helper() {}\n")
        with self.assertRaises(SystemExit):
            frame_budget.recursive_builders()

    def test_recursive_builders_detects_recursion_through_a_helper_in_another_file(
        self,
    ):
        """The bug this guards: transformStaticLink et al. forward through
        `transformNonInteractiveChildren`, defined in a sibling file, rather than calling
        `transformChildren` in their own body — the literal-substring check used to miss all of
        them.
        """
        self._patch_recursion_sources(
            nodes=(
                "@inline(never)\n"
                "func transformStaticLink(_ node: StaticLinkModel) throws -> UIModel {\n"
                "    return .staticLink(children: try transformNonInteractiveChildren(node.children, context: context))\n"
                "}\n"
                "@inline(never)\n"
                "func transformLeaf(_ node: LeafModel) throws -> UIModel {\n"
                "    return .leaf(node)\n"
                "}\n"
            ),
            inline=(
                "func transformNonInteractiveChildren(_ children: [LayoutSchemaModel], context: Context) "
                "throws -> [LayoutSchemaViewModel]? {\n"
                "    return try transformChildren(children, context: context)\n"
                "}\n"
            ),
        )
        self.assertEqual(frame_budget.recursive_builders(), {"transformStaticLink"})

    def test_recursive_builders_follows_two_hops_of_forwarding(self):
        self._patch_recursion_sources(
            nodes=(
                "@inline(never)\n"
                "func transformAccessibilityGrouped(_ layout: LayoutSchemaModel, context: Context) throws -> UIModel {\n"
                "    return try getAccessibilityGrouped(child: layout, context: context)\n"
                "}\n"
            ),
            transformer=(
                "func getAccessibilityGrouped(child: AccessibilityGroupedLayoutChildren, context: Context) throws -> UIModel {\n"
                "    return try forwardOnceMore(child, context: context)\n"
                "}\n"
                "func forwardOnceMore(_ child: AccessibilityGroupedLayoutChildren, context: Context) throws -> UIModel {\n"
                "    return try transformChildren(child.children, context: context)\n"
                "}\n"
            ),
        )
        self.assertEqual(
            frame_budget.recursive_builders(), {"transformAccessibilityGrouped"}
        )

    def test_recursive_builders_ignores_a_helper_that_never_reaches_children(self):
        self._patch_recursion_sources(
            nodes=(
                "@inline(never)\n"
                "func transformCloseButton(_ node: CloseButtonModel) throws -> UIModel {\n"
                "    return .closeButton(try resolveAccessibilityLabel(node.a11yLabel, context: context))\n"
                "}\n"
            ),
            inline=(
                "func resolveAccessibilityLabel(_ value: String?, context: Context) throws -> String? {\n"
                "    guard let value else { return nil }\n"
                "    return value\n"
                "}\n"
            ),
        )
        self.assertEqual(frame_budget.recursive_builders(), set())

    def test_recursive_builders_ignores_an_unrelated_functions_shadowed_parameter_name(
        self,
    ):
        """The bug this guards: a call-graph resolver keyed on bare identifiers can't tell a call
        to `LayoutTransformer.transform` apart from a call to an unrelated closure PARAMETER that
        happens to also be named `transform` — recursive_builders() avoids this by only resolving
        calls within the three files that implement the descent, not every file in the directory.
        """
        self._patch_recursion_sources(
            nodes=(
                "@inline(never)\n"
                "func transformInlineContainer(_ node: InlineContainerModel) throws -> UIModel {\n"
                "    return .inlineContainer(try getInlineContainer(node))\n"
                "}\n"
            ),
            transformer=(
                "func getInlineContainer(_ node: InlineContainerModel) throws -> UIModel {\n"
                "    return try SchemaStyleAdapter.inlineContainer(node)\n"
                "}\n"
                "enum SchemaStyleAdapter {\n"
                "    static func inlineContainer(_ node: InlineContainerModel) throws -> UIModel {\n"
                "        return try states(node, transform: { $0 })\n"
                "    }\n"
                "    static func states<T, U>(_ node: T, transform: (T) throws -> U) throws -> U {\n"
                "        return try transform(node)\n"
                "    }\n"
                "}\n"
            ),
        )
        self.assertEqual(frame_budget.recursive_builders(), set())


class FunctionBodiesTests(unittest.TestCase):
    def test_extracts_body_through_nested_braces(self):
        source = "func foo() {\n    if true {\n        doSomething()\n    }\n}\n"
        bodies = frame_budget._function_bodies(source)
        self.assertIn("foo", bodies)
        self.assertIn("doSomething()", bodies["foo"])

    def test_handles_a_generic_parameter_list(self):
        source = "func foo<T: Codable>(_ value: T) {\n    bar()\n}\n"
        bodies = frame_budget._function_bodies(source)
        self.assertIn("foo", bodies)
        self.assertIn("bar()", bodies["foo"])

    def test_skips_a_default_argument_closures_braces_when_finding_the_body(self):
        source = "func foo(onDone: () -> Void = { }) {\n    real()\n}\n"
        bodies = frame_budget._function_bodies(source)
        self.assertIn("foo", bodies)
        self.assertIn("real()", bodies["foo"])

    def test_a_declaration_with_no_body_is_not_paired_with_a_later_functions_body(self):
        source = "func foo() -> Int\nfunc bar() {\n    unrelated()\n}\n"
        bodies = frame_budget._function_bodies(source)
        self.assertNotIn("foo", bodies)
        self.assertIn("bar", bodies)
        self.assertIn("unrelated()", bodies["bar"])


class LargestTests(unittest.TestCase):
    def test_returns_the_largest_match(self):
        frames = {"A.foo": 10, "B.foo": 20, "A.bar": 5}
        self.assertEqual(
            frame_budget.largest(frames, lambda name: name.startswith("A.")),
            ("A.foo", 10),
        )

    def test_returns_empty_when_nothing_matches(self):
        self.assertEqual(
            frame_budget.largest({"A": 1}, lambda name: name == "Z"), ("", 0)
        )


class MainTests(unittest.TestCase):
    """End-to-end `main()` runs with disassemble/demangle mocked and no real xcrun calls."""

    def _patch(self, target: str, **kwargs) -> None:
        patcher = patch.object(frame_budget, target, **kwargs)
        patcher.start()
        self.addCleanup(patcher.stop)

    def _mock_transform_entry_points(
        self, *, dispatch_bytes: int, builder_bytes: int, children_bytes: int
    ) -> None:
        disassembly = (
            "_dispatch:\n"
            f"0000000100004000\tsub\tsp, sp, #{dispatch_bytes}\n"
            "_builder:\n"
            f"0000000100004000\tsub\tsp, sp, #{builder_bytes}\n"
            "_children:\n"
            f"0000000100004000\tsub\tsp, sp, #{children_bytes}\n"
        )
        demangled = {
            "_dispatch": frame_budget.DISPATCH_SYMBOL,
            "_builder": "LayoutTransformer.transformRow(_ node: RowModel) throws -> UIModel",
            "_children": frame_budget.CHILDREN_SYMBOL,
        }
        self._patch("disassemble", return_value=disassembly)
        self._patch("demangle", return_value=demangled)
        self._patch("recursive_builders", return_value={"transformRow"})

    def _run_main(self) -> tuple[int, str, str]:
        stdout, stderr = io.StringIO(), io.StringIO()
        with patch.object(sys, "argv", ["frame_budget.py", "dummy.o"]):
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                code = frame_budget.main()
        return code, stdout.getvalue(), stderr.getvalue()

    def test_under_budget_returns_0(self):
        self._mock_transform_entry_points(
            dispatch_bytes=100, builder_bytes=100, children_bytes=100
        )
        self._patch("depth_cap", return_value=10)
        self._patch("stack_size", return_value=100_000)

        code, _, _ = self._run_main()

        self.assertEqual(code, 0)

    def test_over_budget_returns_1_with_remediation_message(self):
        self._mock_transform_entry_points(
            dispatch_bytes=100, builder_bytes=100, children_bytes=100
        )
        self._patch("depth_cap", return_value=10)
        self._patch("stack_size", return_value=1_000)

        code, _, stderr = self._run_main()

        self.assertEqual(code, 1)
        self.assertIn("over the", stderr)
        self.assertIn("250 B budget", stderr)

    def test_missing_transform_entry_points_returns_2(self):
        disassembly = "_unrelated:\n0000000100004000\tsub\tsp, sp, #0x10\n"
        self._patch("disassemble", return_value=disassembly)
        self._patch("demangle", return_value={"_unrelated": "SomeOther.func()"})
        self._patch("stack_size", return_value=1_000)

        code, _, stderr = self._run_main()

        self.assertEqual(code, 2)
        self.assertIn("Wrong object, or a stripped build", stderr)

    def test_unmeasurable_build_returns_2(self):
        self._mock_transform_entry_points(
            dispatch_bytes=0, builder_bytes=0, children_bytes=0
        )
        self._patch("depth_cap", return_value=10)
        self._patch("stack_size", return_value=1_000)

        code, _, stderr = self._run_main()

        self.assertEqual(code, 2)
        self.assertIn("cannot be measured", stderr)

    def test_no_matching_builder_symbol_returns_2_instead_of_crashing(self):
        """Regression test: `recursive_builders()` naming a builder that isn't in the object (a
        renamed/refactored builder, or source drift) used to raise an uncaught `StopIteration`
        instead of the tool's own diagnostic.
        """
        disassembly = (
            "_dispatch:\n"
            "0000000100004000\tsub\tsp, sp, #100\n"
            "_children:\n"
            "0000000100004000\tsub\tsp, sp, #100\n"
        )
        demangled = {
            "_dispatch": frame_budget.DISPATCH_SYMBOL,
            "_children": frame_budget.CHILDREN_SYMBOL,
        }
        self._patch("disassemble", return_value=disassembly)
        self._patch("demangle", return_value=demangled)
        self._patch("recursive_builders", return_value={"transformRenamedAway"})
        self._patch("stack_size", return_value=1_000)

        code, _, stderr = self._run_main()

        self.assertEqual(code, 2)
        self.assertIn("Wrong object, or a stripped build", stderr)


if __name__ == "__main__":
    unittest.main()
