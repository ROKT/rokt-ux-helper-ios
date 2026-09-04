# Testing Guide

## Native testing workflow

Read [the public-content checklist](./docs/public-content-checklist.md) before preparing fixtures
or sharing test output. Tests and their generated artifacts must not publish Rokt-internal
information, secrets, or PII.

1. **Identify the candidate.** Record the helper revision, dependency versions and any local
   overrides. Preserve existing changes; use an isolated checkout for a different candidate.
   A passing result from another branch or dependency graph does not validate this one.
2. **Check the environment without changing it:**

   ```bash
   xcode-select -p
   xcodebuild -version
   xcrun simctl list runtimes
   xcrun simctl list devices available
   ```

   Compare with [the current CI configuration](#environment-sensitivity). If Xcode setup,
   license acceptance, or a runtime installation is incomplete, arrange that explicitly; do not
   repeatedly download runtimes or accept agreements on another user's behalf.

3. **Agree on simulator ownership.** Select one installed destination by identifier. Do not run
   automated UI tests on a simulator being used for manual review, or shut down/reset unrelated
   simulators. Serial testing avoids parallel test clones interfering with that review.
4. **Run the affected suite, then the full package suite for code changes.** From the repository
   root, replace the placeholder with the selected simulator identifier:

   ```bash
   TEST_DESTINATION='platform=iOS Simulator,id=<simulator-udid>'
   TEST_OUTPUT=$(mktemp -d "${TMPDIR:-/tmp}/rokt-ux-tests.XXXXXX")
   xcodebuild -skipPackagePluginValidation -scheme RoktUXHelper \
     -destination "$TEST_DESTINATION" \
     -parallel-testing-enabled NO \
     -derivedDataPath "$TEST_OUTPUT/DerivedData" \
     -resultBundlePath "$TEST_OUTPUT/Tests.xcresult" test
   ```

   Add `-only-testing:RoktUXHelperTests/TestRowComponent` to target an existing suite. Use a fresh
   result path for each run. If piping output to `xcbeautify`, enable `set -o pipefail` first so a
   failing build remains a failing command. Do not use host `swift build` or `swift test`: UIKit
   requires the iOS destination.

5. **Investigate failures before retrying.** Preserve the first result bundle and error. Separate
   compilation, dependency, environment, assertion and snapshot failures. A passing retry does
   not explain an earlier failure; report both. Do not replace references, relax tolerances,
   remove assertions, change CI or alter lint baselines merely to get a green result.
6. **Test the assembled layout when rendering changes.** Follow the
   [existing Example app walkthrough](./docs/local-layout-testing.md) for fixture generation,
   SwiftUI/UIKit rendering and reload steps. Programmatic scrolling and component snapshots do
   not prove real gesture delivery, browser behavior, or event transport.
7. **Complete the relevant repository checks.** Use Trunk and the documented Example build;
   validate both package managers when dependencies change. Documentation-only changes should
   check formatting, links, examples and source accuracy, and explicitly say native tests were
   not run rather than claim a runtime pass.

## Validation record

Include a safe summary in the PR and retain detailed evidence privately when it contains
sensitive data. Review every attachment using the public-content checklist before uploading it.

| Field           | Record                                                                                                                |
| --------------- | --------------------------------------------------------------------------------------------------------------------- |
| Candidate       | Commit and exact dependency versions; identify local overrides and later changes                                      |
| Environment     | Xcode, runtime, device, SwiftUI/UIKit host and outer layout used                                                      |
| Scope           | Suites and meaningful assertions; for gestures, measured motion and unintended-response checks                        |
| Result          | Passed, failed and skipped counts; preserve the initial failure and each retry separately                             |
| Evidence        | Result bundle and reviewed visual comparison; share only sanitized, public-safe output                                |
| Test doubles    | Whether images, URL opening, callbacks, data and event transport were real or mocked                                  |
| Remaining gates | Published dependencies, consuming SDK/app tests, supported OS/device, VoiceOver, Dynamic Type and human visual review |

Check test counts and skips in the result bundle, not just a successful process exit. Passing
component tests, a local app build, current-head CI, published-dependency validation and manual
acceptance are distinct results. A size-report job passing does not itself approve a size increase.

## Snapshot Testing

### Overview

Snapshot tests render SwiftUI components into images and compare them pixel-by-pixel against committed reference PNGs. They catch visual regressions that unit assertions would miss (e.g. font-stripping, missing underline, broken layout).

The library used is [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) by Point-Free.

### Shared Configuration

All snapshot tests use a shared device config defined in:

```text
Tests/RoktUXHelperTests/UI/Utils/SnapshotConfig.swift
```

This ensures every snapshot renders against the same viewport (`iPhone13Pro`, portrait). To change the target device, update `snapshotDevice` in that file and re-record all reference images.

### Reference Image Location

Reference PNGs are stored next to the test file in a `__Snapshots__/` directory, named after the test class and method:

```text
Tests/RoktUXHelperTests/UI/Components/__Snapshots__/
  TestBasicTextComponent/testSnapshot.1.png
  TestCatalogImageGalleryComponent/testSnapshot_fullFeatured.1.png
  TestColumnComponent/testSnapshot.1.png
  TestCreativeResponseComponent/testSnapshot.1.png
  TestRichTextComponent/testSnapshot.1.png
  TestRichTextComponent/testSnapshot_nilDefaultStyle.1.png
  TestRichTextComponent/testSnapshot_nilTextStyle.1.png
  TestRowComponent/testSnapshot_withChildren.1.png
  TestRuntimeAndTransactionDataPlaceholders/testSnapshot_basicText_catalogRuntimeFallsBackToDefault_whenDataMissing.1.png
  TestRuntimeAndTransactionDataPlaceholders/testSnapshot_basicText_mandatoryOrphan_zeroesLine.1.png
  TestRuntimeAndTransactionDataPlaceholders/testSnapshot_basicText_optionalOrphan_substitutesDefault.1.png
  TestRuntimeAndTransactionDataPlaceholders/testSnapshot_basicText_resolvesCatalogRuntimePlaceholders.1.png
  TestRuntimeAndTransactionDataPlaceholders/testSnapshot_basicText_resolvesShippingAddressFromTransactionData.1.png
  TestScrollableColumn/testSnapshot.1.png
  TestScrollableColumn/testSnapshot_minHeightExpandsViewport.1.png
  TestScrollableColumn/testSnapshot_percentageChildrenFillViewport.1.png
  TestScrollableColumn/testSnapshot_shortContentKeepsMainAxisAlignment.1.png
  TestScrollableColumn/testSnapshot_tallScrollableContentAtBottom.1.png
  TestScrollableColumn/testSnapshot_tallScrollableContentAtTop.1.png
  TestScrollableRow/testSnapshot.1.png
  TestScrollableRow/testSnapshot_minWidthExpandsViewport.1.png
  TestScrollableRow/testSnapshot_narrowContentKeepsMainAxisAlignment.1.png
  TestScrollableRow/testSnapshot_percentageChildrenFillViewport.1.png
  TestScrollableRow/testSnapshot_wideScrollableContentAtEnd.1.png
  TestScrollableRow/testSnapshot_wideScrollableContentAtStart.1.png
  TestToggleButtonComponent/testSnapshot.1.png
  TestZStackComponent/testSnapshot.1.png
```

These PNGs **must** be committed to the repository. If they are missing, the test records a new image and fails on the first run.

### Test Fixture Location

JSON fixtures used by component tests live under `Tests/RoktUXHelperTests/Supporting Files/`. Note that the subdirectory names don't always match the component -- for example, `Supporting Files/ZStack/` contains fixtures for ZStack, ToggleButton, and other components that share the same directory. Check `ModelTestData.swift` to see which JSON file maps to which component model.

### Adding a New Snapshot Test

1. **Create the test method** in the appropriate `Test*Component.swift` file. Use `snapshotDevice` for the device config:

```swift
/// Brief description of what this snapshot validates.
func testSnapshot_myNewCase() {
    let view = TestPlaceHolder(layout: LayoutSchemaViewModel.richText(model))
        .frame(width: 350, height: 200)

    let hostingController = UIHostingController(rootView: view)
    assertSnapshot(of: hostingController, as: .image(on: snapshotDevice,
                                                  precision: snapshotPrecision,
                                                  perceptualPrecision: snapshotPerceptualPrecision))
}
```

2. **Run the test** locally (Cmd+U or right-click the test). It will fail and record a new reference image.

3. **Inspect the generated PNG** in `__Snapshots__/` to verify it looks correct.

4. **Run the test again** to confirm it passes against the new reference.

5. **Commit the reference PNG** alongside your test code.

### Updating Snapshots After an Intentional UI Change

First compare the existing reference with the actual rendering and explain every meaningful
difference. An unexpected alignment, clipping, spacing, or interaction change is a regression to
fix against the existing reference. Check the toolchain before attributing a difference to the
code, but do not assume an environment mismatch makes the difference harmless.

Use the following recording steps **only after an intentional appearance change has been
reviewed**. Keep the original reference available for comparison. Do not delete a reference,
enable record mode, or lower precision merely because a test failed.

#### Option A: Delete and re-record (recommended for a few snapshots)

1. **Run the tests** (Cmd+U). Note which snapshot tests fail.
2. **Delete the old reference PNGs** for the failing tests from `__Snapshots__/`. For example:

```bash
rm Tests/RoktUXHelperTests/UI/Components/__Snapshots__/TestRichTextComponent/testSnapshot.1.png
```

3. **Run the tests again.** The library records new reference images and the tests fail once more (first-run recording).
4. **Inspect each new PNG** in `__Snapshots__/` to confirm it reflects your intended change.
5. **Run the tests a third time.** They should now pass.
6. **Commit the updated PNGs** alongside your code changes in the same PR.

#### Option B: Scoped recording for an intentional update

When many snapshots need re-recording at once (e.g. changing the shared device config or a global style):

1. **Temporarily wrap only the intended assertions** in scoped recording. The pinned library
   deprecates the global `isRecording` flag:

```swift
withSnapshotTesting(record: .all) {
    assertSnapshot(of: hostingController, as: .image(on: snapshotDevice,
                                                  precision: snapshotPrecision,
                                                  perceptualPrecision: snapshotPerceptualPrecision))
}
```

2. **Run the selected tests.** They record the selected images and report recording failures.
3. **Remove the record-mode wrapper** -- do not commit it.
4. **Run the tests again** to confirm they pass with the new references.
5. **Review the git diff** of the changed PNGs to verify the visual changes are intentional.
6. **Commit the updated PNGs** alongside your code changes.

> **Important:** Never commit a record-mode override, including `isRecording = true` or
> `withSnapshotTesting(record: .all)`. It bypasses the intended reference comparison.

#### Checklist for PR authors

- [ ] Every changed reference represents an intentional, reviewed appearance change
- [ ] Unexpected differences were fixed against the original references
- [ ] All snapshot tests pass with recording disabled
- [ ] Updated reference PNGs are committed in the PR
- [ ] No record-mode override or unapproved precision change is present in committed code
- [ ] New PNGs have been visually inspected

### Debugging CI Failures

When snapshot tests fail in CI:

1. Go to the failed GitHub Actions run.
2. Download the **snapshot-failures** artifact (uploaded automatically on test failure).
3. Inspect the actual rendered images and any exported diff images. Artifact contents depend on
   the test helper; a rendered PNG alone is not a diff. Retrieve the committed reference from the
   tested revision for comparison.
4. Compare against the committed reference to determine if the change is intentional or a regression.
5. If intentional, follow the update process above and push updated reference PNGs. If unexpected, investigate the code change that caused the diff.

### Environment Sensitivity

Snapshot images are sensitive to the OS version and simulator device. The repository variables
were verified on 4 September 2026 as:

- **Xcode**: 26.2
- **Simulator**: iPhone 17, iOS 26.2 (pinned to the runtime bundled with Xcode 26.2)
- **Viewport**: Set by `snapshotDevice` (currently `ViewImageConfig.iPhone13Pro(.portrait)`)

The runner label, Xcode version, simulator model, and iOS runtime come from **repository
variables**. Verify them before reproducing a snapshot failure; the dated values above can drift.
For contributors with repository access:

```bash
gh api repos/ROKT/rokt-ux-helper-ios/actions/variables \
  --jq '.variables[] | select(.name | startswith("CI_")) | "\(.name)=\(.value)"'
```

Without access, use the workflow run's setup logs or ask a maintainer to confirm the environment.
The workflow provides `macos-latest` as the runner fallback. The composite action requires the
Xcode/model/runtime inputs and declares **no defaults** for them; do not assume missing variables
will fall back to the values in this guide. Do not change repository variables to make a local
failure disappear.

`snapshotDevice` sets the viewport independently of the simulator's model. Matching that viewport
alone does not match the OS font renderer, toolchain, or all device behavior. Reproduce with the
same Xcode/runtime first; treat other supported OS versions as a separate compatibility check.

### Async Considerations

RichText snapshot tests require waiting for HTML-to-attributed-string conversion, which runs on `DispatchQueue.main.async`. Use the `waitForAttributedStringConversion` helper:

```swift
model.transformValueToAttributedString(.light)
waitForAttributedStringConversion(on: model, timeout: 2.0)
```

This spins the main run loop until `model.attributedString.string` is non-empty or the timeout expires.

### Image Components and Data URIs

Components that load images asynchronously (e.g. `AsyncImageView`) will render blank in snapshot tests when given remote URLs, because network requests don't complete during the synchronous snapshot capture.

To work around this, use **base64 data URIs** for image sources in snapshot factories. `AsyncImageView` already supports `data:image/...;base64,...` URIs and renders them synchronously via `Base64Image`. See `TestCatalogImageGalleryComponent.swift` for an example that defines small solid-color PNGs and arrow icons as static data URI constants.

**ARGB hex format:** The `UIColor(hexString:)` initializer uses **ARGB** byte order for 8-character hex values, not RGBA. For example, 60% opaque black is `#99000000` (not `#00000099`, which would be fully transparent).

### Snapshot Coverage Matrix

This matrix tracks which visual scenarios have snapshot tests and which are known gaps. When adding a new feature or fixing a visual bug, check the relevant component below and add a snapshot for unchecked items where appropriate.

#### BasicText

- [x] Standard rendering -- font, text color, background, fixed height (`testSnapshot`)
- [ ] Dark mode color adaptation
- [ ] Text truncation with `lineLimit`
- [ ] Min/max width constraints

#### Column

- [x] Standard rendering -- background color, centered child (`testSnapshot`)
- [ ] Dark mode color adaptation
- [ ] Border styling
- [ ] Nested columns

#### RichText

- [x] Standard rendering -- bold, italic, underline, strikethrough with campaign font (`testSnapshot`)
- [x] nil `defaultStyle` -- HTML parsed correctly without styling, PR #220 fix (`testSnapshot_nilDefaultStyle`)
- [x] nil text style -- style exists but no text properties, font-stripping guard (`testSnapshot_nilTextStyle`)
- [ ] Link rendering with default blue underline
- [ ] Custom link styling (campaign-configured colors/weight)
- [ ] Dark mode with adapted text/link colors
- [ ] Mixed HTML tags with `<br>` line breaks
- [ ] Plain text with no HTML tags

#### Row

- [x] Multiple children -- BasicText, RichText, CloseButton in a single row (`testSnapshot_withChildren`)

#### ZStack

- [x] Standard rendering -- pink background, padding, centered alignment (`testSnapshot`)
- [ ] Multiple overlapping children

#### OneByOne (Distribution)

- [ ] Embedded one-by-one layout (test exists but is commented out -- see `TestRuntimeAndTransactionDataPlaceholders` for a working `perceptualPrecision: 0.98` pattern that may unblock this)

#### ScrollableColumn

- [x] Standard rendering -- Column with pink background inside a ScrollView (`testSnapshot`)
- [x] Max height constrained tall content -- viewport clipped at the max height with a stationary border (`testSnapshot_tallScrollableContentAtTop`)
- [x] Max height constrained tall content -- bottom viewport shows the final colored sections (`testSnapshot_tallScrollableContentAtBottom`)
- [x] Min height -- viewport background fills the minimum even though the content is shorter (`testSnapshot_minHeightExpandsViewport`)
- [x] Percentage-height children -- two 50% children fill a fixed-height viewport (`testSnapshot_percentageChildrenFillViewport`)
- [x] Main-axis alignment -- `justifyContent: center` centres short content in a taller viewport (`testSnapshot_shortContentKeepsMainAxisAlignment`)
- [ ] Scroll indicator visibility

#### ScrollableRow

- [x] Standard rendering -- Row with pink background inside a ScrollView (`testSnapshot`)
- [x] Wide content -- viewport clipped at the parent width with a stationary border (`testSnapshot_wideScrollableContentAtStart`)
- [x] Wide content -- trailing viewport shows the final colored sections (`testSnapshot_wideScrollableContentAtEnd`)
- [x] Min width -- viewport background fills the minimum even though the content is narrower (`testSnapshot_minWidthExpandsViewport`)
- [x] Percentage-width children -- two 50% children fill a fixed-width viewport (`testSnapshot_percentageChildrenFillViewport`)
- [x] Main-axis alignment -- `justifyContent: center` centres narrow content in a wider viewport (`testSnapshot_narrowContentKeepsMainAxisAlignment`)
- [ ] Scroll indicator visibility

#### Overlay

- [ ] Overlay positioning and backdrop

#### CreativeResponse

- [x] Positive response button -- black background, 10px padding (`testSnapshot`)
- [ ] Negative response button
- [ ] Pressed/hover state

#### ToggleButton

- [x] Default state -- blue background with "Subscribe" label (`testSnapshot`)
- [ ] Selected/toggled state

#### CloseButton

- [ ] Default close button rendering

#### StaticImage / DataImage

- [ ] Image rendering with sizing constraints

#### CatalogImageGallery

- [x] Full-featured rendering -- gallery image, navigation buttons, pill indicator with dots (`testSnapshot_fullFeatured`)

#### Placeholder Resolution (Runtime + Transaction Data)

End-to-end coverage for the placeholder namespaces and the finalize step. These
drive `BasicTextViewModel` directly and through the full `LayoutTransformer`
pipeline. They use `perceptualPrecision: 0.98` to tolerate sub-pixel text
rendering drift across simulator runtimes.

- [x] `DATA.catalogRuntime.*` -- host-pushed runtime values resolved reactively from `LayoutState.catalogRuntimeDataKey` (`testSnapshot_basicText_resolvesCatalogRuntimePlaceholders`)
- [x] `DATA.catalogRuntime.*` fallback -- `--` default substitutes when host has not pushed runtime data (`testSnapshot_basicText_catalogRuntimeFallsBackToDefault_whenDataMissing`)
- [x] `DATA.transactionData.shippingAddress.*` -- full transformer pipeline, `TransactionDataMapper` resolves from active offer via `LayoutState.fullOfferKey` (`testSnapshot_basicText_resolvesShippingAddressFromTransactionData`)
- [x] OrphanedPlaceholderResolver -- optional orphan with `|` default substitutes the literal, line stays (`testSnapshot_basicText_optionalOrphan_substitutesDefault`)
- [x] OrphanedPlaceholderResolver -- mandatory orphan (no `|` default) zeroes the line, `boundValue == ""` (`testSnapshot_basicText_mandatoryOrphan_zeroesLine`)

#### ProgressIndicator / ProgressControl

- [ ] Progress bar rendering at various states

> **Contributing:** When you add a new snapshot test, check the box above and note the test method name. When you identify a new scenario worth covering, add an unchecked item.

## Native Inline Text

`TestInlineContainerComponent` exercises the internal text renderer without adding a schema dependency or advertising a new schema version. It covers shared text/action lines, narrow wrapping, Unicode action ranges, natural mixed-font baselines, Dynamic Type, dark mode, right-to-left content, accessible link/button labels, disabled actions, custom-state dispatch, and SwiftUI host height changes. The height coordinator test checks that identical measurements do not keep updating SwiftUI state.

Inline range styles cover font/color/baseline/decoration typography, solid background colors, nonnegative padding/margins, solid or dashed borders (including unequal side widths), and opacity. Line height, line limits, and per-span paragraph alignment are not part of the inline text style contract. Parent container styles use the existing layout modifier. Background images, blur, and shadows on individual inline ranges are not represented by `InlineSpanStyle`; a future schema adapter must handle or explicitly reject these effects rather than discard them. No new wire node is accepted by this implementation alone.

`BNFTextOperationTests` and `TextSlicingTests` cover `:sliceText[Chars,N]`, including 77/78/79-character boundaries, joined emoji and combining marks, invalid arguments, and fallback alternatives. `N` is a nonnegative whole number within Swift's `Int` range. Slicing uses the same `String` character semantics as the length predicate. Operations apply to the selected key alternative; literal fallbacks remain unchanged.

`StateTextOperationBindingTests` verifies that creative and catalog mappers preserve deferred STATE tokens, including their operations, until plain and attributed text rendering resolves them. `NumericPredicateTextExpansionTests` verifies that numeric predicates expand their string inputs before numeric conversion. This differs from directly requesting an integer binding from an extractor, which rejects text operations.

The real native view has snapshot tests for narrow copy/action wrapping (`testSnapshot_narrowWrappingTextAndAction`) and expanded right-to-left text in dark mode (`testSnapshot_expandedRightToLeftInDarkMode`). Both use the shared device and precision settings. Their references were rendered in simulator CI and visually reviewed. The snapshot helper also exports the rendered image to `SNAPSHOT_ARTIFACTS` when set, so CI can expose a first rendering even when a missing reference is recorded beside the tests. Missing references still fail the tests and must be visually reviewed before committing their PNGs.

Run these tests on an iOS simulator using the package's normal `xcodebuild` workflow. Native layout assertions do not replace visual checks: inspect inline wrapping and decoration on iOS 15 and a current OS, exercise VoiceOver and nested scrolling, and verify the example host before enabling schema integration.
