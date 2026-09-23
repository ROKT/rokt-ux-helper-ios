import XCTest
@testable import RoktUXHelper
import DcuiSchema

/// Pins the behaviour of `StyleTransformer.updatedStyle` for every style type, independently of how
/// the merge is dispatched. A style type either merges base and override, or it is not wired in and
/// yields `nil`; both outcomes are asserted here so the set cannot change unnoticed.
@available(iOS 15, *)
final class TestStyleMerging: XCTestCase {

    private let basePadding = SpacingStylingProperties(padding: "1", margin: nil, offset: nil)
    private let overrideMargin = SpacingStylingProperties(padding: nil, margin: "2", offset: nil)

    func test_updatedStyle_mergesSpacingForEveryWiredStyleType() throws {
        try assertMergesSpacing(spacing: \.spacing) {
            StylingPropertiesModel(container: nil, background: nil, dimension: nil,
                                   flexChild: nil, spacing: $0, border: nil)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            RowStyle(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            ScrollableRowStyle(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            ColumnStyle(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            ScrollableColumnStyle(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            ZStackStyle(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            OneByOneDistributionStyles(container: nil, background: nil, border: nil,
                                       dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            BasicTextStyle(dimension: nil, flexChild: nil, spacing: $0, background: nil, text: nil)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            RichTextStyle(dimension: nil, flexChild: nil, spacing: $0, background: nil, text: nil)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            StaticImageStyles(background: nil, border: nil, dimension: nil, image: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            DataImageStyles(background: nil, border: nil, dimension: nil, image: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            CloseButtonStyles(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            IndicatorStyles(container: nil, background: nil, border: nil, dimension: nil,
                            flexChild: nil, spacing: $0, text: nil)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            ProgressIndicatorStyles(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            StaticLinkStyles(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            CreativeResponseStyles(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            ProgressControlStyle(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            GroupedDistributionStyles(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            ToggleButtonStateTriggerStyle(container: nil, background: nil, border: nil,
                                          dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            DataImageCarouselStyles(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            DataImageCarouselIndicatorStyles(container: nil, background: nil, border: nil,
                                             dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            CatalogDevicePayButtonStyles(container: nil, background: nil, border: nil,
                                         dimension: nil, flexChild: nil, spacing: $0)
        }
        try assertMergesSpacing(spacing: \.spacing) {
            CatalogResponseButtonStyles(container: nil, background: nil, border: nil,
                                        dimension: nil, flexChild: nil, spacing: $0)
        }
    }

    /// `InLineTextStyle` carries no spacing, so it is merged through its text properties instead.
    func test_updatedStyle_mergesInlineTextStyle() throws {
        let defaultStyle = InLineTextStyle(text: inlineText(fontFamily: "Arial", fontSize: 12))
        let pressed = InLineTextStyle(text: inlineText(fontFamily: nil, fontSize: 14))

        let merged = try XCTUnwrap(StyleTransformer.updatedStyle(defaultStyle, newStyle: pressed))

        XCTAssertEqual(merged.text.fontFamily, "Arial")
        XCTAssertEqual(merged.text.fontSize, 14)
    }

    /// The merge dispatcher covers the style types that reach a rendered component. The types below
    /// are accepted by `updatedStyles` but produce no merge today, which drops breakpoint
    /// inheritance and every non-default state for them. Wiring them in is a behavioural change and
    /// is deliberately out of scope here; this test exists so the change is a conscious one.
    func test_updatedStyle_returnsNilForStyleTypesOutsideTheMergeDispatcher() throws {
        XCTAssertNil(try StyleTransformer.updatedStyle(
            OverlayStyles(container: nil, background: nil, border: nil, dimension: nil, flexChild: nil, spacing: basePadding),
            newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            OverlayWrapperStyles(container: nil, background: nil), newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            BottomSheetStyles(container: nil, background: nil, border: nil, dimension: nil,
                              flexChild: nil, spacing: basePadding),
            newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            BottomSheetWrapperStyles(container: nil, background: nil), newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            CarouselDistributionStyles(container: nil, background: nil, border: nil, dimension: nil,
                                       flexChild: nil, spacing: basePadding),
            newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            CatalogDropdownStyles(container: nil, background: nil, border: nil, dimension: nil,
                                  flexChild: nil, spacing: basePadding, text: nil),
            newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            CatalogImageGalleryStyles(container: nil, background: nil, border: nil, dimension: nil,
                                      flexChild: nil, spacing: basePadding, text: nil),
            newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            CatalogImageGalleryIndicatorStyles(container: nil, background: nil, border: nil, dimension: nil,
                                               flexChild: nil, spacing: basePadding),
            newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            CatalogStackedCollectionStyles(container: nil, background: nil, border: nil, dimension: nil,
                                           flexChild: nil, spacing: basePadding),
            newStyle: nil))
        XCTAssertNil(try StyleTransformer.updatedStyle(
            CatalogCombinedCollectionStyles(container: nil, background: nil, border: nil, dimension: nil,
                                            flexChild: nil, spacing: basePadding),
            newStyle: nil))
    }

    func test_updatedStyle_returnsNilWhenThereIsNoDefaultStyle() throws {
        let pressed = RowStyle(container: nil, background: nil, border: nil,
                               dimension: nil, flexChild: nil, spacing: overrideMargin)

        XCTAssertNil(try StyleTransformer.updatedStyle(nil, newStyle: pressed))
    }

    func test_updatedStyle_propagatesValidationErrors() throws {
        let invalid = RowStyle(container: nil,
                               background: BackgroundStylingProperties(backgroundColor: ThemeColor(light: "nope", dark: nil),
                                                                       backgroundImage: nil),
                               border: nil, dimension: nil, flexChild: nil, spacing: nil)

        XCTAssertThrowsError(try StyleTransformer.updatedStyle(invalid, newStyle: nil))
    }

    /// `updatedStyles` derives every state from the merged default, so a block that authors only a
    /// hovered override still resolves pressed and disabled. This is the behaviour that silently
    /// disappears when a style type is missing from the dispatcher.
    func test_updatedStyles_derivesEveryStateFromTheMergedDefault() throws {
        let blocks = [
            BasicStateStylingBlock(default: RowStyle(container: nil, background: nil, border: nil,
                                                     dimension: nil, flexChild: nil, spacing: basePadding),
                                   pressed: nil,
                                   hovered: RowStyle(container: nil, background: nil, border: nil,
                                                     dimension: nil, flexChild: nil, spacing: overrideMargin),
                                   focussed: nil,
                                   disabled: nil)
        ]

        let merged = try StyleTransformer.updatedStyles(blocks)

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.default.spacing?.padding, "1")
        XCTAssertEqual(merged.first?.hovered?.spacing?.padding, "1")
        XCTAssertEqual(merged.first?.hovered?.spacing?.margin, "2")
        XCTAssertEqual(merged.first?.pressed?.spacing?.padding, "1")
        XCTAssertNil(merged.first?.pressed?.spacing?.margin)
    }

    // MARK: Helpers

    private func assertMergesSpacing<T: Decodable>(
        spacing: KeyPath<T, SpacingStylingProperties?>,
        file: StaticString = #filePath,
        line: UInt = #line,
        make: (SpacingStylingProperties) -> T
    ) throws {
        let merged = try XCTUnwrap(StyleTransformer.updatedStyle(make(basePadding), newStyle: make(overrideMargin)),
                                   "\(T.self) is not wired into the style merge",
                                   file: file, line: line)

        XCTAssertEqual(merged[keyPath: spacing]?.padding, "1", "\(T.self) lost the base padding", file: file, line: line)
        XCTAssertEqual(merged[keyPath: spacing]?.margin, "2", "\(T.self) lost the override margin", file: file, line: line)
    }

    private func inlineText(fontFamily: String?, fontSize: Float) -> InlineTextStylingProperties {
        InlineTextStylingProperties(textColor: nil, fontSize: fontSize, fontFamily: fontFamily, fontWeight: nil,
                                    baselineTextAlign: nil, fontStyle: nil, textTransform: nil,
                                    letterSpacing: nil, textDecoration: nil)
    }
}
