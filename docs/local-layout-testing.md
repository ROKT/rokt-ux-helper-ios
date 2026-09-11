# Render a local layout in the Example app

Use the existing Example app to test an authored layout through `RoktLayoutView` and `RoktLayoutUIView`. A component snapshot, a SwiftUI preview, and this app exercise different boundaries. This app renders a supplied experience; it does not establish that a released SDK can fetch the experience or deliver its events.

Read [the public-content checklist](./public-content-checklist.md) before preparing fixtures or sharing results. Use synthetic content. Do not paste a production response into a tracked file or publish captured tokens, identifiers, or URLs.

## Choose the right entry point

| Goal                                      | Entry point                                         | What it does not establish                               |
| ----------------------------------------- | --------------------------------------------------- | -------------------------------------------------------- |
| Unit and snapshot regression              | `Package.swift`, scheme `RoktUXHelper`              | Full app integration or real touch delivery              |
| Authored layout in SwiftUI or UIKit       | `Example/Example.xcodeproj`, scheme `Example`       | SDK networking, released dependencies, or event delivery |
| SDK integration or partner-app acceptance | The consuming SDK/app's documented test entry point | A helper-only pass cannot substitute for these checks    |

All paths below are relative to the repository root. First follow [the testing preflight](../TESTING.md#native-testing-workflow). Preserve unrelated local changes and coordinate simulator use before running an app or UI tests.

## Prepare and merge the fixture

The default Example reads these files:

- `Example/Example/Resources/outer_layout.json`: the outer layout object.
- `Example/Example/Resources/layout_variant.json`: the variant layout object.
- `Example/Example/Resources/experience.json`: the full experience envelope containing the layout strings and sample offer data.

1. Work in an isolated checkout or preserve your current fixture edits before replacing anything. Edit the outer and variant JSON objects with nodes supported by the schema dependency and renderer on the branch you are testing. A web layout is not automatically an iOS layout.
2. Ensure the experience supplies the data required by the layout. The merge tool does not generate offer/catalog data, convert platform schemas, validate supported nodes, or repair response metadata.
3. Run the existing tool from the repository root:

   ```bash
   python3 tools/merge_layout.py
   python3 -m json.tool Example/Example/Resources/experience.json > /dev/null
   git diff -- Example/Example/Resources
   ```

   This **overwrites** the layout fields in the default `experience.json`. The JSON syntax check does not validate schema compatibility; run the relevant decoder/transformer tests and inspect the rendered result too.

4. Review the tool's output and the resulting fixture. The tool replaces the **first occurrence** of each selected field; it is not a multi-offer fixture editor. A successful exit can mean only one field was replaced, so confirm both `layoutVariantSchema` and `outerLayoutSchema` were merged when both are intended. Inspect the remaining variants separately in a multi-offer experience.

For a single layout change, use `--only layout-variant` or `--only outer-layout`. To target another existing experience without changing the default one, pass explicit paths:

```bash
python3 tools/merge_layout.py \
  --layout-variant /path/to/layout_variant.json \
  --outer-layout /path/to/outer_layout.json \
  --experience /path/to/experience.json
```

The tool handles encoding layouts into the experience's string fields. Supply JSON objects as the input files; do not double-encode them yourself. It updates an existing experience and does not create a complete experience from two layouts alone.

## Open, render, and reload

1. Open `Example/Example.xcodeproj`, select the **Example** scheme and the agreed iOS simulator. The project already references the helper package locally; do not add a second remote dependency to test this checkout.
2. Run the app and choose **Load SwiftUI** or **Load UIKit**. Both default to the bundled `experience.json` and `location: "#target_element"`. The experience's `targetElementSelector` must match that location.
3. Use the existing full-screen buttons for overlay/bottom-sheet fixtures. They select `experience-overlay.json` or `experience-bottomsheet.json` with an empty location. Editing `experience.json` will not change those screens.
4. After editing JSON, rebuild and run again so the bundle contains the new file. Stop and rerun the app to reset a completed/dismissed experience. The view model loads the resource at initialization; an already-open screen is not a live JSON editor.
5. Check both SwiftUI and UIKit when changing shared rendering or layout sizing. Record which host and outer layout were exercised rather than describing one successful screen as all-host coverage.

For implementation details, see [the Example README](../Example/README.md), [HomeView](../Example/Example/HomeView.swift), [SampleView](../Example/Example/SampleView.swift), and [SampleViewController](../Example/Example/SampleViewController.swift).

## Interaction and navigation evidence

- For scrolling, assert that the content offset or an item's measured frame actually changes. Seeing a second item is insufficient when it was already visible. Test a quick drag, a held drag and a reversal; dragging over a response control must not generate an unintended response.
- For expandable copy, check expansion and collapse in the surrounding layout: wrapping, height growth/shrinkage, scroll position, and usable action targets.
- For responses, verify the selected item's URL and event identity with synthetic distinct values. Check missing/invalid data and that callbacks from an old offer cannot advance a newer one.
- Record whether images are local data URIs or remotely loaded. Local images make snapshots deterministic but do not test downloading, placeholders, or failures.
- State whether URL opening and event transport are real, mocked, or intercepted. The Example's sample URL handlers complete early; they are not a browser-dismissal or failed-open acceptance test. See [the callback limitations](../Example/README.md#url-callback-limitations).
- Run real URL/app-link and host callback acceptance in the consuming app under an approved test setup. Do not send synthetic or production events to an unintended endpoint merely to make a preview interactive.

Do not represent a supported configuration as the approved default appearance. Record any fixture overrides for fonts, spacing, images, copy, or feature settings. Use the intended configuration for final visual acceptance.

## Troubleshooting

| Symptom                                | Check before changing code or resetting caches                                                                  |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Layout is blank                        | JSON syntax, schema/renderer support, required data, target/location match, and layout error callbacks          |
| Screen looks unchanged                 | Correct checkout and app target, selected home-screen entry, resource name, rebuilt bundle, then restart        |
| A node fails to decode                 | Whether this branch's schema dependency includes it; do not assume renderer work also published that dependency |
| A drag test passes without motion      | Measure displacement and ensure the asserted destination was not visible initially                              |
| A tap dismisses the sample immediately | Sample URL completion behavior and offer/outer completion settings; do not infer browser behavior               |
| Package resolution fails               | Actual selected versions, local overrides and registry availability; do not reset all caches as the first step  |

## Dependencies and handoff

The Example's local helper reference is intentional. If you also use a local schema or a consuming SDK checkout, record every revision and dirty override. Keep development-only package paths and fixtures out of release commits. Do not silently edit a colleague's checkout to satisfy resolution.

Before release acceptance, repeat validation with the intended published dependency versions through both supported package managers. A Git tag does not prove CocoaPods availability, and a successful local override does not prove the published dependency graph. Follow [the schema update checklist](../README.md#how-to-update-the-layouts-schema-file).

Use [the validation record](../TESTING.md#validation-record) to hand off exact evidence. Physical-device, minimum-supported-OS, VoiceOver, Dynamic Type, and final visual acceptance remain separate from simulator/component results. Review every screenshot, recording, log, and report before sharing it publicly.
