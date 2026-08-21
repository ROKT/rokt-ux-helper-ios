import XCTest
import SwiftUI
import UIKit
import ViewInspector
import SnapshotTesting
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15.0, *)
final class TestScrollableColumn: XCTestCase {
    func test_column() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_model()))

        let column = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ColumnComponent.self)

        // A scrollable column is a ColumnComponent whose stack is wrapped in a ScrollView.
        XCTAssertTrue(try column.actualView().isScrollable)

        // Sizing and decoration are applied to the viewport, so the styling modifiers
        // wrap the ScrollView rather than the stack inside it.
        let scrollView = try column.actualView().inspect().scrollView()

        // test custom modifier class
        let paddingModifier = try scrollView.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24))

        // Test weight = 1 add maxHeight .infinity
        let flexFrame = try scrollView.flexFrame()
        XCTAssertEqual(flexFrame.maxHeight, .infinity)

        // background
        let backgroundModifier = try scrollView.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle

        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))

        // border
        let borderModifier = try scrollView.modifier(BorderModifier.self)
        let borderStyle = try borderModifier.actualView().borderStyle

        XCTAssertNil(borderStyle)

        // alignment
        let alignment = try scrollView.vStack().alignment()
        XCTAssertEqual(alignment, .center)
    }

    // MARK: - Viewport sizing

    func test_scrollableColumn_withMaxHeight_boundsViewportAndScrollsContent() throws {
        let scrollView = try renderScrollableColumn(
            ModelTestData.ColumnData.scrollableColumnWithTallContent(),
            hostHeight: 240
        )

        // maxHeight caps the viewport — 200 less the 8pt padding that sits outside it ...
        XCTAssertEqual(scrollView.bounds.height, 184, accuracy: 1)
        // ... while the content keeps its full height, so there is somewhere to scroll to.
        XCTAssertEqual(scrollView.contentSize.height, 6 * 80 + 5 * 8, accuracy: 1)
        XCTAssertGreaterThan(scrollView.contentSize.height, scrollView.bounds.height)
    }

    func test_scrollableColumn_withMaxHeightAndWeight_prefersMaxHeight() throws {
        let scrollView = try renderScrollableColumn(
            ModelTestData.ColumnData.scrollableColumnWithMaxHeight(),
            hostHeight: 400
        )

        // weight 1 alone would fill the 400pt host; maxHeight wins.
        // 200 less the 18pt top padding, which sits outside the viewport.
        XCTAssertEqual(scrollView.bounds.height, 182, accuracy: 1)
    }

    func test_scrollableColumn_withMinHeight_expandsViewportBeyondItsContent() throws {
        // The host is deliberately shorter than minHeight, so a viewport that merely
        // wrapped its 48pt of content could not pass this.
        let scrollView = try renderScrollableColumn(
            ModelTestData.ColumnData.scrollableColumnWithMinHeight(),
            hostHeight: 150
        )

        // 200pt minimum less the 8pt padding outside the viewport.
        XCTAssertEqual(scrollView.bounds.height, 184, accuracy: 1)
    }

    func test_scrollableColumn_withPercentageChildren_measuresThemAgainstTheViewport() throws {
        let scrollView = try renderScrollableColumn(
            ModelTestData.ColumnData.scrollableColumnWithPercentageChildren(),
            hostHeight: 400
        )

        // Fixed 200pt viewport, two 50% children: they fill it exactly rather than
        // resolving against their own intrinsic height.
        XCTAssertEqual(scrollView.bounds.height, 200, accuracy: 1)
        XCTAssertEqual(scrollView.contentSize.height, 200, accuracy: 1)
    }

    func test_scrollableColumn_withoutHeightStyle_wrapsItsContent() throws {
        let scrollView = try renderScrollableColumn(
            ModelTestData.ColumnData.scrollableColumnWrapsContent(),
            hostHeight: 400
        )

        // An 80pt child. A greedy ScrollView would take the full 400 instead.
        XCTAssertEqual(scrollView.bounds.height, 80, accuracy: 1)
        XCTAssertEqual(scrollView.contentSize.height, 80, accuracy: 1)
    }

    // MARK: - Snapshots

    func testSnapshot() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_model()))
            .frame(width: 350, height: 350)

        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(
            of: hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_tallScrollableContentAtTop() throws {
        let host = try makeScrollableColumnHost(
            ModelTestData.ColumnData.scrollableColumnWithTallContent(),
            hostHeight: 240
        )
        _ = try host.settledScrollView()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_tallScrollableContentAtBottom() throws {
        let host = try makeScrollableColumnHost(
            ModelTestData.ColumnData.scrollableColumnWithTallContent(),
            hostHeight: 240
        )
        let scrollView = try host.settledScrollView()

        scrollView.setContentOffset(
            CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height),
            animated: false
        )
        host.layoutIfNeeded()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_minHeightExpandsViewport() throws {
        let host = try makeScrollableColumnHost(
            ModelTestData.ColumnData.scrollableColumnWithMinHeight(),
            hostHeight: 300
        )
        _ = try host.settledScrollView()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    func testSnapshot_percentageChildrenFillViewport() throws {
        let host = try makeScrollableColumnHost(
            ModelTestData.ColumnData.scrollableColumnWithPercentageChildren(),
            hostHeight: 400
        )
        _ = try host.settledScrollView()

        assertSnapshot(
            of: host.hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    // MARK: - Helpers

    func get_model() throws -> ColumnViewModel {
        try get_column_model(ModelTestData.ColumnData.columnWithBasicText())
    }

    private func get_column_model(
        _ column: ColumnModel<LayoutSchemaModel, WhenPredicate>
    ) throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        return try transformer.getColumn(
            column.styles,
            children: transformer.transformChildren(column.children, context: .outer([]))
        )
    }

    private func renderScrollableColumn(
        _ column: ColumnModel<LayoutSchemaModel, WhenPredicate>,
        hostHeight: CGFloat
    ) throws -> UIScrollView {
        try makeScrollableColumnHost(column, hostHeight: hostHeight).settledScrollView()
    }

    private func makeScrollableColumnHost(
        _ column: ColumnModel<LayoutSchemaModel, WhenPredicate>,
        hostHeight: CGFloat
    ) throws -> ScrollViewHost {
        ScrollViewHost(
            layout: .scrollableColumn(try get_column_model(column)),
            size: CGSize(width: 350, height: hostHeight)
        )
    }
}
