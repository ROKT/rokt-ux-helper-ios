# Rokt UX Helper iOS

The RoktUXHelper enables partner applications to render tailored user experiences, improving the velocity of testing and relevancy for the customer. This library offers an easy way to perform rendering and provides event hooks for integration into backend systems.

## Resident Experts

- James Newman - <james.newman@rokt.com>
- Thomson Thomas - <thomson.thomas@rokt.com>

| Environment | Build                                                                                                                                                                                     | Coverage                                                                                                                                    |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| main        | [![Build status](https://github.com/ROKT/rokt-ux-helper-ios/actions/workflows/pull-request.yml/badge.svg)](https://github.com/ROKT/rokt-ux-helper-ios/actions/workflows/pull-request.yml) | [![codecov](https://codecov.io/gh/ROKT/rokt-ux-helper-ios/graph/badge.svg?token=xFMumIDkv8)](https://codecov.io/gh/ROKT/rokt-ux-helper-ios) |

## Requirements

- Download the latest [Xcode](https://developer.apple.com/xcode/). Project is configured to run on iOS 15.0 and above and compiled with the latest version of iOS.
- clone the repository using `git clone git@github.com:ROKT/rokt-ux-helper-ios.git`

## Installation

### Swift Package Manager

#### Xcode

To integrate to your Xcode project, select File > Add Package Dependency and enter
`https://github.com/ROKT/rokt-ux-helper-ios`.
You can also navigate to your target's General pane, and in the "Frameworks, Libraries, and Embedded Content" section, click the + button, select Add Other, and choose Add Package Dependency.

#### Swift package

To integrate to your Swift package, add the following SPM dependency into your `Package.swift` file. This configuration ensures that your app will receive updates to the library up to, but not including, the next major release.

```swift
dependencies: [
    .package(url: "https://github.com/ROKT/rokt-ux-helper-ios.git", .upToNextMajor(from: "0.1.0"))
]
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'RoktUXHelper', '~> 0.8'
```

Then run `pod install`.

## Architecture

```mermaid
graph TD
    RoktUX[RoktUX] --> |Initiates and manages| LayoutTransformer
    RoktUX --> |Creates and manages| LayoutState


    %% Layout transformation
    LayoutTransformer --> |Transforms to| LayoutSchemaViewModel
    LayoutTransformer --> |Uses| CreativeMapper[CreativeSyntaxMapper]
    CreativeMapper --> |Processes BNF placeholders| LayoutSchemaViewModel
    LayoutSchemaViewModel --> |Renders as| UIComponents

    %% Configuration and state
    RoktUXConfig[RoktUXConfig] --> |Configures| RoktUX
    LayoutState --> |Manages state for| UIComponents
```

The RoktUX Helper iOS follows a unidirectional data flow architecture with these key components:

- **RoktUX**: The main entry point that orchestrates the rendering process and manages the overall state
- **LayoutTransformer**: Converts layout schema from backend responses into view models
- **CreativeSyntaxMapper**: Processes BNF (Backus-Naur Form) placeholders in layout content, transforming them into the final display values
- **LayoutSchemaViewModel**: Represents the UI structure in a framework-agnostic way
- **LayoutState**: Maintains the state of UI components and handles user interactions
- **UIComponents**: The actual UI components rendered on screen (compatible with both SwiftUI and UIKit)

Data flows from the backend response through the transformer and creative mapper to create view models with resolved placeholders, which are then rendered as UI components. User interactions flow back through the state management system to trigger callbacks and state updates.

## Opening the Project

Open the `Package.swift` file with Xcode to start development.

### How to run unit tests locally?

Use the `RoktUXHelper` scheme with an iOS Simulator, then press `command + U` or select
`Product -> Test`. Follow [TESTING.md](./TESTING.md#native-testing-workflow) for environment checks,
CLI commands, failure diagnosis and validation records. Host `swift test` cannot build UIKit.

To render authored JSON, start with [the local layout walkthrough](./docs/local-layout-testing.md).
It uses the existing Example app and `tools/merge_layout.py`; no separate playground is needed.
Before contributing code, PR text, comments or attachments, read
[the mandatory public-content checklist](./docs/public-content-checklist.md).

## Snapshot Testing

Component tests use [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) to catch visual regressions. Each snapshot test renders a component via `UIHostingController` and compares the result pixel-by-pixel against a committed reference PNG.

All snapshot tests share a single device config (`snapshotDevice` in `Tests/.../UI/Utils/SnapshotConfig.swift`) so the viewport is consistent. CI runs these alongside unit tests and uploads failure diffs as a `snapshot-failures` build artifact when any test fails.

**Current snapshot coverage:**

- `TestBasicTextComponent/testSnapshot` -- BasicText with font, color, background, fixed height
- `TestColumnComponent/testSnapshot` -- Column with background and centered child
- `TestRichTextComponent/testSnapshot` -- RichText with HTML bold/italic/underline/strikethrough
- `TestRichTextComponent/testSnapshot_nilDefaultStyle` -- nil `defaultStyle` regression guard
- `TestRichTextComponent/testSnapshot_nilTextStyle` -- nil text style font-stripping guard
- `TestRowComponent/testSnapshot` -- Row with background and BasicText child
- `TestRowComponent/testSnapshot_withChildren` -- Row with multiple children
- `TestScrollableColumn/testSnapshot` -- ScrollableColumn wrapping a styled Column
- `TestZStackComponent/testSnapshot` -- ZStack with background and centered alignment
- `TestCreativeResponseComponent/testSnapshot` -- Positive creative response button
- `TestToggleButtonComponent/testSnapshot` -- ToggleButton default state

See [TESTING.md](./TESTING.md) for the full coverage matrix including known gaps.

**Workflow:**

1. **First run** -- no reference image exists; the library records one and fails. Review the PNG, then commit it.
2. **Subsequent runs** -- rendered output is compared against the reference using the configured precision. Meaningful differences must be investigated.
3. **Intentional UI changes** -- compare expected and actual images before deciding to re-record. Fix unintended regressions against the original PNGs. Only record reviewed appearance changes; see [TESTING.md](./TESTING.md#updating-snapshots-after-an-intentional-ui-change).
4. **CI failures** -- download the `snapshot-failures` artifact from the Actions run to inspect the actual vs. expected diff.

Reference images live at:

```text
Tests/RoktUXHelperTests/UI/Components/__Snapshots__/<TestClass>/<testMethod>.1.png
```

For a detailed guide on adding new snapshots, see [TESTING.md](./TESTING.md).

## Key Dependencies & Gotchas

### SDK Dependencies

- **DcuiSchema**: Core library for parsing experience response. Any schema changes require careful testing to ensure compatibility.
- **ViewInspector**: Used only for testing - not included in production builds.

### Integration Gotchas

1. **iOS Version Compatibility**: The library requires iOS 15.0+. Using with earlier iOS versions will not render any layouts.

2. **Error Handling**:
   - Schema parsing errors are handled gracefully but may result in empty views

### How to Update the Layouts Schema File

1. Confirm the intended version is available from both the [Swift schema package](https://github.com/ROKT/dcui-swift-schema) and CocoaPods. A Swift tag alone does not establish that the matching pod was published.
2. Update the exact schema dependency in `Package.swift` and `RoktUXHelper.podspec` together. Change the pod's dependency, not the helper version field owned by the release workflow.
3. Update `Constants.layoutSchemaVersion` in `Sources/RoktUXHelper/Data/Model/RoktIntegrationInfoDetails.swift` to match. `SchemaVersionConsistencyTests` guards the SPM pin and reported version; it does not replace checking the podspec.
4. Resolve the package and Example dependencies, review their lockfiles, and verify the intended generated types. Run schema/transformer tests, the native suite, Example builds, and the normal `pod lib lint RoktUXHelper.podspec --allow-warnings --verbose` check.
5. If local overrides were used while developing, repeat acceptance with the intended published versions. Do not ship local package paths or treat a local override as proof of registry availability. Report the dependency combination to consuming SDK/app maintainers; their validation is separate.

## Example App

An example app is available in this repository to demonstrate integration with RoktUXHelper using both SwiftUI and UIKit. For detailed implementation examples, refer to the [example app README](https://github.com/ROKT/rokt-ux-helper-ios/tree/main/Example).

## FAQ

### 1. Documentation

For detailed documentation, check the [SwiftUI integration guide](https://docs.rokt.com/server-to-server/ios?platform=swiftui) and [UIKit integration guide](https://docs.rokt.com/server-to-server/ios?platform=uikit).

### 2. What are the branches?

There are main branches coresponding to each version : **Main**, **Release branches** and **Features branches**

- **main** - This is the main, default branch. Feature branches merge back into this branch, and release branches are created off this branch.
- **release branches** - This branch is production ready.
- **feature branches** - After every push to this branch swift lint and tests are run to ensure no breaking changes are allowed.

## Creating a Release

To create a new release version:

1. Navigate to the "Actions" tab in the GitHub repository
2. Select the "Release – Draft" workflow
3. Click "Run workflow" and use the dropdown to bump the version
4. Click "Run workflow" to start the process

This workflow will:

- Create a release PR with the specified version allowing you to review
- Auto-generate changelog from git history (conventional commit PR titles)

> [!NOTE]
> The "Release – Draft" workflow maintains the `VERSION` file and `CHANGELOG.md` automatically. **Do not edit `CHANGELOG.md` in feature branches** — entries are generated from conventional commit PR titles at release time and any manual edits will be overwritten. See [RELEASING.md](./RELEASING.md) for details.
