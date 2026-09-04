import XCTest
import SwiftUI
import Combine
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class CatalogCarouselStretchLayoutTests: XCTestCase {
    func test_renderedCardsStretchAndShrinkAfterTextAndWidthChanges() throws {
        let state = LayoutState()
        let slots = try CatalogCarouselTestFixture.slots(count: 2)
        let longTitle = String(repeating: "A longer product description ", count: 6)
        var texts: [BasicTextViewModel] = []
        var mountCount = 0
        var reachCount = 0
        let model = try CatalogCarouselCollectionViewModel(
            slots: slots, offerIndex: 1, viewableItems: [2], peekThroughSize: [], layoutState: state,
            callbacks: .init(onMount: { _ in mountCount += 1 }, onReach: { _, _ in reachCount += 1 })
        ) { context in
            let text = BasicTextViewModel(value: context.itemIndex == 0 ? "Short product" : longTitle,
                                          defaultStyle: nil, pressedStyle: nil, hoveredStyle: nil,
                                          disabledStyle: nil, layoutState: state, diagnosticService: nil,
                                          catalogItemContext: context)
            texts.append(text)
            let color = context.itemIndex == 0 ? "#FF0000" : "#0000FF"
            let style = try JSONDecoder().decode(ColumnStyle.self, from: Data("""
            {"dimension":{"width":{"type":"percentage","value":100}},
             "spacing":{"padding":"8"},"background":{"backgroundColor":{"light":"\(color)"}}}
            """.utf8))
            return .column(ColumnViewModel(children: [.basicText(text)], defaultStyle: [style],
                                           pressedStyle: nil, hoveredStyle: nil, disabledStyle: nil,
                                           accessibilityGrouped: false, layoutState: state))
        }
        let screen = GlobalScreenSize()
        screen.width = 320
        screen.height = 1200
        func root(width: CGFloat) -> AnyView {
            AnyView(LayoutSchemaComponent(config: .init(parent: .column, position: 1),
                                          layout: .catalogCarouselCollection(model),
                                          parentWidth: .constant(width), parentHeight: .constant(nil),
                                          styleState: .constant(.default))
                .frame(width: width)
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .background(Color.white)
                .environment(\.colorScheme, .light)
                .environmentObject(screen))
        }
        let host = UIHostingController(rootView: root(width: 320))
        host.overrideUserInterfaceStyle = .light
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 1200))
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let initialHeight = try measure(model, satisfying: { $0 > 0 }) {
            window.rootViewController = host
            window.isHidden = false
            host.view.layoutIfNeeded()
        }
        try assertEqualCardHeights(in: host.view, minimumHeight: initialHeight - 2)

        let expandedHeight = try measure(model, satisfying: { $0 > initialHeight + 20 }) {
            texts[0].updateDataBinding(dataBinding: .value(String(repeating: "Expanded product details ", count: 14)))
        }
        try assertEqualCardHeights(in: host.view, minimumHeight: expandedHeight - 2)

        let restoredHeight = try measure(model, satisfying: { abs($0 - initialHeight) < 2 }) {
            texts[0].updateDataBinding(dataBinding: .value("Short product"))
        }
        XCTAssertLessThan(restoredHeight, expandedHeight)
        try assertEqualCardHeights(in: host.view, minimumHeight: restoredHeight - 2)

        let narrowHeight = try measure(model, satisfying: { $0 > restoredHeight + 10 }) {
            screen.width = 220
            window.frame.size.width = 220
            host.rootView = root(width: 220)
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
        }
        try assertEqualCardHeights(in: host.view, minimumHeight: narrowHeight - 2)

        let wideHeight = try measure(model, satisfying: { $0 > 0 && $0 < narrowHeight - 10 }) {
            screen.width = 500
            window.frame.size.width = 500
            host.rootView = root(width: 500)
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
        }
        try assertEqualCardHeights(in: host.view, minimumHeight: wideHeight - 2)

        let shortenedHeight = try measure(model, satisfying: { $0 > 0 && $0 < wideHeight - 10 }) {
            texts[1].updateDataBinding(dataBinding: .value("Another short product"))
        }
        try assertEqualCardHeights(in: host.view, minimumHeight: shortenedHeight - 2)
        XCTAssertEqual(mountCount, 1)
        XCTAssertEqual(reachCount, 0)
        XCTAssertNil(state.items[LayoutState.activeCatalogItemKey])
        XCTAssertNil(state.items[LayoutState.currentProgressKey])
    }

    private func measure(_ model: CatalogCarouselCollectionViewModel,
                         satisfying predicate: @escaping (CGFloat) -> Bool,
                         action: () -> Void) throws -> CGFloat {
        let measured = expectation(description: "Rendered carousel reaches the expected height")
        var result: CGFloat?
        let subscription = model.$contentHeight.compactMap { $0 }
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .filter(predicate).first().sink {
                result = $0
                measured.fulfill()
            }
        defer { subscription.cancel() }
        action()
        wait(for: [measured], timeout: 5)
        return try XCTUnwrap(result)
    }

    private func assertEqualCardHeights(in view: UIView, minimumHeight: CGFloat,
                                        file: StaticString = #filePath, line: UInt = #line) throws {
        view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { context in
            view.layer.render(in: context.cgContext)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "Card surfaces at width \(view.bounds.width), expected height \(minimumHeight + 2)"
        attachment.lifetime = .keepAlways
        add(attachment)
        let cgImage = try XCTUnwrap(image.cgImage, file: file, line: line)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let bounds = try pixels.withUnsafeMutableBytes { buffer -> [(Int, Int)?] in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: width, height: height,
                                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                                  space: CGColorSpaceCreateDeviceRGB(),
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                                                    CGBitmapInfo.byteOrder32Big.rawValue), file: file, line: line)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            var rows: [(Int, Int)?] = [nil, nil]
            let bytes = buffer.bindMemory(to: UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * 4
                    let red = bytes[offset]
                    let green = bytes[offset + 1]
                    let blue = bytes[offset + 2]
                    let card: Int?
                    if red > 240 && green < 15 && blue < 15 {
                        card = 0
                    } else if blue > 240 && red < 15 && green < 15 {
                        card = 1
                    } else {
                        card = nil
                    }
                    if let card {
                        rows[card] = (min(rows[card]?.0 ?? y, y), max(rows[card]?.1 ?? y, y))
                    }
                }
            }
            return rows
        }
        let first = try XCTUnwrap(bounds[0], "First card surface must render", file: file, line: line)
        let second = try XCTUnwrap(bounds[1], "Second card surface must render", file: file, line: line)
        let firstHeight = CGFloat(first.1 - first.0 + 1)
        let secondHeight = CGFloat(second.1 - second.0 + 1)
        XCTAssertGreaterThanOrEqual(firstHeight, minimumHeight, file: file, line: line)
        XCTAssertEqual(firstHeight, secondHeight, accuracy: 1, file: file, line: line)
        XCTAssertEqual(CGFloat(first.0), CGFloat(second.0), accuracy: 1, file: file, line: line)
    }
}
