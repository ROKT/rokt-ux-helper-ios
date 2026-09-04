# Testing Guide

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
  TestCatalogCarouselCollectionComponent/testSnapshot_zeroProducts.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_oneProduct.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_manyProducts.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_smallWidth.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_productLayoutWithCollapsedDescription.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_productLayoutInDarkMode.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_productLayoutWithMissingResponse.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_productLayoutAfterExpandingDescription.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_productLayoutScrolledToLastCard.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_productLayoutWithAccessibleTextRightToLeft.1.png
  TestCatalogImageGalleryComponent/testSnapshot_fullFeatured.1.png
  TestCatalogCarouselCollectionComponent/testSnapshot_mixedIntrinsicCardHeights.1.png
  TestColumnComponent/testSnapshot.1.png
  TestCreativeResponseComponent/testSnapshot.1.png
  TestInlineContainerComponent/testSnapshot_narrowWrappingTextAndAction.1.png
  TestInlineContainerComponent/testSnapshot_expandedRightToLeftInDarkMode.1.png
  TestInlineContainerComponent/testSnapshot_disabledAction.1.png
  TestInlineContainerComponent/testSnapshot_hoveredAction.1.png
  TestInlineContainerComponent/testSnapshot_pressedAction.1.png
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
    assertSnapshot(of: hostingController, as: .image(on: snapshotDevice))
}
```

2. **Run the test** locally (Cmd+U or right-click the test). It will fail and record a new reference image.

3. **Inspect the generated PNG** in `__Snapshots__/` to verify it looks correct.

4. **Run the test again** to confirm it passes against the new reference.

5. **Commit the reference PNG** alongside your test code.

### Updating Snapshots After an Intentional UI Change

If you change component styling, layout, or rendering logic, existing snapshot tests **will fail** -- this is expected and means the tests are doing their job. Here is how to update them:

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

#### Option B: Use `isRecording` flag (recommended for bulk updates)

When many snapshots need re-recording at once (e.g. changing the shared device config or a global style):

1. **Set the global recording flag** at the top of the test file or in `setUp()`:

```swift
override func setUp() {
    super.setUp()
    isRecording = true
}
```

2. **Run all snapshot tests** (Cmd+U). Every snapshot is re-recorded and the tests fail.
3. **Remove `isRecording = true`** -- do not commit it.
4. **Run the tests again** to confirm they pass with the new references.
5. **Review the git diff** of the changed PNGs to verify the visual changes are intentional.
6. **Commit the updated PNGs** alongside your code changes.

> **Important:** Never commit `isRecording = true`. It disables regression detection. PR reviewers should flag this if spotted.

#### Checklist for PR authors

- [ ] All snapshot tests pass locally after re-recording
- [ ] Updated reference PNGs are committed in the PR
- [ ] `isRecording = true` is **not** present in committed code
- [ ] New PNGs have been visually inspected

### Debugging CI Failures

When snapshot tests fail in CI:

1. Go to the failed GitHub Actions run.
2. Download the **snapshot-failures** artifact (uploaded automatically on test failure).
3. The artifact contains the actual rendered image and a diff highlighting pixel differences.
4. Compare against the committed reference to determine if the change is intentional or a regression.
5. If intentional, follow the update process above and push updated reference PNGs. If unexpected, investigate the code change that caused the diff.

### Environment Sensitivity

Snapshot images are sensitive to the OS version and simulator device. The CI uses:

- **Xcode**: 26.2
- **Simulator**: iPhone 17, iOS 26.2 (pinned to the runtime bundled with Xcode 26.2)
- **Viewport**: Set by `snapshotDevice` (currently `ViewImageConfig.iPhone13Pro(.portrait)`)

The CI runner label, Xcode version, simulator model, and iOS runtime are supplied by **repository variables** so a runner-image change (GitHub bumping Xcode or the available simulators) can be handled by editing a variable in repo settings — no code PR required. Defaults in parentheses are used when the variable is unset:

- `CI_MACOS_RUNNER` (`macos-latest`) — `runs-on` for the test jobs
- `CI_XCODE_VERSION` (`26.2`) — Xcode version selected by `setup-xcode`
- `CI_SIMULATOR_MODEL` (`iPhone 17`) — simulator device model
- `CI_SIMULATOR_OS` (`26.2`) — simulator iOS runtime (keep aligned with the runtime bundled by `CI_XCODE_VERSION`)

Set these under **Settings → Secrets and variables → Actions → Variables**. Changing `CI_MACOS_RUNNER` or `CI_SIMULATOR_MODEL` does not affect rendering (the `ViewImageConfig` sets the viewport explicitly). **Changing `CI_XCODE_VERSION` or `CI_SIMULATOR_OS` can** — font rendering varies across Xcode/OS versions, so after such a change the reference PNGs may need re-recording (the small precision tolerance in `SnapshotConfig` absorbs minor anti-aliasing differences, but not a full toolchain jump). If you see unexpected diffs, ensure your local Xcode and simulator match CI.

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

#### CatalogResponseButton

`CatalogResponseButtonInteractionTests` covers behavior with ViewInspector, not snapshots:

- Product responses use a native button and invoke the bound product callback exactly once.
- Product labels have no competing tap or long-press handlers; disabled and invalid responses cannot activate.
- Existing catalog purchase buttons retain their gesture and purchase behavior.

These checks do not simulate touch arbitration. Also exercise a JSON-rendered carousel in the Example app: drag from a visible card to reveal an initially offscreen card, verify that its horizontal position changes, then drag back. Repeat after holding the card before dragging. Neither gesture should open a destination or submit a response. Check vertical host scrolling and ordinary product taps separately; checking a card that was already visible does not establish that scrolling worked.

#### CatalogImageGallery

- [x] Full-featured rendering -- gallery image, navigation buttons, pill indicator with dots (`testSnapshot_fullFeatured`)

#### CatalogCarouselCollection

`CatalogCarouselStretchLayoutTests` mounts the real carousel and measures rendered card surfaces with different text lengths. It checks equal card heights, growth and shrinkage after text changes, narrow and wide host widths, and stable mount/scroll callbacks. These are native layout assertions with synthetic colors, not recorded image snapshots or product-button gesture coverage.

The same suite checks that intrinsic-width cards retain their leading edge and that full-width cards preserve authored center/end child alignment in both layout directions. Snapshot readiness requires measurements for every card at the current width, unchanged measurements across consecutive layout checks, and a scroll host height matching the measured maximum. A first positive height alone is insufficient because later cards can change that maximum.

- [x] Product cards with different intrinsic title heights share a row height (`testSnapshot_mixedIntrinsicCardHeights`). This checks the card surfaces, not aligned internal buttons or full-template styling.

- [x] Empty catalog -- no reserved carousel space (`testSnapshot_zeroProducts`)
- [x] Single product -- full-width card (`testSnapshot_oneProduct`)
- [x] Multiple products -- grouped width, gap, and peek (`testSnapshot_manyProducts`)
- [x] Narrow host -- wrapping product title (`testSnapshot_smallWidth`)
- [x] Typed product layout with collapsed description, data-URI images, selected title/price fields, and response buttons (`testSnapshot_productLayoutWithCollapsedDescription`)
- [x] Typed product layout after activating See More (`testSnapshot_productLayoutAfterExpandingDescription`)
- [x] Typed product layout scrolled to its last product (`testSnapshot_productLayoutScrolledToLastCard`)
- [x] Accessible text with right-to-left offer and product copy (`testSnapshot_productLayoutWithAccessibleTextRightToLeft`)
- [x] Dark mode offer copy, product labels, and response labels (`testSnapshot_productLayoutInDarkMode`)
- [x] Product with no response retains its image and labels but omits its button (`testSnapshot_productLayoutWithMissingResponse`)

The typed-layout cases reuse `ProductCarouselIntegrationFixture` and render through `OneByOneDistribution`, including the inline description and catalog cards. They use generic product responses and synchronous data-URI images. The missing-response case removes only the first product's response map and checks that the other products still have renderable responses. It exercises an absent button, not disabled styling for a valid response. Expansion activates the rendered inline action, and the scrolled case moves the real carousel scroll view. These cases are component integration coverage; they do not replace running the assembled template in the SDK example app.

The accessible RTL case scales the inline description; product labels retain their authored size. Its action labels are English. This does not establish full-template Dynamic Type, translated-label, or VoiceOver acceptance.

#### InlineContainer

- [x] Narrow copy/action wrapping with action padding and border (`testSnapshot_narrowWrappingTextAndAction`)
- [x] Expanded right-to-left text in dark mode (`testSnapshot_expandedRightToLeftInDarkMode`)
- [x] Disabled action appearance and blocked activation (`testSnapshot_disabledAction`)
- [x] Pressed action text, background, and border appearance (`testSnapshot_pressedAction`)
- [x] Pointer-hover action text, background, and border appearance (`testSnapshot_hoveredAction`)
- [ ] Standalone inline layout at accessible text sizes

The typed product layout cases above also exercise inline copy within its surrounding layout. The hover snapshot uses the existing test recognizer to select hover styling; the disabled snapshot then disables that action. The pressed snapshot selects the existing model style state directly. These snapshots cover appearance, not real pointer or touch delivery. Dynamic Type and accessibility behavior additionally have native assertions in `TestInlineContainerComponent`; those assertions are not visual snapshot coverage.

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

`TestInlineContainerComponent` builds the text renderer directly from native view models. It covers shared text/action lines, narrow wrapping, Unicode action ranges, natural mixed-font baselines, Dynamic Type, dark mode, right-to-left content, accessible link/button labels, pointer hover, disabled actions, custom-state dispatch, and SwiftUI host height changes. Container tests verify ordered accessibility elements without duplicated text, stale-action removal, and wrapped-action activation points within actual text fragments. These native assertions do not replace app-level touch automation or manual VoiceOver testing. The height coordinator test checks that identical measurements do not keep updating SwiftUI state. The package now pins and advertises `2.9.0`; `TestSchemaAdapters`, `TestProductCarouselIntegration`, and `TestInlineSchemaLifecycle` cover the typed inline and catalog carousel adapters, transformation, state binding, and hosted lifecycle behavior.

Inline range styles cover font/color/baseline/decoration typography, solid background colors, nonnegative padding/margins, solid or dashed borders (including unequal side widths), and opacity. Line height, line limits, and per-span paragraph alignment are not part of the inline text style contract. Parent container styles use the existing layout modifier. The typed adapters explicitly reject unsupported effects, including background images, nonzero blur, and shadows on individual inline ranges. Adapter tests check these rejections in interaction states, conditional transitions, and hidden branches.

`BNFTextOperationTests` and `TextSlicingTests` cover `:sliceText[Chars,N]`, including 77/78/79-character boundaries, joined emoji and combining marks, invalid arguments, and fallback alternatives. `N` is a nonnegative whole number within Swift's `Int` range. Slicing uses the same `String` character semantics as the length predicate. Operations apply to the selected key alternative; literal fallbacks remain unchanged.

`StateTextOperationBindingTests` verifies that creative and catalog mappers preserve deferred STATE tokens, including their operations, until plain and attributed text rendering resolves them. `NumericPredicateTextExpansionTests` verifies that numeric predicates expand their string inputs before numeric conversion. This differs from directly requesting an integer binding from an extractor, which rejects text operations.

The real native view has snapshot tests for narrow copy/action wrapping (`testSnapshot_narrowWrappingTextAndAction`) and expanded right-to-left text in dark mode (`testSnapshot_expandedRightToLeftInDarkMode`). These and the disabled, hovered, and pressed action snapshots use the shared device and precision settings. The original wrapping and right-to-left references were rendered in simulator CI and visually reviewed. New references follow the same record, inspect, and rerun workflow above. The snapshot helper also exports the rendered image to `SNAPSHOT_ARTIFACTS` when set, so CI can expose a first rendering even when a missing reference is recorded beside the tests. Missing references still fail the tests and must be visually reviewed before committing their PNGs.

Run these tests on an iOS simulator using the package's normal `xcodebuild` workflow. Native layout assertions do not replace visual checks: inline wrapping and decoration on iOS 15 and a current OS, VoiceOver, nested scrolling, and example host verification remain release gates.
