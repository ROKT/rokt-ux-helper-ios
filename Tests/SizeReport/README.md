# RoktUXHelper Size Report

Measures how much `RoktUXHelper` adds to an app's size by comparing a bare
SwiftUI app against the same app with the dependency integrated. The number is
indicative for partners deciding to adopt the SDK.

## How it works

1. `measure_size.sh` builds two apps with `xcodebuild archive` (Release):
   - **SizeTestApp** — a bare SwiftUI app with no dependencies (baseline).
   - **SizeTestAppWithUXHelper** — the same app plus `RoktUXHelper`, referenced
     via a local SPM package pointing at the repository root, so local source
     changes are measured automatically.
2. It reports the app-bundle size delta (the "helper impact") and the main
   executable delta. `RoktUXHelper` links statically, so its code lands in the
   app's executable; any resource bundle it ships is reported separately.

## Usage

```bash
./measure_size.sh                    # Human-readable output
./measure_size.sh --json             # Single-line JSON (used by CI)
./measure_size.sh --with-helper-only # Only build/measure the with-helper app
```

## CI integration

`.github/workflows/ci-size-report.yml` runs on pull requests. It builds the two
apps on both the PR branch and the target branch, computes the change in helper
impact, and posts (or updates) a sticky comment on the PR.
