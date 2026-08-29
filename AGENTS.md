# Agent Guide

Instructions for AI coding agents (Claude Code, Codex, etc.) working in this repository. It carries
only what you cannot get from the repository itself: read `Package.swift`, `.swiftlint.yml`,
`.trunk/trunk.yaml`, and `.github/workflows/` for versions, dependencies, and lint rules, and `ls`
for the layout. Human docs: [README.md](./README.md) (architecture, schema bumps),
[TESTING.md](./TESTING.md) (snapshot workflow, CI toolchain pins), [RELEASING.md](./RELEASING.md),
[MIGRATING.md](./MIGRATING.md).

<!-- COMMON SECTION - kept in sync by hand with ROKT/rokt-ux-helper-android's AGENTS.md.
     Change it in both repositories or in neither. -->

## Confidentiality — this is a public repository

Everything committed here is permanent and world-readable: code, comments, commit messages, branch
names, PR titles and descriptions (titles also become public release-note entries), and test names.
Never include:

- Partner, client, customer, or advertiser names or identifiers, or any detail that could identify
  one — account/tenant/campaign IDs, deal terms, integration specifics. Keep examples anonymized.
- Internal service/system names, internal contract/class names, or their field layouts.
- Backend or infrastructure detail: serializer libraries and versions, server-side
  validation/deserialization behavior, datastore/infra specifics, or how a payload is checked
  server-side.
- Links to private repos, internal tickets/PRs, or internal dashboards.

Describe client-side behavior only, in partner-facing terms. When a change is driven by a server
contract, say so generically ("to match the server contract") without naming internal types,
versions, or server behavior. Keep internal rationale in non-public channels.

<!-- END COMMON SECTION -->

## Commands

In Xcode: `open Package.swift`, then `⌘U`. From the CLI, substituting the CI simulator model and
runtime for `<model>`/`<runtime>` (see trap 3):

```bash
# tests; append -only-testing:RoktUXHelperTests/TestRowComponent to scope to one suite
set -o pipefail && xcodebuild -skipPackagePluginValidation -scheme RoktUXHelper \
  -destination 'platform=iOS Simulator,name=<model>,OS=<runtime>' \
  -derivedDataPath DerivedData test

trunk check --all && trunk fmt --all          # the lint gate; see trap 6

xcodebuild -project Example/Example.xcodeproj -scheme Example \
  -destination 'platform=iOS Simulator,name=<model>,OS=<runtime>' build
```

### Command traps

1. **`swift build` and `swift test` cannot work here.** `Sources/` imports `UIKit` unguarded and SPM
   builds for the host platform, so both fail immediately with
   `error: no such module 'UIKit'`. Everything goes through `xcodebuild` with an iOS Simulator
   destination.
2. **Keep `set -o pipefail` in front of any `xcodebuild … | xcbeautify`** or the pipeline's status is
   the formatter's and a failed build reports success. CI does this in
   `.github/composite_actions/run_xcodebuild_tests/action.yml`; copy that shape.
3. **Put the OS in `-destination`, not just the model.** Snapshot PNGs are valid only for the Xcode +
   iOS runtime pair CI uses, and CI reads that pair from repository Actions variables
   (`CI_XCODE_VERSION`, `CI_SIMULATOR_MODEL`, `CI_SIMULATOR_OS`) that a checkout cannot see —
   TESTING.md records their current values. A `name=`-only destination resolves against whatever
   runtimes you happen to have installed, and every snapshot test then "fails" with nothing broken.
4. **`isRecording` is deprecated in the pinned `swift-snapshot-testing`.** Delete the stale PNG and
   re-run, or wrap the assertion in `withSnapshotTesting(record: .all) { … }`. Never commit a
   record-mode override; it disables regression detection for that test.
5. **A CLI re-record needs the `TEST_RUNNER_` prefix on the variable:**
   `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild … test`. The test bundle runs inside the
   simulator, so a bare `SNAPSHOT_TESTING_RECORD` never reaches it — that prefix is why the CI action
   passes `TEST_RUNNER_SNAPSHOT_ARTIFACTS` to collect failure diffs.
6. **`trunk` is the lint gate and it checks the whole repository.**
   `.github/workflows/pull-request.yml` runs trunk-action with `check-mode: all`, so a pre-existing
   violation in a file you never touched fails your PR. Three scoping surprises: SwiftFormat's
   config is `.trunk/configs/.swiftformat`, so calling `swiftformat` directly applies different
   rules; `.swiftlint.yml` excludes `Tests`, so
   SwiftLint never sees test code; and Markdown is formatted by prettier, because
   `.trunk/configs/.markdownlint.yaml` turns markdownlint's formatting rules off.
7. **No workflow builds `Example/`** — nothing under `.github/` references it, so breaking the
   example app is invisible to CI. Build it yourself if you changed public API or rendering.
8. **The size report cannot fail your PR.** Both measurement steps in
   `.github/workflows/ci-size-report.yml` are `continue-on-error` and degrade to `N/A`, and the job
   is not in `pr-notify`'s `needs`. Read its comment as information, not as a gate.

## Pull requests

- Base branch is `main`.
- Conventional-commit PR titles, with `!` **after** the scope for a breaking change:
  `feat(offers)!: …`, not `feat!(offers): …`. Both spellings are in the history, so do not copy a
  neighboring commit blindly.
- **Nothing in CI validates the title**, and the changelog is generated from it, so a malformed title
  silently produces a malformed public release note. Branch names use the same convention by habit;
  no gate enforces that either.
- `SchemaVersionConsistencyTests` guards `Constants.layoutSchemaVersion` in
  `Sources/RoktUXHelper/Data/Model/RoktIntegrationInfoDetails.swift` against the `dcui-swift-schema`
  pin in `Package.swift` — move both together (README has the steps). Nothing guards
  `RoktUXHelper.podspec`'s deployment target against `Package.swift`'s `platforms`; `pod lib lint`
  only checks the podspec against itself.
- Update [MIGRATING.md](./MIGRATING.md) when you rename or remove a public symbol.

## Files the release workflow owns — do not hand-edit

`CHANGELOG.md`, `VERSION`, and `RoktUXHelper.podspec`'s `s.version` are written by the
`Release – Draft` workflow, which runs by manual dispatch from `main` or `maintenance/*` only. Edits
on a feature branch are overwritten when the next release PR is drafted; the way into the changelog
is the PR title. See [RELEASING.md](./RELEASING.md).

Reference PNGs under `Tests/**/__Snapshots__/` are committed on purpose. Regenerate them only when
you intended the visual change, and look at each one before committing.
