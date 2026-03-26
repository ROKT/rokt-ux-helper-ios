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
  TestBasicTextComponent/
    testSnapshot.1.png
  TestColumnComponent/
    testSnapshot.1.png
  TestRichTextComponent/
    testSnapshot.1.png
    testSnapshot_nilDefaultStyle.1.png
    testSnapshot_nilTextStyle.1.png
```

These PNGs **must** be committed to the repository. If they are missing, the test records a new image and fails on the first run.

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

- **Xcode**: 16.4
- **Simulator**: iPhone 16, iOS >= 18.0
- **Viewport**: Set by `snapshotDevice` (currently `ViewImageConfig.iPhone13Pro(.portrait)`)

The `ViewImageConfig` sets the rendering viewport explicitly, so the simulator model doesn't affect output. However, font rendering can vary across OS versions. If you see unexpected diffs, ensure your local Xcode and simulator match CI.

### Async Considerations

RichText snapshot tests require waiting for HTML-to-attributed-string conversion, which runs on `DispatchQueue.main.async`. Use the `waitForAttributedStringConversion` helper:

```swift
model.transformValueToAttributedString(.light)
waitForAttributedStringConversion(on: model, timeout: 2.0)
```

This spins the main run loop until `model.attributedString.string` is non-empty or the timeout expires.

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
- [x] nil `defaultStyle` -- no styling provided, PR #220 regression guard (`testSnapshot_nilDefaultStyle`)
- [x] nil text style -- style exists but no text properties, font-stripping guard (`testSnapshot_nilTextStyle`)
- [ ] Link rendering with default blue underline
- [ ] Custom link styling (campaign-configured colors/weight)
- [ ] Dark mode with adapted text/link colors
- [ ] Mixed HTML tags with `<br>` line breaks
- [ ] Plain text with no HTML tags

#### Row

- [x] Standard rendering -- pink background, centered BasicText child, fixed 140x24 frame (`testSnapshot`)
- [x] Multiple children -- BasicText, RichText, CloseButton in a single row (`testSnapshot_withChildren`)

#### ZStack

- [x] Standard rendering -- pink background, padding, centered alignment (`testSnapshot`)
- [ ] Multiple overlapping children

#### OneByOne (Distribution)

- [ ] Embedded one-by-one layout (test exists but is commented out -- needs `perceptualPrecision` investigation)

#### ScrollableColumn

- [x] Standard rendering -- Column with pink background inside a ScrollView (`testSnapshot`)
- [ ] Max height constraint variant
- [ ] Scroll indicator visibility

#### ScrollableRow

- [ ] Standard rendering
- [ ] Scroll indicator visibility

#### Overlay

- [ ] Overlay positioning and backdrop

#### CreativeResponse

- [x] Positive response button -- black background, 10px padding (`testSnapshot`)
- [ ] Negative response button
- [ ] Pressed/hover state

#### ToggleButton

- [x] Default state -- white/black adaptive background (`testSnapshot`)
- [ ] Selected/toggled state

#### CloseButton

- [ ] Default close button rendering

#### StaticImage / DataImage

- [ ] Image rendering with sizing constraints

#### ProgressIndicator / ProgressControl

- [ ] Progress bar rendering at various states

> **Contributing:** When you add a new snapshot test, check the box above and note the test method name. When you identify a new scenario worth covering, add an unchecked item.
