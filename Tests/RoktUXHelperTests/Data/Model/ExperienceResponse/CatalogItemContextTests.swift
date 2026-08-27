import XCTest
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogItemContextTests: XCTestCase {
    func test_contextUsesTheSelectedSlotAndKeepsBothItemIdentities() throws {
        let slots = try CatalogProductFixture.slots()
        let first = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let second = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 1))

        XCTAssertEqual(first.offerIndex, 1)
        XCTAssertEqual(first.itemIndex, 0)
        XCTAssertEqual(second.itemIndex, 1)
        XCTAssertEqual(first.slot.instanceGuid, "example-product-slot")
        XCTAssertEqual(first.slot.jwtToken, "example-slot-token")
        XCTAssertEqual(first.moduleName, "standard-marketing")
        XCTAssertEqual(first.offer.accountId, "example-product-account")
        XCTAssertEqual(first.offer.creative.instanceGuid, "creative:example/parent")
        XCTAssertEqual(first.catalogItem.catalogItemId, "item:example/product-a")
        XCTAssertEqual(second.catalogItem.catalogItemId, "item:example/product-b")
        XCTAssertEqual(first.responseOption(for: "buy-now")?.responseJWTToken, "example-response-token-a")
        XCTAssertEqual(second.responseOption()?.responseJWTToken, "example-response-token-b")
        XCTAssertEqual(second.responseOption(for: "")?.id, "example-response-b")
        XCTAssertNil(first.responseOption())
        XCTAssertNil(first.responseOption(for: "missing"))
        XCTAssertNil(second.responseOption(for: "buy-now"))
    }

    func test_contextRejectsMissingSlotsOffersAndItems() throws {
        let slots = try CatalogProductFixture.slots()
        XCTAssertNil(CatalogItemContext(slots: [], offerIndex: 0, itemIndex: 0))
        XCTAssertNil(CatalogItemContext(slots: slots, offerIndex: -1, itemIndex: 0))
        XCTAssertNil(CatalogItemContext(slots: slots, offerIndex: slots.count, itemIndex: 0))
        XCTAssertNil(CatalogItemContext(slots: slots, offerIndex: 0, itemIndex: 0))
        XCTAssertNil(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: -1))
        XCTAssertNil(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 2))

        let emptySlot = SlotModel(instanceGuid: nil, offer: nil, layoutVariant: nil, jwtToken: "")
        XCTAssertNil(CatalogItemContext(slots: [emptySlot], offerIndex: 0, itemIndex: 0))
        let emptyOffer = try CatalogProductFixture.offer(["creative": [:], "catalog_items": []])
        let emptyItems = SlotModel(instanceGuid: nil, offer: emptyOffer, layoutVariant: nil, jwtToken: "")
        XCTAssertNil(CatalogItemContext(slots: [emptyItems], offerIndex: 0, itemIndex: 0))
    }

    func test_textImagesAndPredicatesResolveAgainstTheSameCard() throws {
        let slots = try CatalogProductFixture.slots()
        let resolver = PlaceholderPredicateResolver()
        let extractor = CatalogDataExtractor()

        for index in 0..<2 {
            let card = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: index))
            let context = PlaceholderResolutionContext(catalogItemContext: card)
            let selector = try XCTUnwrap(card.catalogItem.productCartAttribute1)
            let titleBinding = try extractor.extractDataRepresentedBy(String.self,
                                                                      propertyChain: "%^DATA.catalogItem.title^%",
                                                                      responseKey: nil,
                                                                      from: card.catalogItem)
            guard case .value(let title) = titleBinding else { return XCTFail("Expected a value binding") }
            XCTAssertEqual(title, card.catalogItem.title)
            XCTAssertEqual(resolver.resolveString(placeholder: "%^DATA.catalogItem.productCartAttribute1^%", context: context),
                           selector)
            XCTAssertEqual(resolver.resolveString(placeholder: "%^DATA.catalogItem.productCartAttribute2^%", context: context),
                           card.catalogItem.productCartAttribute2)
            XCTAssertEqual(resolver
                .resolveString(placeholder: "%^DATA.catalogItem.images.catalogItemImage0.light^%", context: context),
                           card.catalogItem.images["catalogItemImage0"]?.light)
            XCTAssertEqual(resolver.resolveString(placeholder: "%^DATA.creativeCopy.title^%", context: context), "Product offer")
            XCTAssertEqual(resolver.resolveInt(placeholder: "%^STATE.IndicatorPosition^%", context: context), 1)
            XCTAssertEqual(resolver.resolveInt(placeholder: "%^STATE.TotalOffers^%", context: context), 2)
        }
    }
}
