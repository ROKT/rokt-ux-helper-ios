import XCTest
import SwiftUI
import UIKit
import ViewInspector
import SnapshotTesting
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15.0, *)
final class TestScrollableColumn: XCTestCase {
    private var hostingWindow: UIWindow?

    override func tearDown() {
        hostingWindow?.isHidden = true
        hostingWindow = nil
        super.tearDown()
    }

    func test_column() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_model()))

        let vstack = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ScrollableColumnComponent.self)
            .scrollView()
            .view(ColumnComponent.self)
            .actualView()
            .inspect()
            .vStack()

        // test custom modifier class
        let paddingModifier = try vstack.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24))

        // test the effect of custom modifier
        let padding = try vstack.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 18.0, leading: 24.0, bottom: 0.0, trailing: 24.0))

        // The viewport, not its content, owns vertical weight sizing.
        let flexFrame = try vstack.flexFrame()
        XCTAssertTrue(flexFrame.maxHeight.isNaN)

        // background
        let backgroundModifier = try vstack.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle

        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))

        // border
        let borderModifier = try vstack.modifier(BorderModifier.self)
        let borderStyle = try borderModifier.actualView().borderStyle

        XCTAssertNil(borderStyle)

        // alignment
        let alignment = try vstack.alignment()
        XCTAssertEqual(alignment, .center)
    }

    // MARK: - Tests for ScrollableColumnComponent computed properties

    func test_scrollableColumnComponent_computedProperties_withWeight() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_model()))

        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ScrollableColumnComponent.self)
            .actualView()

        // Test computed properties
        XCTAssertNotNil(sut.style)
        XCTAssertNotNil(sut.containerStyle)
        XCTAssertNotNil(sut.flexStyle)
        XCTAssertEqual(sut.flexStyle?.weight, 1)

        // Test alignment properties
        XCTAssertEqual(sut.verticalAlignment, .center)
        XCTAssertEqual(sut.horizontalAlignment, .center)

        // Test weightProperties
        XCTAssertEqual(sut.weightProperties.weight, 1)
        XCTAssertEqual(sut.weightProperties.parent, .column)

        // When only weight is set (no maxHeight in dimensions), dimensionMaxHeight should be nil
        XCTAssertNil(sut.dimensionMaxHeight)
    }

    func test_scrollableColumnComponent_dimensionMaxHeight_prioritizedOverWeight() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_model_with_max_height()))

        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ScrollableColumnComponent.self)
            .actualView()

        // Test that both weight and maxHeight are present in the style
        XCTAssertNotNil(sut.flexStyle)
        XCTAssertEqual(sut.flexStyle?.weight, 1)
        XCTAssertNotNil(sut.dimensionStyle)
        XCTAssertEqual(sut.dimensionStyle?.maxHeight, 200)

        // Test that dimensionMaxHeight returns the dimension maxHeight value
        // This verifies that dimension maxHeight takes precedence over weight
        XCTAssertEqual(sut.dimensionMaxHeight, 200)
    }

    func test_scrollableColumnComponent_dimensionStyle_accessible() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_model_with_max_height()))

        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ScrollableColumnComponent.self)
            .actualView()

        // Verify dimensionStyle is accessible and contains expected values
        XCTAssertNotNil(sut.dimensionStyle)
        XCTAssertEqual(sut.dimensionStyle?.maxHeight, 200)
    }

    func test_scrollableColumn_withTallContent_hasScrollableViewport() throws {
        let hostingController = try makeTallContentHostingController()
        let scrollView = try waitForScrollableViewport(in: hostingController)

        XCTAssertEqual(scrollView.bounds.height, 200, accuracy: 1)
        XCTAssertGreaterThan(scrollView.contentSize.height, scrollView.bounds.height)
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

    func testSnapshot_tallScrollableContentAtBottom() throws {
        let hostingController = try makeTallContentHostingController()
        let scrollView = try waitForScrollableViewport(in: hostingController)

        scrollView.setContentOffset(
            CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height),
            animated: false
        )
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            of: hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }

    // MARK: - Helpers

    func get_model() throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let column = ModelTestData.ColumnData.columnWithBasicText()
        return try transformer.getColumn(
            column.styles,
            children: transformer.transformChildren(column.children, context: .outer([]))
        )
    }

    func get_model_with_max_height() throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let column = ModelTestData.ColumnData.scrollableColumnWithMaxHeight()
        return try transformer.getColumn(
            column.styles,
            children: transformer.transformChildren(column.children, context: .outer([]))
        )
    }

    private func get_tall_content_model() throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let column = ModelTestData.ColumnData.scrollableColumnWithTallContent()
        return try transformer.getColumn(
            column.styles,
            children: transformer.transformChildren(column.children, context: .outer([]))
        )
    }

    private func makeTallContentHostingController() throws -> UIHostingController<AnyView> {
        let view = AnyView(
            TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_tall_content_model()))
                .frame(width: 350, height: 240)
        )
        let hostingController = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingWindow = window
        return hostingController
    }

    private func waitForScrollableViewport(
        in hostingController: UIHostingController<AnyView>
    ) throws -> UIScrollView {
        hostingController.view.setNeedsLayout()

        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            hostingController.view.layoutIfNeeded()

            if let scrollView = findScrollView(in: hostingController.view),
               scrollView.bounds.height > 0,
               scrollView.bounds.height <= 201 {
                return scrollView
            }

            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }

        XCTFail("Timed out waiting for the scrollable column viewport")
        throw ScrollableColumnTestError.viewportNotFound
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }

        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }

        return nil
    }

}

private enum ScrollableColumnTestError: Error {
    case viewportNotFound
}
