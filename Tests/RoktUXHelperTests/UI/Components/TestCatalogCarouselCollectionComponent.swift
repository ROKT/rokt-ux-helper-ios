import XCTest
import SwiftUI
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

    /// Product cards with different intrinsic title heights fill one shared row height.
    func testSnapshot_mixedIntrinsicCardHeights() throws {
        try snapshot(itemCount: 2, width: 350, viewableItems: 2)
    }

    /// The typed layout renders collapsed offer copy, synchronous product images, selectors, and response buttons together.
    func testSnapshot_productLayoutWithCollapsedDescription() throws {
        try snapshotProductLayout()
    }

    /// Dark-mode offer copy, product labels, and response labels retain their authored contrast.
    func testSnapshot_productLayoutInDarkMode() throws {
        try snapshotProductLayout(colorScheme: .dark)
    }

    /// A product without a response keeps its image and labels, but does not render a response button.
    func testSnapshot_productLayoutWithMissingResponse() throws {
        try snapshotProductLayout(missingFirstResponse: true)
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
                 "instance_guid": "example-response-instance-\(index)",
                 "signal_type": "SignalProductItemResponse", "token": "example-response-token-\(index)",
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
        for card in model.cards {
            XCTAssertNotNil(CatalogProductResponse(context: card.context), file: file, line: line)
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

        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 844))
        window.rootViewController = host
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        host.view.layoutIfNeeded()
        waitForCarousel(model, in: window)
        assertCarouselSnapshot(host, file: file, testName: testName, line: line)
    }

    private func snapshotProductLayout(expandDescription: Bool = false, scrollToLastCard: Bool = false,
                                       contentSize: ContentSizeCategory = .large,
                                       direction: LayoutDirection = .leftToRight,
                                       colorScheme: ColorScheme = .light, missingFirstResponse: Bool = false,
                                       file: StaticString = #filePath, testName: String = #function,
                                       line: UInt = #line) throws {
        let width: CGFloat = 350
        let copy = direction == .rightToLeft
            ? "تصفح مجموعة من المنتجات المختارة واكتشف التفاصيل الكاملة قبل اختيار المنتج المناسب لك. تتوفر خيارات متعددة مع صور وأسعار واضحة للمقارنة."
            : "Explore a selection of everyday essentials, with clear product details and prices to help you choose. Read the full description before viewing a product."
        let slots = try productSlots(copy: copy, direction: direction, missingFirstResponse: missingFirstResponse)
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
        let layout = try transformer.transform(ProductCarouselIntegrationFixture.distributions[0],
                                               context: .outer(slots.map(\.offer)))
        guard case .oneByOne(let distribution) = layout,
              case .column(let column) = distribution.children?.first,
              case .catalogCarouselCollection(let carousel) = column.children?[3] else {
            return XCTFail("Expected the typed product layout inside its distribution", file: file, line: line)
        }
        for (index, card) in carousel.cards.enumerated() {
            guard case .column(let product) = card.layout,
                  case .catalogResponseButton(let response) = product.children?[3] else {
                return XCTFail("Expected a product response button", file: file, line: line)
            }
            XCTAssertEqual(response.isRenderable, !missingFirstResponse || index != 0, file: file, line: line)
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
            .background(colorScheme == .dark ? Color.black : Color.white)
            .environmentObject(screen)
            .environment(\.colorScheme, colorScheme)
            .environment(\.sizeCategory, contentSize)
            .environment(\.layoutDirection, direction)
        let host = UIHostingController(rootView: root)
        host.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 844))
        window.rootViewController = host
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        host.view.layoutIfNeeded()
        waitForCarousel(carousel, in: window)
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
                                             style: carousel.style(width: width, position: 0, colorScheme: colorScheme))
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
        waitForCarousel(carousel, in: window)
        assertCarouselSnapshot(host, file: file, testName: testName, line: line)
    }

    private func waitForCarousel(_ carousel: CatalogCarouselCollectionViewModel, in window: UIWindow) {
        guard !carousel.cards.isEmpty else { return }
        var previousHeights: [Int: CGFloat]?
        let ready = expectation(for: NSPredicate { _, _ in
            window.layoutIfNeeded()
            let heights = carousel.itemHeights
            defer { previousHeights = heights }
            guard heights.count == carousel.cards.count, heights == previousHeights,
                  let maximumHeight = heights.values.max(), let contentHeight = carousel.contentHeight,
                  abs(contentHeight - maximumHeight) < 0.5,
                  let scroll = self.firstView(CatalogCarouselScrollView.self, in: window) else { return false }
            return scroll.bounds.width > 0 && abs(scroll.bounds.height - max(1, contentHeight)) < 0.5
        }, evaluatedWith: nil)
        wait(for: [ready], timeout: 5)
    }

    private func productSlots(copy: String, direction: LayoutDirection, missingFirstResponse: Bool) throws -> [SlotModel] {
        let titles = direction == .rightToLeft
            ? ["حقيبة يومية", "زجاجة قابلة لإعادة الاستخدام", "دفتر ملاحظات"]
            : ["Everyday bag", "Reusable bottle with an easy-carry handle", "Pocket notebook"]
        let items: [[String: Any]] = try titles.enumerated().map { index, title in
            let image = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80)).image { context in
                [UIColor.blue, .green, .orange][index].setFill()
                context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
            }
            let imageURI = "data:image/png;base64," + (try XCTUnwrap(image.pngData())).base64EncodedString()
            var item: [String: Any] = ["catalog_item_id": "example-item-\(index)", "title": title,
                                       "price_formatted": "$\(12 + index * 6).00",
                                       "product_cart_attribute1": "title", "product_cart_attribute2": "price",
                                       "images": ["catalogItemImage0": ["light": imageURI, "dark": imageURI, "alt": title]],
                                       "token": "example-item-token-\(index)",
                                       "response_options_map": ["positive": [
                                           "id": "example-response-\(index)", "is_positive": true, "action": "Url",
                                           "instance_guid": "example-response-instance-\(index)",
                                           "signal_type": "SignalProductItemResponse", "token": "example-response-token-\(index)",
                                           "url": "https://example.com/product-\(index)"
                                       ]]]
            if missingFirstResponse && index == 0 { item.removeValue(forKey: "response_options_map") }
            return item
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
        assertSnapshot(of: host, as: strategy, file: file, testName: testName, line: line)
    }

    private func exportSnapshot(_ image: UIImage, testName: String, file: StaticString) throws {
        // Missing references stay beside the tests; also expose the first rendering to CI's existing artifact upload.
        guard let path = ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] else { return }
        let suite = URL(fileURLWithPath: "\(file)").deletingPathExtension().lastPathComponent
        let directory = URL(fileURLWithPath: path).appendingPathComponent(suite)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = testName.replacingOccurrences(of: "()", with: "")
        try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent("\(name).1.png"))
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
