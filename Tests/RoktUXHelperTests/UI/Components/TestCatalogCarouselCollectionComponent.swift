import XCTest
import SwiftUI
import Combine
import DcuiSchema
import SnapshotTesting
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class TestCatalogCarouselCollectionComponent: XCTestCase {
    /// An empty catalog does not reserve carousel space.
    func testSnapshot_zeroProducts() throws {
        try snapshot(itemCount: 0, width: 350)
    }

    /// A single card fills the available carousel width.
    func testSnapshot_oneProduct() throws {
        try snapshot(itemCount: 1, width: 350)
    }

    /// Multiple cards retain the configured group width, gap, and peek.
    func testSnapshot_manyProducts() throws {
        try snapshot(itemCount: 5, width: 350, viewableItems: 2)
    }

    /// Product text wraps within a narrow host.
    func testSnapshot_smallWidth() throws {
        try snapshot(itemCount: 4, width: 230)
    }

    /// The typed layout renders collapsed offer copy, synchronous product images, selectors, and response buttons together.
    func testSnapshot_productLayoutWithCollapsedDescription() throws {
        try snapshotProductLayout()
    }

    /// Activating the native inline action expands the description and moves the carousel below the new text height.
    func testSnapshot_productLayoutAfterExpandingDescription() throws {
        try snapshotProductLayout(expandDescription: true)
    }

    /// The actual scroll host renders the last product's image, labels, and response button.
    func testSnapshot_productLayoutScrolledToLastCard() throws {
        try snapshotProductLayout(scrollToLastCard: true)
    }

    /// Accessible text and right-to-left layout preserve description wrapping and the first logical product.
    func testSnapshot_productLayoutWithAccessibleTextRightToLeft() throws {
        try snapshotProductLayout(contentSize: .accessibilityLarge, direction: .rightToLeft)
    }

    private func snapshot(itemCount: Int, width: CGFloat, viewableItems: UInt8 = 1,
                          file: StaticString = #filePath, testName: String = #function, line: UInt = #line) throws {
        let items: [[String: Any]] = (0..<itemCount).map { index in
            ["catalog_item_id": "example-item-\(index)",
             "title": index == 1 ? "Example product with a longer title" : "Example product \(index + 1)",
             "price_formatted": "$\(12 + index * 3).00",
             "response_options_map": ["positive": [
                 "id": "example-response-\(index)", "is_positive": true, "action": "Url",
                 "url": "https://example.com/product-\(index)"
             ]]]
        }
        let offer = try CatalogProductFixture.offer(["creative": [:], "catalog_items": items])
        let slots = [SlotModel(instanceGuid: "example-slot", offer: offer,
                               layoutVariant: LayoutVariantModel(layoutVariantSchema: nil, moduleName: "standard-marketing"),
                               jwtToken: "")]
        let state = LayoutState()
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots), layoutState: state)
        let template = try JSONDecoder().decode(LayoutSchemaModel.self, from: Data(Self.cardTemplate.utf8))
        let style = try JSONDecoder().decode(BaseStyles.self, from: Data(#"{"container":{"gap":12}}"#.utf8))
        let model = try CatalogCarouselCollectionViewModel(slots: slots, offerIndex: 0, viewableItems: [viewableItems],
                                                           peekThroughSize: [.fixed(16)], defaultStyle: [style],
                                                           layoutState: state) { context in
            try transformer.transform(template, context: .inner(.catalogItem(context)))
        }
        let screen = GlobalScreenSize()
        screen.width = width
        screen.height = 844
        let root = VStack(alignment: .leading, spacing: 16) {
            Text("Products").font(.title2.bold())
            LayoutSchemaComponent(config: ComponentConfig(parent: .column, position: 0),
                                  layout: .catalogCarouselCollection(model),
                                  parentWidth: .constant(width - 32), parentHeight: .constant(nil),
                                  styleState: .constant(.default))
        }
        .padding(16)
        .frame(width: width, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .environmentObject(screen)
        .environment(\.colorScheme, .light)

        let measured = expectation(description: "Rendered cards have a stable height")
        let measurement = model.$contentHeight.compactMap { $0 }.filter { $0 > 0 }
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main).first().sink { _ in measured.fulfill() }
        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 844))
        window.rootViewController = host
        window.isHidden = false
        defer {
            measurement.cancel()
            window.isHidden = true
            window.rootViewController = nil
        }
        host.view.layoutIfNeeded()
        if itemCount == 0 { measured.fulfill() }
        wait(for: [measured], timeout: 5)
        assertCarouselSnapshot(host, file: file, testName: testName, line: line)
    }

    private func snapshotProductLayout(expandDescription: Bool = false, scrollToLastCard: Bool = false,
                                       contentSize: ContentSizeCategory = .large,
                                       direction: LayoutDirection = .leftToRight,
                                       file: StaticString = #filePath, testName: String = #function,
                                       line: UInt = #line) throws {
        let width: CGFloat = 350
        let copy = direction == .rightToLeft
            ? "تصفح مجموعة من المنتجات المختارة واكتشف التفاصيل الكاملة قبل اختيار المنتج المناسب لك. تتوفر خيارات متعددة مع صور وأسعار واضحة للمقارنة."
            : "Explore a selection of everyday essentials, with clear product details and prices to help you choose. Read the full description before viewing a product."
        let slots = try productSlots(copy: copy, direction: direction)
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
        let layout = try transformer.transform(ProductCarouselIntegrationFixture.distributions[0],
                                               context: .outer(slots.map(\.offer)))
        guard case .oneByOne(let distribution) = layout,
              case .column(let column) = distribution.children?.first,
              case .catalogCarouselCollection(let carousel) = column.children?[3] else {
            return XCTFail("Expected the typed product layout inside its distribution", file: file, line: line)
        }
        for card in carousel.cards {
            guard case .column(let product) = card.layout,
                  case .catalogResponseButton(let response) = product.children?[3] else {
                return XCTFail("Expected a product response button", file: file, line: line)
            }
            XCTAssertTrue(response.isRenderable, file: file, line: line)
        }
        let screen = GlobalScreenSize()
        screen.width = width
        screen.height = 844
        let root = LayoutSchemaComponent(config: .init(parent: .column, position: nil), layout: layout,
                                         parentWidth: .constant(width - 32), parentHeight: .constant(nil),
                                         styleState: .constant(.default))
            .padding(16)
            .frame(width: width, alignment: .topLeading)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
            .environmentObject(screen)
            .environment(\.colorScheme, .light)
            .environment(\.sizeCategory, contentSize)
            .environment(\.layoutDirection, direction)
        let measured = expectation(description: "Typed product cards have a stable height")
        let measurement = carousel.$contentHeight.compactMap { $0 }.filter { $0 > 120 }
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main).first().sink { _ in measured.fulfill() }
        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 844))
        window.rootViewController = host
        window.isHidden = false
        defer {
            measurement.cancel()
            window.isHidden = true
            window.rootViewController = nil
        }
        host.view.layoutIfNeeded()
        wait(for: [measured], timeout: 5)
        waitForInline(in: window) { $0.text.contains("See More") }
        let inline = try XCTUnwrap(firstView(InlineTextView.self, in: window), file: file, line: line)
        if expandDescription {
            let collapsedHeight = inline.bounds.height
            let action = try XCTUnwrap(inline.runs.first { $0.action != nil }, file: file, line: line)
            XCTAssertTrue(inline.activateRun(id: action.id), file: file, line: line)
            waitForInline(in: window) { $0.text.contains("See Less") && $0.bounds.height > collapsedHeight }
        }
        if scrollToLastCard {
            let scroll = try XCTUnwrap(firstView(CatalogCarouselScrollView.self, in: window), file: file, line: line)
            let breakpoint = carousel.layoutState?.getGlobalBreakpointIndex(width) ?? 0
            let geometry = carousel.geometry(viewportWidth: scroll.bounds.width, breakpointIndex: breakpoint,
                                             style: carousel.style(width: width, position: 0, colorScheme: .light))
            XCTAssertGreaterThan(geometry.maximumOffset, 0, file: file, line: line)
            XCTAssertEqual(scroll.contentSize.width - scroll.bounds.width, geometry.maximumOffset,
                           accuracy: 0.5, file: file, line: line)
            let lastOffset = direction == .rightToLeft ? 0 : geometry.maximumOffset
            scroll.delegate?.scrollViewWillBeginDragging?(scroll)
            scroll.setContentOffset(CGPoint(x: lastOffset, y: 0), animated: false)
            scroll.delegate?.scrollViewDidEndDragging?(scroll, willDecelerate: false)
            window.layoutIfNeeded()
            XCTAssertEqual(scroll.contentOffset.x, lastOffset, accuracy: 0.5, file: file, line: line)
            let logicalOffset = direction == .rightToLeft
                ? geometry.maximumOffset - scroll.contentOffset.x : scroll.contentOffset.x
            XCTAssertTrue(geometry.visibleIndexes(at: logicalOffset, threshold: 0.99).contains(carousel.cards.count - 1),
                          file: file, line: line)
            XCTAssertEqual(carousel.currentItemIndex, geometry.leadingIndex(at: logicalOffset), file: file, line: line)
        }
        assertCarouselSnapshot(host, file: file, testName: testName, line: line)
    }

    private func productSlots(copy: String, direction: LayoutDirection) throws -> [SlotModel] {
        let titles = direction == .rightToLeft
            ? ["حقيبة يومية", "زجاجة قابلة لإعادة الاستخدام", "دفتر ملاحظات"]
            : ["Everyday bag", "Reusable bottle with an easy-carry handle", "Pocket notebook"]
        let items: [[String: Any]] = try titles.enumerated().map { index, title in
            let image = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80)).image { context in
                [UIColor.blue, .green, .orange][index].setFill()
                context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
            }
            let imageURI = "data:image/png;base64," + (try XCTUnwrap(image.pngData())).base64EncodedString()
            return ["catalog_item_id": "example-item-\(index)", "title": title,
                    "price_formatted": "$\(12 + index * 6).00",
                    "product_cart_attribute1": "title", "product_cart_attribute2": "price",
                    "images": ["catalogItemImage0": ["light": imageURI, "alt": title]],
                    "token": "example-item-token-\(index)",
                    "response_options_map": ["positive": [
                        "id": "example-response-\(index)", "is_positive": true, "action": "Url",
                        "signal_type": "SignalProductItemResponse", "token": "example-response-token-\(index)",
                        "url": "https://example.com/product-\(index)"
                    ]]]
        }
        let offer = try CatalogProductFixture.offer([
            "creative": ["copy": ["creative.copy": copy]], "catalog_items": items
        ])
        return [SlotModel(instanceGuid: "example-product-slot", offer: offer,
                          layoutVariant: LayoutVariantModel(layoutVariantSchema: try ProductCarouselIntegrationFixture.layout(),
                                                            moduleName: "standard-marketing"), jwtToken: "")]
    }

    private func waitForInline(in window: UIWindow, matching condition: @escaping (InlineTextView) -> Bool) {
        let ready = expectation(for: NSPredicate { _, _ in
            window.layoutIfNeeded()
            guard let inline = self.firstView(InlineTextView.self, in: window),
                  inline.bounds.width > 0, inline.bounds.height > 0 else { return false }
            return abs(inline.bounds.height - inline.measuredHeight(for: inline.bounds.width)) < 0.5 && condition(inline)
        }, evaluatedWith: nil)
        wait(for: [ready], timeout: 5)
    }

    private func firstView<T: UIView>(_ type: T.Type, in view: UIView) -> T? {
        if let match = view as? T, !match.isHidden { return match }
        return view.subviews.lazy.compactMap { self.firstView(type, in: $0) }.first
    }

    private func assertCarouselSnapshot(_ host: UIViewController, file: StaticString,
                                        testName: String, line: UInt) {
        var strategy = Snapshotting<UIViewController, UIImage>.image(
            on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision
        )
        let render = strategy.snapshot
        strategy.snapshot = { controller in
            .init { callback in
                render(controller).run { image in
                    do {
                        try self.exportSnapshot(image, testName: testName, file: file)
                    } catch {
                        XCTFail("Could not export snapshot: \(error)", file: file, line: line)
                    }
                    callback(image)
                }
            }
        }
        assertSnapshot(of: host, as: strategy, named: "carousel", file: file, testName: testName, line: line)
    }

    private func exportSnapshot(_ image: UIImage, testName: String, file: StaticString) throws {
        // Missing references stay beside the tests; also expose the first rendering to CI's existing artifact upload.
        guard let path = ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] else { return }
        let suite = URL(fileURLWithPath: "\(file)").deletingPathExtension().lastPathComponent
        let directory = URL(fileURLWithPath: path).appendingPathComponent(suite)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = testName.replacingOccurrences(of: "()", with: "")
        try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent("\(name).carousel.png"))
    }

    private static let cardTemplate = #"""
    {"type":"Column","node":{
      "styles":{"elements":{"own":[{"default":{
        "background":{"backgroundColor":{"light":"#F4F6F9"}},
        "border":{"borderRadius":12},"spacing":{"padding":"16"},"container":{"gap":12},
        "dimension":{"width":{"type":"fit","value":"fit-width"}}
      }}]}},
      "children":[
        {"type":"BasicText","node":{"value":"%^DATA.catalogItem.title^%",
          "styles":{"elements":{"own":[{"default":{"text":{
            "fontSize":18,"fontWeight":"600","textColor":{"light":"#1A1D24"}
          }}}]}}}},
        {"type":"BasicText","node":{"value":"%^DATA.catalogItem.priceFormatted^%",
          "styles":{"elements":{"own":[{"default":{"text":{
            "fontSize":16,"textColor":{"light":"#1A1D24"}
          }}}]}}}},
        {"type":"CatalogResponseButton","node":{"responseKey":"positive",
          "styles":{"elements":{"own":[{"default":{
            "background":{"backgroundColor":{"light":"#1438C6"}},"border":{"borderRadius":6},
            "spacing":{"padding":"10 12"},"container":{"justifyContent":"center"}
          }}]}},
          "children":[{"type":"BasicText","node":{"value":"View item",
            "styles":{"elements":{"own":[{"default":{"text":{
              "fontSize":14,"fontWeight":"600","textColor":{"light":"#FFFFFF"}
            }}}]}}
          }}]
        }}
      ]
    }}
    """#
}
