#!/usr/bin/env python3
"""Print advisory line coverage for RoktUXHelper from an Xcode result bundle.

Usage: python3 tools/coverage_summary.py Tests.xcresult --test-outcome success

Unit, component, and snapshot tests run together and contribute to this one production
target's coverage. Only aggregate counts are published; Xcode diagnostics and local paths
are deliberately omitted from the report.
"""

import argparse
import json
import subprocess  # nosec B404 - fixed argv below, without a shell
from pathlib import Path

TARGET = "RoktUXHelper"
MARKER = "<!-- ux-helper-coverage-report -->"


def coverage_table(bundle):
    """Return a Markdown table, or an explicit reason coverage is unavailable."""
    if not bundle.is_dir():
        return "Coverage unavailable: the test run did not produce a result bundle."

    try:
        result = subprocess.run(  # nosec B603 B607 - xcrun comes from the active Xcode
            [
                "xcrun",
                "xccov",
                "view",
                "--report",
                "--only-targets",
                "--json",
                str(bundle.resolve()),
            ],
            capture_output=True,
            text=True,
            check=True,
            timeout=60,
        )
        targets = json.loads(result.stdout)
    except (OSError, subprocess.SubprocessError, ValueError):
        return "Coverage unavailable: Xcode coverage could not be read."

    if not isinstance(targets, list) or any(
        not isinstance(target, dict) for target in targets
    ):
        return "Coverage unavailable: Xcode returned an invalid coverage report."

    matches = [target for target in targets if target.get("name") == TARGET]
    if not matches:
        return f"Coverage unavailable: no coverage was reported for {TARGET}."
    if len(matches) != 1:
        return f"Coverage unavailable: multiple coverage entries were reported for {TARGET}."

    covered = matches[0].get("coveredLines")
    total = matches[0].get("executableLines")
    if type(covered) is not int or type(total) is not int or not 0 <= covered <= total:
        return "Coverage unavailable: Xcode returned invalid line counts."
    if total == 0:
        return f"Coverage unavailable: {TARGET} has no executable lines."

    return (
        "| Target | Covered lines | Coverage |\n"
        "| --- | ---: | ---: |\n"
        f"| {TARGET} | {covered}/{total} | {covered / total:.2%} |"
    )


def render(bundle, test_outcome="unknown", commit=None, run_url=None):
    """Render the same safe summary for the job, artifact, and PR comment."""
    parts = [
        MARKER,
        "## Code coverage",
        "",
        "Combined unit, UI component, and snapshot test coverage. Advisory only.",
        "",
        coverage_table(bundle),
        "",
        f"Test outcome: **{test_outcome}**.",
    ]
    if test_outcome != "success":
        parts += [
            "Coverage may be incomplete because the test run did not report success."
        ]
    if commit:
        parts += ["", f"Measured commit: `{commit}`."]
    if run_url:
        parts += ["", f"[Workflow run]({run_url})"]
    return "\n".join(parts) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "bundle", type=Path, help="Xcode result bundle collected with coverage"
    )
    parser.add_argument(
        "--test-outcome",
        choices=("success", "failure", "cancelled", "skipped", "unknown"),
        default="unknown",
    )
    parser.add_argument("--commit", help="commit measured by the test run")
    parser.add_argument("--run-url", help="workflow run URL")
    args = parser.parse_args()
    print(render(args.bundle, args.test_outcome, args.commit, args.run_url), end="")


if __name__ == "__main__":
    main()
