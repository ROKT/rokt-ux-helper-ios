import XCTest
import SwiftUI
import Combine
import DcuiSchema
import SnapshotTesting
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class CatalogCarouselSnapshotTests: XCTestCase {
    func test_snapshot_zeroProducts() throws {
        try snapshot(itemCount: 0, width: 350)
    }

    func test_snapshot_oneProduct() throws {
        try snapshot(itemCount: 1, width: 350)
    }

    func test_snapshot_manyProducts() throws {
        try snapshot(itemCount: 5, width: 350, viewableItems: 2)
    }

    func test_snapshot_smallWidth() throws {
        try snapshot(itemCount: 4, width: 230)
    }

    private func snapshot(itemCount: Int, width: CGFloat, viewableItems: UInt8 = 1,
                          file: StaticString = #filePath, testName: String = #function) throws {
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
        assertSnapshot(of: host,
                       as: .image(on: snapshotDevice, precision: snapshotPrecision,
                                  perceptualPrecision: snapshotPerceptualPrecision),
                       file: file, testName: testName)
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
