import XCTest
import SwiftUI
import DcuiSchema
import ViewInspector
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogCarouselBindingTests: XCTestCase {
    func test_eachCardBindsItsParentCopyItemContentImagesPredicatesAndResponse() throws {
        let slots = try CatalogProductFixture.slots()
        let state = LayoutState()
        state.items[LayoutState.activeCatalogItemKey] = slots[1].offer?.catalogItems?.last
        state.items[LayoutState.currentProgressKey] = Binding.constant(0)
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots), layoutState: state)
        let template = try JSONDecoder().decode(LayoutSchemaModel.self, from: Data(Self.template.utf8))
        let model = try CatalogCarouselCollectionViewModel(slots: slots, offerIndex: 1, viewableItems: [1],
                                                           peekThroughSize: [], layoutState: state) { context in
            try transformer.transform(template, context: .inner(.catalogItem(context)))
        }

        for card in model.cards {
            guard case .column(let column) = card.layout,
                  let children = column.children,
                  case .basicText(let text) = children[0],
                  case .richText(let richText) = children[1],
                  case .dataImage(let image) = children[2],
                  case .when(let when) = children[3],
                  case .row(let row) = when.children?.first,
                  case .catalogResponseButton(let response) = children[4] else {
                return XCTFail("Expected the complete card template")
            }
            let item = card.context.catalogItem
            XCTAssertEqual(text.boundValue, "Product offer: \(item.title)")
            XCTAssertEqual(richText.boundValue, "Product offer / \(item.title)")
            XCTAssertEqual(image.image?.light, item.images["catalogItemImage0"]?.light)
            XCTAssertEqual(text.catalogItemContext?.itemIndex, card.context.itemIndex)
            XCTAssertEqual(richText.catalogItemContext?.itemIndex, card.context.itemIndex)
            XCTAssertEqual(image.catalogItemContext?.itemIndex, card.context.itemIndex)
            XCTAssertEqual(when.catalogItemContext?.itemIndex, card.context.itemIndex)
            XCTAssertEqual(row.catalogItemContext?.itemIndex, card.context.itemIndex)
            XCTAssertEqual(response.catalogItemContext?.catalogItem.token, item.token)
            XCTAssertEqual(response.catalogItemContext?.moduleName, "standard-marketing")
            XCTAssertEqual(response.responseKey, "buy-now")
            XCTAssertEqual(response.isRenderable, card.context.itemIndex == 0)
            XCTAssertEqual(text.currentIndex.wrappedValue, 1)
            XCTAssertEqual(richText.currentIndex.wrappedValue, 1)
            XCTAssertEqual(text.totalOffer, 2)
            state.items[LayoutState.currentProgressKey] = Binding.constant(9)
            XCTAssertEqual(text.currentIndex.wrappedValue, 1)
            XCTAssertEqual(richText.currentIndex.wrappedValue, 1)
        }
    }

    func test_boundProductButtonUsesOnlyItsCallbackAndNeverPurchasesOrCloses() throws {
        let slots = try CatalogProductFixture.slots()
        let card = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let state = LayoutState()
        let events = MockEventService()
        var didClose = false
        state.actionCollection[.close] = { _ in didClose = true }
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots),
                                            layoutState: state, eventService: events)
        let button = try transformer.getCatalogResponseButtonModel(style: nil, children: [],
                                                                   context: .inner(.catalogItem(card)), responseKey: "buy-now")
        button.cartItemInstantPurchase(position: 1)
        var responses: [String] = []
        button.productResponse = { context, key in
            responses.append(context.responseOption(for: key)?.responseJWTToken ?? "")
        }
        button.cartItemInstantPurchase(position: 1)
        XCTAssertEqual(responses, ["example-response-token-a"])
        XCTAssertFalse(events.cartItemInstantPurchaseCalled)
        XCTAssertFalse(events.cartItemForwardPaymentCalled)
        XCTAssertFalse(events.dismissalEventCalled)
        XCTAssertFalse(didClose)
    }

    func test_missingResponseAndMissingImagesNeverUseAnotherCard() throws {
        let slots = try CatalogCarouselTestFixture.slots(count: 1)
        let card = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let state = LayoutState()
        state.items[LayoutState.activeCatalogItemKey] = try CatalogProductFixture.slots()[1].offer?.catalogItems?.first
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots), layoutState: state)
        let button = try transformer.getCatalogResponseButtonModel(style: nil, children: [],
                                                                   context: .inner(.catalogItem(card)))
        var responseInvoked = false
        button.productResponse = { _, _ in responseInvoked = true }
        button.cartItemInstantPurchase(position: 1)
        XCTAssertFalse(button.isRenderable)
        XCTAssertFalse(responseInvoked)
        let component = CatalogResponseButtonComponent(config: ComponentConfig(parent: .column, position: 1),
                                                       model: button, parentWidth: .constant(300),
                                                       parentHeight: .constant(nil), parentOverride: nil)
        XCTAssertThrowsError(try component.inspect().find(ViewType.HStack.self))
        let imageSchema = try JSONDecoder().decode(DataImageModel<WhenPredicate>.self,
                                                   from: Data(#"{"imageKey":"catalogItemImage0"}"#.utf8))
        let image = try transformer.getDataImage(imageSchema, context: .inner(.catalogItem(card)))
        XCTAssertNil(image.image)
    }

    func test_disabledProductCardDoesNotRespondPurchaseOrDismiss() throws {
        let slots = try CatalogProductFixture.slots()
        let card = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let state = LayoutState()
        let events = MockEventService()
        var closed = false
        state.actionCollection[.close] = { _ in closed = true }
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots),
                                            layoutState: state, eventService: events)
        let button = try transformer.getCatalogResponseButtonModel(style: nil, children: [],
                                                                   context: .inner(.catalogItem(card)), responseKey: "buy-now")
        var responseCount = 0
        button.productResponse = { _, _ in responseCount += 1 }
        button.cartItemInstantPurchase(position: 1, isEnabled: false)
        XCTAssertEqual(responseCount, 0)
        XCTAssertFalse(events.cartItemInstantPurchaseCalled)
        XCTAssertFalse(events.cartItemForwardPaymentCalled)
        XCTAssertFalse(events.dismissalEventCalled)
        XCTAssertFalse(closed)
        button.cartItemInstantPurchase(position: 1, isEnabled: true)
        button.cartItemInstantPurchase(position: 1, isEnabled: false)
        XCTAssertEqual(responseCount, 1)
    }

    private static let template = #"""
    {"type":"Column","node":{"children":[
      {"type":"BasicText","node":{"value":"%^DATA.creativeCopy.title^%: %^DATA.catalogItem.title^%"}},
      {"type":"RichText","node":{"value":"%^DATA.creativeCopy.title^% / %^DATA.catalogItem.title^%"}},
      {"type":"DataImage","node":{"imageKey":"catalogItemImage0"}},
      {"type":"When","node":{"predicates":[],"children":[{"type":"Row","node":{"children":[]}}]}},
      {"type":"CatalogResponseButton","node":{"responseKey":"buy-now","children":[]}}
    ]}}
    """#
}
