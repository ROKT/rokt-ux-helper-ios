<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add CatalogImageGallery snapshot test covering navigation buttons, pill indicator, and gallery image rendering
- Document CatalogImageGallery in TESTING.md coverage matrix and add data URI / ARGB hex guidance

### Fixed

- Move navigation button overlay outside clipped ZStack to prevent button clipping

## [0.9.1] - 2026-04-03

### Added

- Hardcode paymentResult custom state key in CatalogDevicePayButtonViewModel ([#242](https://github.com/ROKT/rokt-ux-helper-ios/pull/242))

## [0.9.0] - 2026-04-02

### Added

- Shoppable ads ([#239](https://github.com/ROKT/rokt-ux-helper-ios/pull/239))
- Add global custom state, form validation, and placeholder predicate infrastructure ([#227](https://github.com/ROKT/rokt-ux-helper-ios/pull/227))

### Fixed

- Pin GitHub Actions to commit SHAs for supply chain security ([#229](https://github.com/ROKT/rokt-ux-helper-ios/pull/229))

### Changed

- Remove note from readme ([#230](https://github.com/ROKT/rokt-ux-helper-ios/pull/230))

## [0.8.3] - 2026-03-30

### Added

- Add device pay, user interaction, and instant purchase dismissal events ([#226](https://github.com/ROKT/rokt-ux-helper-ios/pull/226))

### Fixed

- Replace WebKit HTML parsing with lightweight custom parser ([#219](https://github.com/ROKT/rokt-ux-helper-ios/pull/219))
- Always parse HTML in RichText when defaultStyle is nil ([#220](https://github.com/ROKT/rokt-ux-helper-ios/pull/220))

### Changed

- Remove license compliance comment lines from file headers ([#225](https://github.com/ROKT/rokt-ux-helper-ios/pull/225))
- Add schema-agnostic data foundation for shoppable ads ([#223](https://github.com/ROKT/rokt-ux-helper-ios/pull/223))
- Expand and document snapshot testing ([#222](https://github.com/ROKT/rokt-ux-helper-ios/pull/222))
- Adopt shared Rokt changelog generation action ([#224](https://github.com/ROKT/rokt-ux-helper-ios/pull/224))
- Add snapshot testing section to README ([#221](https://github.com/ROKT/rokt-ux-helper-ios/pull/221))

## [0.8.2] - 2026-03-23

### Added

- Add CocoaPods distribution support with `RoktUXHelper.podspec`

### Fixed

- Fix iOS deployment target in `Package.swift` from iOS 12 to iOS 15 to match actual requirement
- Fix redundant protocol conformance declarations that caused CocoaPods build failures

## [0.8.1] - 2026-02-23

### Fixed

- Fix `SignalViewed` visibility timer check so offers emit viewed events at 50%+ visibility without requiring interaction.

## [0.8.0] - 2026-02-05

### Added

- Add configurable log levels via `RoktUX.setLogLevel(_:)` and `RoktUXConfig.Builder.logLevel(_:)`

### Deprecated

- Deprecate `RoktUXConfig.Builder.enableLogging(_:)` in favor of `logLevel(_:)`

### Fixed

- Fix crash when HTML to AttributedString conversion occurs on background thread
- Fix potential crashes from Combine subscriptions not being properly cancelled in ViewModels
- Fix crashes caused by SwiftUI state updates occurring on background threads

## [0.7.6] - 2026-01-26

### Fixed

- Fix inverted DataImageCarousel indicator colors (seen vs not-seen styles)
- Fix ImageCarouselIndicator item inheriting background color from container instead of using transparent background

## [0.7.5] - 2025-12-10

### Fixed

- Fix ScrollableColumn and ScrollableRow ignoring dimension maxHeight/maxWidth constraints when weight is set

## [0.7.4] - 2025-10-24

### Added

- Add support of new animation style for DataImageCarousel
- Add support of new style for ImageCarouselIndicator

### Fixed

- Fix visualization ImageCarouselIndicator
- Fix ProgressIndicator behavior when the page changes inside CarouselDistribution

## [0.7.3] - 2025-09-18

## [0.7.2] - 2025-09-17

### Fixed

- Fixed thread safety crash in DistributionComponents when transitioning between offers

## [0.7.1] - 2025-08-22

### Fixed

- Handle negative values in `Progression` predicate of `When` component

## [0.7.0] - 2025-08-19

### Added

- Hide the Creative Response Component when the actionType is external

### Fixed

- SignalViewed reporting for offers

### Changed

- `CarouselDistribution` styling behavior and dynamic page height

## [0.6.0] - 2025-08-05

### Added

- Add support to all distributions for clickable progress
- Fallback `imageKey` support in `DataImage` and `DataImageCarousel` nodes

### Fixed

- Ignore sub-pixel height changes by rounding before size-change callback

## [0.5.1] - 2025-06-18

### Added

- Added voiceover accessibility button trait to CloseButtonComponent, CatalogResponseButtonComponent, CreativeResponseComponent, ProgressControlComponent, & ToggleButtonComponent
- Added voiceover accessibility link trait to StaticLinkComponent

## [0.5.0] - 2025-05-28

### Added

- Enhanced offer viewed signals

## [0.4.0] - 2025-04-03

### Added

- DataImageCarousel node supported
- CatalogStackedCollection and CatalogResponseButton node supported
- `Passthrough` support in `LinkOpenTarget`

### Changed

- Refactored BNF mapping logic to simplify logic

## [0.3.1] - 2025-02-27

### Fixed

- limit view dimensions to 2 decimal places to resolve precision issues.

## [0.3.0] - 2025-02-06

### Changed

- Refactored all public classes to include the RoktUX prefix for consistency.
- Optimized rendering performance for complex layouts.

### Fixed

- Image handling: If an image fails to download, the ImageView and its styles will be removed.
- Dark Mode configuration changes now correctly apply to all offers.

## [0.2.0] - 2024-12-17

### Added

- Debug log supported
- Cache functionality for viewState Added

### Changed

- Replaced _attribute_ with _eventData_ in the RoktEventRequest

### Fixed

- Fixed fetching image twice

## [0.1.0] - 2024-10-30

### Added

- Initial implementation of UX Helper

[unreleased]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.9.1...HEAD
[0.9.1]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.9.0...0.9.1
[0.9.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.8.3...0.9.0
[0.8.3]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.8.2...0.8.3
[0.8.2]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.8.1...0.8.2
[0.8.1]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.7.6...0.8.0
[0.7.6]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.7.5...0.7.6
[0.7.5]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.7.4...0.7.5
[0.7.4]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.7.3...0.7.4
[0.7.3]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.7.2...0.7.3
[0.7.2]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.7.1...0.7.2
[0.7.1]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.7.0...0.7.1
[0.7.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.5.1...0.6.0
[0.5.1]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.4.0...0.5.0
[0.4.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/...v0.1.0
