<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[unreleased]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.5.1...HEAD
[0.5.1]: https://github.com/ROKT/rokt-ux-helper-ios/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.4.0...0.5.0
[0.4.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ROKT/rokt-ux-helper-ios/compare/...v0.1.0
