import XCTest
import SwiftUI
@testable import RoktUXHelper
import DcuiSchema
import SnapshotTesting

@available(iOS 15, *)
final class TestPercentageDimension: XCTestCase {

    /// Twice the longest side of the largest iPad, in points.
    private let maximumLength: CGFloat = 2752

    // MARK: - Height

    func test_percentageHeight_withinParent_isAShareOfTheParent() {
        XCTAssertEqual(heightModifier(parent: 300, percentage: 50).frameHeight, 150)
    }

    /// A parent that wraps its content measures the child too, so a share above 100% would
    /// grow on every layout pass. It fills the parent instead, as it does on Android.
    func test_percentageHeight_aboveParent_fillsTheParent() {
        XCTAssertEqual(heightModifier(parent: 300, percentage: 200).frameHeight, 300)
    }

    func test_percentageHeight_nonFiniteParent_staysFinite() {
        XCTAssertEqual(heightModifier(parent: .infinity, percentage: 100).frameHeight, maximumLength)
        XCTAssertEqual(heightModifier(parent: .infinity, percentage: 0).frameHeight, 0)
        XCTAssertEqual(heightModifier(parent: .nan, percentage: 50).frameHeight, 0)
    }

    func test_percentageHeight_marginLargerThanShare_isZero() {
        let margin = FrameAlignmentProperty(top: 20, right: 0, bottom: 20, left: 0)
        XCTAssertEqual(heightModifier(parent: 100, percentage: 10, margin: margin).frameHeight, 0)
    }

    // MARK: - Width

    func test_percentageWidth_withinParent_isAShareOfTheParent() {
        XCTAssertEqual(widthModifier(parent: 300, percentage: 50).frameWidth, 150)
    }

    func test_percentageWidth_aboveParent_fillsTheParent() {
        XCTAssertEqual(widthModifier(parent: 300, percentage: 200).frameWidth, 300)
    }

    func test_percentageWidth_nonFiniteParent_staysFinite() {
        XCTAssertEqual(widthModifier(parent: .infinity, percentage: 100).frameWidth, maximumLength)
        XCTAssertEqual(widthModifier(parent: .infinity, percentage: 0).frameWidth, 0)
        XCTAssertEqual(widthModifier(parent: .nan, percentage: 50).frameWidth, 0)
    }

    func test_percentageWidth_marginLargerThanShare_isZero() {
        let margin = FrameAlignmentProperty(top: 0, right: 20, bottom: 0, left: 20)
        XCTAssertEqual(widthModifier(parent: 100, percentage: 10, margin: margin).frameWidth, 0)
    }

    // MARK: - Embedded layout

    func test_embedded_percentageHeightAboveParent_settlesAtAFiniteHeight() throws {
        let column = try transformedColumn(ModelTestData.ColumnData.columnWithPercentageHeightAboveParent())
        try assertEmbeddedHeightSettles(column, in: 20...100)
    }

    /// Percentage children in a wrapping column must keep their content height.
    func test_embedded_percentageSiblingsAboveParent_settleNearContentHeight() throws {
        let column = try transformedColumn(ModelTestData.ColumnData.columnWithPercentageSiblingsAboveParent())
        try assertEmbeddedHeightSettles(column, in: 40...100)
    }

    func test_embedded_paddedPercentageParent_settlesNearContentHeight() throws {
        let child = try transformedColumn(ModelTestData.ColumnData.columnWithPercentageHeightAboveParent())
        let style = try JSONDecoder().decode(ColumnStyle.self, from: Data(#"{"spacing":{"padding":"10"}}"#.utf8))
        let column = ColumnViewModel(children: child.children,
                                     defaultStyle: [style],
                                     pressedStyle: nil,
                                     hoveredStyle: nil,
                                     disabledStyle: nil,
                                     accessibilityGrouped: false,
                                     layoutState: LayoutState())
        try assertEmbeddedHeightSettles(column, in: 40...100)
    }

    func test_embedded_nestedPercentageSiblings_settleNearContentHeight() throws {
        let child = try transformedColumn(ModelTestData.ColumnData.columnWithPercentageSiblingsAboveParent())
        let column = ColumnViewModel(children: [.column(child)],
                                     defaultStyle: nil,
                                     pressedStyle: nil,
                                     hoveredStyle: nil,
                                     disabledStyle: nil,
                                     accessibilityGrouped: false,
                                     layoutState: LayoutState())
        try assertEmbeddedHeightSettles(column, in: 40...100)
    }

    func test_wrappingRow_preservesPercentageHeightsBesideTallerContent() throws {
        for (percentage, expectedHeight) in [(100, CGFloat(120)), (50, CGFloat(60))] {
            let child = try percentageColumn(percentage)
            let sibling = try styledColumn(#"{"dimension":{"height":{"type":"fixed","value":120}}}"#)
            let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
            let row = try transformer.getRow(nil, children: [.column(child), .column(sibling)])
            XCTAssertEqual(try renderedRedHeight(.row(row)), expectedHeight, accuracy: 1)
        }
    }

    func test_wrappingZStack_preservesPercentageHeightOfTallerContent() throws {
        let child = try percentageColumn(100)
        let sibling = try styledColumn(#"{"dimension":{"height":{"type":"fixed","value":120}}}"#)
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let stack = try transformer.getZStack(nil, children: [.column(sibling), .column(child)])
        XCTAssertEqual(try renderedRedHeight(.zStack(stack)), 120, accuracy: 1)
    }

    func test_forwardingContainers_preservePercentageHeightFromFixedParent() throws {
        let state = LayoutState()
        let child = try percentageColumn(100)
        for (name, wrapper) in forwardingLayouts(.column(child), state: state) {
            let parent = try styledColumn(#"{"dimension":{"height":{"type":"fixed","value":300}}}"#,
                                          children: [wrapper])
            XCTAssertEqual(try renderedRedHeight(.column(parent)), 300, accuracy: 1, name)
        }
    }

    func test_forwardingContainers_keepWrappingColumnsAtContentHeight() throws {
        let state = LayoutState()
        let content = try styledColumn(#"{"dimension":{"height":{"type":"fixed","value":20}}}"#)
        let child = try percentageColumn(100)
        child.children = [.column(content)]
        for (_, wrapper) in forwardingLayouts(.column(child), state: state) {
            let sibling = try styledColumn(#"{"dimension":{"height":{"type":"fixed","value":40}}}"#)
            let parent = try styledColumn("{}", children: [wrapper, .column(sibling)])
            try assertEmbeddedHeightSettles(parent, in: 59...61)
        }
    }

    // MARK: - Helpers

    private func percentageColumn(_ percentage: Int) throws -> ColumnViewModel {
        try styledColumn("""
        {"dimension":{"width":{"type":"fixed","value":20},"height":{"type":"percentage","value":\(percentage)}},
         "background":{"backgroundColor":{"light":"#D92D20"}}}
        """)
    }

    private func styledColumn(_ json: String, children: [LayoutSchemaViewModel] = []) throws -> ColumnViewModel {
        let style = try JSONDecoder().decode(ColumnStyle.self, from: Data(json.utf8))
        return ColumnViewModel(children: children, defaultStyle: [style], pressedStyle: nil,
                               hoveredStyle: nil, disabledStyle: nil, accessibilityGrouped: false,
                               layoutState: LayoutState())
    }

    private func forwardingLayouts(_ child: LayoutSchemaViewModel, state: LayoutState) -> [(String, LayoutSchemaViewModel)] {
        [
            ("one-by-one", .oneByOne(OneByOneViewModel(children: [child], defaultStyle: nil, transition: nil,
                                                       eventService: nil, slots: [], layoutState: state))),
            ("grouped", .groupDistribution(GroupedDistributionViewModel(children: [child],
                                                                        defaultStyle: nil,
                                                                        viewableItems: [1],
                                                                        transition: .fadeInOut(
                                                                            FadeInOutTransitionSettings(duration: 0)
                                                                        ),
                                                                        eventService: nil, slots: [], layoutState: state))),
            ("progress control", .progressControl(ProgressControlViewModel(children: [child], defaultStyle: nil,
                                                                           pressedStyle: nil, hoveredStyle: nil,
                                                                           disabledStyle: nil, direction: .forward,
                                                                           layoutState: state)))
        ]
    }

    private func renderedRedHeight(_ layout: LayoutSchemaViewModel) throws -> CGFloat {
        let host = UIHostingController(rootView: TestPlaceHolder(layout: layout).frame(width: 350, height: 350))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let rendered = expectation(description: "render percentage layout")
        var image: UIImage?
        Snapshotting<UIViewController, UIImage>.wait(for: 1, on: .image(on: snapshotDevice)).snapshot(host).run {
            image = $0
            rendered.fulfill()
        }
        wait(for: [rendered], timeout: 5)
        let screenshot = try XCTUnwrap(image)
        let attachment = XCTAttachment(image: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
        let cgImage = try XCTUnwrap(screenshot.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let redRows = try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: width, height: height,
                                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                                  space: CGColorSpaceCreateDeviceRGB(),
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            let bytes = buffer.bindMemory(to: UInt8.self)
            return (0..<height).filter { y in
                (0..<width).contains { x in
                    let index = (y * width + x) * 4
                    return bytes[index] > 180 && bytes[index + 1] < 80 && bytes[index + 2] < 80
                }
            }.count
        }
        return CGFloat(redRows)/screenshot.scale
    }

    private func heightModifier(
        parent: CGFloat,
        percentage: Float,
        margin: FrameAlignmentProperty? = nil
    ) -> PercentageHeightModifier {
        PercentageHeightModifier(height: parent,
                                 percentage: .percentage(percentage),
                                 verticalAxisAlignment: .top,
                                 margin: margin)
    }

    private func widthModifier(
        parent: CGFloat,
        percentage: Float,
        margin: FrameAlignmentProperty? = nil
    ) -> PercentageWidthModifier {
        PercentageWidthModifier(width: parent,
                                percentage: .percentage(percentage),
                                horizontalAxisAlignment: .leading,
                                margin: margin)
    }

    private func transformedColumn(_ column: ColumnModel<LayoutSchemaModel, WhenPredicate>) throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        return try transformer.getColumn(
            column.styles,
            children: transformer.transformChildren(column.children, context: .outer([]))
        )
    }

    /// Renders `column` as an embedded layout and waits until no new height has been reported for
    /// half a second, then checks that every reported height is finite and that the reports stopped.
    private func assertEmbeddedHeightSettles(
        _ column: ColumnViewModel,
        in range: ClosedRange<CGFloat>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        var heights: [CGFloat] = []
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIHostingController(rootView: EmbeddedComponent(
            layout: .column(column),
            layoutState: LayoutState(),
            eventService: nil,
            onLoad: nil,
            onSizeChange: { heights.append($0) }
        ))
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let deadline = Date().addingTimeInterval(5)
        var reportCount = -1
        while heights.isEmpty || heights.count != reportCount, Date() < deadline {
            reportCount = heights.count
            RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        }

        let lastHeight = try XCTUnwrap(heights.last, "no height was reported", file: file, line: line)
        XCTAssertTrue(heights.allSatisfy(\.isFinite), "reported heights: \(heights)", file: file, line: line)
        XCTAssertTrue(range.contains(lastHeight), "reported heights: \(heights)", file: file, line: line)
        XCTAssertTrue(heights.allSatisfy { $0 <= range.upperBound }, "reported heights: \(heights)", file: file, line: line)
        XCTAssertEqual(heights.count, reportCount, "the height was still changing", file: file, line: line)
    }
}
