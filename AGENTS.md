# Rokt UX Helper iOS

## Project Overview

RoktUXHelper is a native iOS Swift library that enables partner applications to render tailored user
experiences (offers, overlays, bottom sheets, embedded layouts) from Rokt backend responses. It
transforms layout schema into SwiftUI/UIKit views, handles BNF placeholder resolution, manages
user interaction events, and provides event hooks for backend integration. The library is distributed
as a Swift Package and supports both server-to-server (S2S) and SDK integration types.

**Current version:** 0.8.0 (see `VERSION` file)

**Owned by:** sdk-engineering (ROKT/sdk-engineering)
**Resident experts:** James Newman, Thomson Thomas
**On-call:** Mobile Integrations (OpsGenie schedule)

## Architecture

```text
RoktUX (entry point)
  |
  +-- LayoutTransformer --> LayoutSchemaViewModel --> UI Components
  |     |
  |     +-- CreativeSyntaxMapper (BNF placeholder resolution)
  |     +-- StyleTransformer (style conversion)
  |     +-- AttributedStringTransformer (HTML/rich text)
  |
  +-- LayoutState (state management, action collection)
  |
  +-- EventService / EventProcessor (signals, diagnostics, platform events)
```

The library follows MVVM with unidirectional data flow:

1. **RoktUX** orchestrates layout loading and event delegation
2. **LayoutTransformer** converts backend schema into view models
3. **CreativeSyntaxMapper** resolves BNF placeholders in content
4. **LayoutSchemaViewModel** provides framework-agnostic UI representation
5. **LayoutState** manages component state and user interactions
6. **UI Components** render as SwiftUI views (overlays, bottom sheets, embedded layouts)

Layout types supported: Overlay, BottomSheet (fixed/dynamic), Embedded.

## Tech Stack

- **Language:** Swift 5.9+ (swift-tools-version: 5.9)
- **Minimum deployment target:** iOS 12.0 (Package.swift), iOS 15.0+ required at runtime
- **UI frameworks:** SwiftUI, UIKit, Combine
- **Build system:** Swift Package Manager (SPM), Xcode 16.x
- **Key dependencies:**
  - `dcui-swift-schema` 2.3.0 (layout schema parsing)
  - `ViewInspector` 0.10.3 (test only - SwiftUI view inspection)
  - `swift-snapshot-testing` 1.18.9 (test only - visual regression)
- **Linting:** Trunk (SwiftLint 0.58.2, SwiftFormat 0.55.5, markdownlint 0.44.0, Prettier 3.5.3, and more)

## Development Guide

### Prerequisites

- Latest Xcode (16.x) with iOS Simulator
- Git: `git clone git@github.com:ROKT/rokt-ux-helper-ios.git`
- Trunk CLI (optional, for linting)

### Quick Start

1. Open `Package.swift` in Xcode
2. Let SPM resolve dependencies automatically
3. Select an iOS Simulator target (iPhone 16 Pro recommended)
4. Build with `Cmd+B`, run tests with `Cmd+U`

### Common Tasks

| Task             | Command                                                                                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Build            | `xcodebuild -scheme RoktUXHelper -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' build`                        |
| Run tests        | `xcodebuild -scheme RoktUXHelper -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -enableCodeCoverage YES test` |
| Clean            | `xcodebuild -scheme RoktUXHelper clean`                                                                                         |
| Resolve packages | `swift package resolve --verbose`                                                                                               |
| Reset SPM cache  | `swift package reset`                                                                                                           |
| Lint (Trunk)     | `trunk check --all`                                                                                                             |
| Format (Trunk)   | `trunk fmt --all`                                                                                                               |

### Example App

Located in `Example/`. Build with:

```bash
xcodebuild -project Example/Example.xcodeproj -scheme Example \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' build
```

Or open `Example/Example.xcodeproj` in Xcode. The example demonstrates both SwiftUI (`RoktLayoutView`)
and UIKit (`RoktLayoutUIView`) integration patterns.

## CI/CD Pipeline

CI runs on **GitHub Actions** (macOS runners).

### Workflows

| Workflow                 | Trigger                             | Description                                                              |
| ------------------------ | ----------------------------------- | ------------------------------------------------------------------------ |
| `pull-request.yml`       | Push to main, PRs                   | Trunk check (all linters) + unit tests with code coverage                |
| `release-from-main.yml`  | Push to main when `VERSION` changes | Runs tests, extracts changelog, creates GitHub release                   |
| `draft-release.yml`      | Manual dispatch                     | Bumps version (major/minor/patch), updates CHANGELOG, creates release PR |
| `patch-old-release.yml`  | Manual dispatch                     | Creates patch branch from existing release tag                           |
| `create-workstation.yml` | Manual dispatch                     | Creates a workstation branch                                             |
| `trunk-upgrade.yml`      | Monthly cron / manual               | Upgrades Trunk linter versions                                           |

### PR Checks

- **Trunk Check:** Runs all enabled linters (SwiftLint, SwiftFormat, markdownlint, Prettier, etc.)
- **Unit Tests:** Runs on macOS-15, Xcode 16.4.0, iOS Simulator (iPhone 16, iOS 18+)
- **Code Coverage:** Uploaded to Codecov with 1% threshold for project and patch targets
- **GChat Notification:** Notifies Mobile Integration channel when non-draft PRs pass

### Release Process

1. Go to Actions > "Create draft release from main" workflow
2. Select version bump type (major/minor/patch)
3. Review the generated release PR (version bump + changelog update)
4. Merge the release PR to main, which triggers `release-from-main.yml`
5. **Important:** Only update `VERSION` via the release workflow; decline PRs with manual VERSION changes

## Project Structure

```text
Sources/RoktUXHelper/
  RoktUX.swift              # Main entry point, layout loading orchestration
  Data/
    Expansion/              # BNF placeholder resolution (syntax mapping)
    Model/                  # Data models (events, experience response, styles, constants)
  Services/
    ActionCollection.swift  # User interaction action registry
    LayoutState.swift       # State management for layouts
    LayoutTransformer/      # Schema-to-ViewModel transformation
    Events/                 # Event processing and service layer
    Decoder/                # JSON decoding
    Logging/                # RoktUXLogger with configurable log levels
    Validator/              # Input validation
  UI/
    RoktLayoutView/         # SwiftUI view (RoktLayoutView) and ViewModel
    RoktLayoutUIView.swift  # UIKit wrapper view
    Components/             # All UI components (30+ SwiftUI views)
      ViewModel/            # Component-specific ViewModels
      Style/                # Style application
      Common/               # Shared component utilities
      Config/               # Component configuration
      Distribution/         # Offer distribution logic
      EmbeddedComponent/    # Embedded layout rendering
  Utils/                    # Extensions and utilities
Tests/RoktUXHelperTests/
  Data/                     # Data layer tests
  Services/                 # Service layer tests
  UI/                       # UI component tests (ViewInspector + snapshot)
  Utils/                    # Utility tests
  Supporting Files/         # Test fixtures (JSON responses, etc.)
Example/
  Example.xcodeproj         # Example app Xcode project
  Example/                  # Example app source (SwiftUI + UIKit demos)
```

## Code Style & Linting

- **Trunk** manages all linters via `.trunk/trunk.yaml`
- **SwiftLint** (`.swiftlint.yml`): Line length warning at 130, error at 160. Disabled rules:
  `identifier_name`, `force_cast`, `weak_delegate`, `function_parameter_count`, `file_length`,
  `type_body_length`, `cyclomatic_complexity`, `function_body_length`. Tests are excluded from linting.
- **SwiftFormat** 0.55.5 for code formatting
- **Pre-commit hooks:** `trunk-fmt-pre-commit` and `trunk-check-pre-commit` are enabled
- **Pre-push hooks:** `trunk-check-pre-push` is enabled
- Architecture: Follow MVVM pattern, maintain Data/Services/UI layer separation

## Key Dependencies & Gotchas

- **DcuiSchema** (`dcui-swift-schema`): Core schema library. To update, bump version in `Package.swift`
  and verify `schema.swift` is updated. Schema source of truth is [dcui-layout-schema](https://github.com/ROKT/dcui-layout-schema).
- **iOS 15.0+ required at runtime** even though Package.swift declares iOS 12.0 as platform minimum.
  Layouts will not render on earlier versions.
- Schema parsing errors are handled gracefully but may result in empty views.
- HTML to AttributedString conversion must occur on the main thread.

## Observability

- **Cortex tag:** `rokt-ux-helper-ios`
- **Cortex group:** `lang-swift`
- **Buildkite pipeline:** `ux-helper-ios-build`
- **Codecov:** Coverage reports at [codecov.io/gh/ROKT/rokt-ux-helper-ios](https://codecov.io/gh/ROKT/rokt-ux-helper-ios)

## Maintaining This Document

When making changes to this repository that affect the information documented here
(build commands, dependencies, architecture, deployment configuration, etc.),
please update this document to keep it accurate. This file is the primary reference
for AI coding assistants working in this codebase.
