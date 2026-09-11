import XCTest
import SwiftUI
import UIKit
import ViewInspector
import SnapshotTesting
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15.0, *)
final class TestScrollableRow: XCTestCase {

    func test_row() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableRow(try get_model()))

        let row = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RowComponent.self)

        // A scrollable row is a RowComponent whose stack is wrapped in a ScrollView.
        XCTAssertTrue(try row.actualView().isScrollable)

        // Sizing and decoration are applied to the viewport, so the styling modifiers
        // wrap the ScrollView rather than the stack inside it.
        let scrollView = try row.actualView().inspect().scrollView()
        let hstack = try scrollView.hStack()
        XCTAssertEqual(hstack.count, 1)

        // test custom modifier class
        let paddingModifier = try scrollView.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24))

        // background
        let backgroundModifier = try scrollView.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle

        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))

        // border
        let borderModifier = try scrollView.modifier(BorderModifier.self)
        let borderStyle = try borderModifier.actualView().borderStyle

        XCTAssertNil(borderStyle)

        // alignment
        let alignment = try hstack.alignment()
        XCTAssertEqual(alignment, .center)

        // frame
        let flexFrame = try scrollView.flexFrame()
        XCTAssertEqual(flexFrame.minHeight, 24)
        XCTAssertEqual(flexFrame.maxHeight, 24)
        XCTAssertEqual(flexFrame.minWidth, 140)
        XCTAssertEqual(flexFrame.maxWidth, 140)
    }

    func test_rowComponent_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableRow(try get_model()))

        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RowComponent.self)
            .actualView()

        let defaultStyle = sut.model.defaultStyle?[0]

        XCTAssertEqual(sut.style, defaultStyle)

        XCTAssertEqual(sut.containerStyle, defaultStyle?.container)
        XCTAssertEqual(sut.dimensionStyle, defaultStyle?.dimension)
        XCTAssertEqual(sut.flexStyle, defaultStyle?.flexChild)
        XCTAssertEqual(sut.backgroundStyle, defaultStyle?.background)
        XCTAssertEqual(sut.spacingStyle, defaultStyle?.spacing)
        XCTAssertEqual(sut.borderStyle, defaultStyle?.border)

        XCTAssertEqual(sut.passableBackgroundStyle, defaultStyle?.background)

        XCTAssertEqual(sut.verticalAlignment, .center)
        XCTAssertEqual(sut.horizontalAlignment, .center)

        XCTAssertEqual(sut.accessibilityBehavior, .contain)
    }

    // MARK: - Viewport sizing

    func test_scrollableRow_withWideContent_scrollsBeyondTheViewport() throws {
        // No width style at all: the row's `fitWidth` default used to clamp the content
        // to the parent width, leaving the trailing sections unreachable.
        let scrollView = try renderScrollableRow(
            ModelTestData.RowData.scrollableRowWithWideContent(),
            hostSize: CGSize(width: 350, height: 200)
        )

        // 350pt host less the 8pt horizontal padding that sits outside the viewport.
        XCTAssertEqual(scrollView.bounds.width, 334, accuracy: 1)
        // Six 80pt sections with five 8pt gaps.
        XCTAssertEqual(scrollView.contentSize.width, 6 * 80 + 5 * 8, accuracy: 1)
        XCTAssertGreaterThan(scrollView.contentSize.width, scrollView.bounds.width)
    }

    func test_scrollableRow_withMaxWidthAndWeight_prefersMaxWidth() throws {
        let scrollView = try renderScrollableRow(
            ModelTestData.RowData.scrollableRowWithMaxWidth(),
            hostSize: CGSize(width: 350, height: 200)
        )

        // weight 1 alone would fill the 350pt host; maxWidth wins.
        // 200 less the 24pt left and right padding, which sit outside the viewport.
        XCTAssertEqual(scrollView.bounds.width, 152, accuracy: 1)
    }

    func test_scrollableRow_withStretchAndMaxWidth_prefersMaxWidth() throws {
        let scrollView = try renderScrollableRow(
            ModelTestData.RowData.scrollableRowWithStretchAndMaxWidth(),
            hostSize: CGSize(width: 350, height: 200)
        )

        // `alignSelf: stretch` fills the parent, but must not lift the authored cap:
        // 200 less the 24pt left and right padding, not the full 350pt host.
        XCTAssertEqual(scrollView.bounds.width, 152, accuracy: 1)
    }

    func test_scrollableRow_withMinWidth_expandsViewportBeyondItsContent() throws {
        // The host is deliberately narrower than minWidth, so a viewport that merely
        // wrapped its 48pt of content could not pass this.
        let scrollView = try renderScrollableRow(
            ModelTestData.RowData.scrollableRowWithMinWidth(),
            hostSize: CGSize(width: 150, height: 200)
        )

        // 200pt minimum less the 8pt horizontal padding outside the viewport.
        XCTAssertEqual(scrollView.bounds.width, 184, accuracy: 1)
    }

    func test_scrollableRow_withPercentageChildren_measuresThemAgainstTheViewport() throws {
        let scrollView = try renderScrollableRow(
            ModelTestData.RowData.scrollableRowWithPercentageChildren(),
            hostSize: CGSize(width: 400, height: 200)
        )

        // Fixed 200pt viewport, two 50% children: they fill it exactly rather than
        // resolving against their own intrinsic width.
        XCTAssertEqual(scrollView.bounds.width, 200, accuracy: 1)
        XCTAssertEqual(scrollView.contentSize.width, 200, accuracy: 1)
    }

    func test_scrollableRow_withWrapContentWidth_wrapsItsContent() throws {
        let scrollView = try renderScrollableRow(
            ModelTestData.RowData.scrollableRowWrapsContent(),
            hostSize: CGSize(width: 400, height: 200)
        )

        // An 80pt child. A greedy ScrollView would take the full 400 instead.
        XCTAssertEqual(scrollView.bounds.width, 80, accuracy: 1)
        XCTAssertEqual(scrollView.contentSize.width, 80, accuracy: 1)
    }

    func test_scrollableRow_withNarrowContent_keepsMainAxisAlignment() throws {
        let scrollView = try renderScrollableRow(
            ModelTestData.RowData.scrollableRowCentersShortContent(),
            hostSize: CGSize(width: 400, height: 200)
        )

        // A ScrollView pins its content to the leading edge, so `justifyContent: center` can
        // only be honoured if the stack fills the viewport rather than its intrinsic 120pt.
        XCTAssertEqual(scrollView.bounds.width, 300, accuracy: 1)
        XCTAssertEqual(scrollView.contentSize.width, 300, accuracy: 1)
    }

    // MARK: - Snapshots

    func testSnapshot() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableRow(try get_model()))
            .frame(width: 350, height: 350)

        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(
            of: hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_wideScrollableContentAtStart() throws {
        let host = try makeScrollableRowHost(
            ModelTestData.RowData.scrollableRowWithWideContent(),
            hostSize: CGSize(width: 350, height: 200)
        )
        _ = try host.settledScrollView()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_wideScrollableContentAtEnd() throws {
        let host = try makeScrollableRowHost(
            ModelTestData.RowData.scrollableRowWithWideContent(),
            hostSize: CGSize(width: 350, height: 200)
        )
        let scrollView = try host.settledScrollView()

        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentSize.width - scrollView.bounds.width, y: 0),
            animated: false
        )
        host.layoutIfNeeded()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_minWidthExpandsViewport() throws {
        let host = try makeScrollableRowHost(
            ModelTestData.RowData.scrollableRowWithMinWidth(),
            hostSize: CGSize(width: 300, height: 200)
        )
        _ = try host.settledScrollView()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_percentageChildrenFillViewport() throws {
        let host = try makeScrollableRowHost(
            ModelTestData.RowData.scrollableRowWithPercentageChildren(),
            hostSize: CGSize(width: 400, height: 200)
        )
        _ = try host.settledScrollView()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_narrowContentKeepsMainAxisAlignment() throws {
        let host = try makeScrollableRowHost(
            ModelTestData.RowData.scrollableRowCentersShortContent(),
            hostSize: CGSize(width: 400, height: 200)
        )
        _ = try host.settledScrollView()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    // MARK: - Helpers

    func get_model() throws -> RowViewModel {
        try get_row_model(ModelTestData.RowData.rowWithBasicText())
    }

    private func get_row_model(_ row: RowModel<LayoutSchemaModel, WhenPredicate>) throws -> RowViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        return try transformer.getRow(row.styles, children: transformer.transformChildren(row.children, context: .outer([])))
    }

    private func renderScrollableRow(
        _ row: RowModel<LayoutSchemaModel, WhenPredicate>,
        hostSize: CGSize
    ) throws -> UIScrollView {
        try makeScrollableRowHost(row, hostSize: hostSize).settledScrollView()
    }

    private func makeScrollableRowHost(
        _ row: RowModel<LayoutSchemaModel, WhenPredicate>,
        hostSize: CGSize
    ) throws -> ScrollViewHost {
        ScrollViewHost(layout: .scrollableRow(try get_row_model(row)), size: hostSize)
    }
}
