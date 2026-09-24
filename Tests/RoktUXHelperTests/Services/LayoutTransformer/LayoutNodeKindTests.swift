import XCTest
@testable import RoktUXHelper
import DcuiSchema

/// `transform` no longer switches on the layout node itself. It reads `nodeKind` and dispatches to
/// a builder that re-matches the node, so the node kind is now named in three places that have to
/// agree: the `nodeKind` mapping, the dispatch arm, and the builder's own `guard case`.
///
/// A disagreement does not fail to compile — it routes a node to the wrong builder, whose `guard`
/// then throws `InvalidMapping`, and the layout fails to render. These tests pin the routing.
@available(iOS 15, *)
final class LayoutNodeKindTests: XCTestCase {

    /// Every case of the schema enum, with the `type` discriminator that decodes to it.
    ///
    /// Listed by hand so that a node kind added to the schema shows up as a missing entry here
    /// rather than as an untested dispatch arm. The count assertion below is what enforces that.
    private static let allNodeKinds: [(type: String, kind: LayoutNodeKind)] = [
        ("Row", .row),
        ("Column", .column),
        ("ScrollableColumn", .scrollableColumn),
        ("ScrollableRow", .scrollableRow),
        ("ZStack", .zStack),
        ("AccessibilityGrouped", .accessibilityGrouped),
        ("StaticImage", .staticImage),
        ("DataImage", .dataImage),
        ("DataImageCarousel", .dataImageCarousel),
        ("RichText", .richText),
        ("BasicText", .basicText),
        ("ProgressIndicator", .progressIndicator),
        ("CreativeResponse", .creativeResponse),
        ("OneByOneDistribution", .oneByOneDistribution),
        ("Overlay", .overlay),
        ("BottomSheet", .bottomSheet),
        ("When", .when),
        ("StaticLink", .staticLink),
        ("CloseButton", .closeButton),
        ("CarouselDistribution", .carouselDistribution),
        ("ProgressControl", .progressControl),
        ("GroupedDistribution", .groupedDistribution),
        ("ToggleButtonStateTrigger", .toggleButtonStateTrigger),
        ("CatalogStackedCollection", .catalogStackedCollection),
        ("CatalogCombinedCollection", .catalogCombinedCollection),
        ("CatalogResponseButton", .catalogResponseButton),
        ("CatalogDevicePayButton", .catalogDevicePayButton),
        ("CatalogDropdown", .catalogDropdown),
        ("CatalogImageGallery", .catalogImageGallery),
        ("InlineContainer", .inlineContainer),
        ("CatalogCarouselCollection", .catalogCarouselCollection)
    ]

    /// The smallest `node` object each type decodes from — only the fields the schema makes
    /// non-optional. These exist to get a value of every case in hand, not to describe a layout
    /// anyone would author, so nothing here should be read as a realistic node.
    private func minimalNode(for type: String) -> [String: Any] {
        let emptyRow: [String: Any] = ["type": "Row", "node": ["children": []]]
        let fadeInOut: [String: Any] = ["type": "FadeInOut", "settings": ["duration": 1]]

        switch type {
        case "AccessibilityGrouped":
            return ["child": emptyRow]
        case "StaticImage":
            return ["url": ["light": "https://example.invalid/image.png"]]
        case "DataImage":
            return ["imageKey": "imageKey"]
        case "DataImageCarousel":
            return ["imageKey": "imageKey", "duration": 1]
        case "RichText", "BasicText":
            return ["value": "Example"]
        case "ProgressIndicator":
            return ["indicator": "1"]
        case "CreativeResponse":
            return ["responseKey": "POSITIVE", "children": []]
        case "OneByOneDistribution":
            return ["transition": fadeInOut]
        case "GroupedDistribution":
            return ["viewableItems": [1], "transition": fadeInOut]
        case "CarouselDistribution":
            return ["viewableItems": [1], "peekThroughSize": [["type": "Fixed", "value": 0]]]
        case "Overlay", "BottomSheet":
            return ["allowBackdropToClose": true, "children": []]
        case "When":
            return ["predicates": [], "children": []]
        case "StaticLink":
            return ["src": "https://example.invalid", "open": "internally", "children": []]
        case "ProgressControl":
            return ["direction": "Forward", "children": []]
        case "ToggleButtonStateTrigger":
            return ["customStateKey": "key", "children": []]
        case "CatalogDevicePayButton":
            return ["provider": "ApplePay", "children": []]
        case "CatalogStackedCollection", "CatalogCombinedCollection":
            return ["template": emptyRow]
        case "CatalogCarouselCollection":
            return [
                "viewableItems": [1],
                "peekThroughSize": [["type": "fixed", "value": 0]],
                "template": emptyRow
            ]
        case "CatalogDropdown", "CatalogImageGallery":
            return [:]
        default:
            // Row, Column, ScrollableRow, ScrollableColumn, ZStack, CloseButton,
            // CatalogResponseButton and InlineContainer need only their children.
            return ["children": []]
        }
    }

    private func decode(type: String) throws -> LayoutSchemaModel {
        let json: [String: Any] = ["type": type, "node": minimalNode(for: type)]
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(LayoutSchemaModel.self, from: data)
    }

    func test_every_schema_node_kind_is_listed() {
        XCTAssertEqual(
            Self.allNodeKinds.count,
            31,
            "A node kind was added to or removed from the schema. Add it here, to LayoutNodeKind, "
                + "to the dispatch in transform(_:context:) and to a builder in LayoutTransformer+Nodes."
        )
    }

    func test_nodeKind_matches_the_decoded_node() throws {
        for (type, expected) in Self.allNodeKinds {
            let model = try decode(type: type)
            XCTAssertEqual(model.nodeKind, expected, "\(type) reported the wrong node kind")
        }
    }

    /// Routing, rather than rendering: a node sent to the wrong builder trips that builder's
    /// `guard case` and throws `InvalidMapping` from a `transform…` frame.
    ///
    /// The `get…` functions throw the same error for their own reasons — most of these minimal
    /// nodes have no offer to bind against — so the test reads the `#function` the error carries
    /// and only fails when the rejection came from a builder. Everything else means the node
    /// reached its own builder, which is all this is checking.
    func test_no_node_kind_is_dispatched_to_the_wrong_builder() throws {
        for (type, _) in Self.allNodeKinds {
            let model = try decode(type: type)
            let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(layout: model))
            do {
                _ = try transformer.transform(model, context: .outer([]))
            } catch LayoutTransformerError.InvalidMapping(let line, let function)
                        where function.hasPrefix("transform") {
                XCTFail("\(type) was dispatched to \(function):\(line), which rejected it")
            } catch {
                // Any other failure is the deliberately minimal node, not the routing.
            }
        }
    }
}
