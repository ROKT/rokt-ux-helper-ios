#!/usr/bin/env python3
"""Check coverage selection, unavailable data, and public report contents offline."""

import json
import subprocess  # nosec B404 - only constructs synthetic errors in tests
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import coverage_summary  # noqa: E402 - import follows the sys.path fix-up above


class CoverageSummaryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.bundle = Path(temporary.name) / "Tests.xcresult"
        self.bundle.mkdir()
        patcher = patch("coverage_summary.subprocess.run")
        self.xccov = patcher.start()
        self.addCleanup(patcher.stop)

    def report(self, targets, outcome="success"):
        self.xccov.return_value.stdout = json.dumps(targets)
        return coverage_summary.render(self.bundle, outcome)

    def test_only_production_coverage_is_counted(self):
        report = self.report(
            [
                {
                    "name": "RoktUXHelperTests",
                    "coveredLines": 100,
                    "executableLines": 100,
                },
                {"name": "Dependency", "coveredLines": 100, "executableLines": 100},
                {"name": "RoktUXHelper", "coveredLines": 2, "executableLines": 3},
            ]
        )
        self.assertIn("| RoktUXHelper | 2/3 | 66.67% |", report)
        self.assertNotIn("Dependency", report)
        self.assertNotIn("RoktUXHelperTests", report)
        self.assertNotIn("incomplete", report)

    def test_zero_covered_lines_is_a_real_measurement(self):
        report = self.report(
            [{"name": "RoktUXHelper", "coveredLines": 0, "executableLines": 10}]
        )
        self.assertIn("| RoktUXHelper | 0/10 | 0.00% |", report)

    def test_missing_bundle_is_explicit_and_does_not_run_xccov(self):
        report = coverage_summary.render(self.bundle / "missing")
        self.assertIn("did not produce a result bundle", report)
        self.xccov.assert_not_called()

    def test_xcode_errors_are_unavailable_without_exposing_diagnostics(self):
        errors = [
            FileNotFoundError("synthetic private path"),
            subprocess.CalledProcessError(1, "xccov", stderr="synthetic private path"),
            subprocess.TimeoutExpired("xccov", 60),
        ]
        for error in errors:
            with self.subTest(error=type(error).__name__):
                self.xccov.side_effect = error
                report = coverage_summary.render(self.bundle)
                self.assertIn("Xcode coverage could not be read", report)
                self.assertNotIn("synthetic private path", report)

    def test_invalid_json_is_unavailable(self):
        self.xccov.return_value.stdout = "not JSON"
        self.assertIn("could not be read", coverage_summary.render(self.bundle))

    def test_invalid_report_shape_is_unavailable(self):
        for targets in ({"targets": []}, [None], ["RoktUXHelper"]):
            with self.subTest(targets=targets):
                self.assertIn("invalid coverage report", self.report(targets))

    def test_missing_or_ambiguous_target_is_unavailable(self):
        self.assertIn("no coverage was reported for RoktUXHelper", self.report([]))
        self.assertIn(
            "multiple coverage entries",
            self.report([{"name": "RoktUXHelper"}, {"name": "RoktUXHelper"}]),
        )

    def test_invalid_or_empty_line_counts_do_not_become_percentages(self):
        for covered, total in (
            (None, 2),
            (1, None),
            (True, 2),
            (-1, 2),
            (3, 2),
            (1, "2"),
        ):
            with self.subTest(covered=covered, total=total):
                report = self.report(
                    [
                        {
                            "name": "RoktUXHelper",
                            "coveredLines": covered,
                            "executableLines": total,
                        }
                    ]
                )
                self.assertIn("invalid line counts", report)
                self.assertNotIn("| Target |", report)
        report = self.report(
            [{"name": "RoktUXHelper", "coveredLines": 0, "executableLines": 0}]
        )
        self.assertIn("no executable lines", report)
        self.assertNotIn("0.00%", report)

    def test_unsuccessful_runs_keep_coverage_but_warn_it_may_be_incomplete(self):
        for outcome in ("failure", "cancelled", "skipped", "unknown"):
            with self.subTest(outcome=outcome):
                report = self.report(
                    [{"name": "RoktUXHelper", "coveredLines": 1, "executableLines": 2}],
                    outcome,
                )
                self.assertIn("| RoktUXHelper | 1/2 | 50.00% |", report)
                self.assertIn(f"Test outcome: **{outcome}**", report)
                self.assertIn("Coverage may be incomplete", report)

    def test_report_identifies_its_measurement(self):
        self.xccov.return_value.stdout = "[]"
        report = coverage_summary.render(
            self.bundle, "success", "a" * 40, "https://example.com/run/1"
        )
        self.assertTrue(report.startswith("<!-- ux-helper-coverage-report -->\n"))
        self.assertIn(f"Measured commit: `{'a' * 40}`", report)
        self.assertIn("[Workflow run](https://example.com/run/1)", report)
        self.assertNotIn(str(self.bundle), report)


if __name__ == "__main__":
    unittest.main()
