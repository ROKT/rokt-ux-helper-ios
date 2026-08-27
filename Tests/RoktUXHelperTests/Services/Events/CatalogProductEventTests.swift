import SwiftUI
import XCTest
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogProductEventTests: XCTestCase {
    func testResponsesUseSelectedOptionIdentityAndToken() throws {
        let delegate = MockUXHelper()
        var events: [RoktEventRequest] = []
        let service = get_mock_event_processor(uxEventDelegate: delegate) { events.append($0) }
        let first = try XCTUnwrap(CatalogProductResponse(context: CatalogProductActionFixture.context(itemIndex: 0),
                                                         responseKey: "buy-now"))
        let second = try XCTUnwrap(CatalogProductResponse(context: CatalogProductActionFixture.context()))
        service.sendCatalogProductResponse(first)
        service.sendCatalogProductResponse(second)
        service.sendCatalogProductResponse(first)

        XCTAssertEqual(events.map(\.eventType), Array(repeating: .SignalProductItemResponse, count: 3))
        XCTAssertEqual(events.map(\.parentGuid), ["response:example/card-a/buy", "response:example/card-b/view",
                                                  "response:example/card-a/buy"])
        XCTAssertEqual(events.map(\.jwtToken),
                       ["example-response-token-a", "example-response-token-b", "example-response-token-a"])
        XCTAssertEqual(events[0].objectData, ["catalogItemId": "item:example/product-a", "productSku": "example-sku-a",
                                              "catalogId": "example-catalog-a", "accountId": "example-product-account"])
        XCTAssertEqual(delegate.roktEvents.filter { $0 == .OfferEngagement }.count, 3)
        XCTAssertEqual(delegate.roktEvents.filter { $0 == .PositiveEngagement }.count, 3)
        XCTAssertEqual(delegate.roktEvents.filter { $0 == .FirstPositiveEngagement }.count, 1)
        XCTAssertFalse(delegate.roktEvents.contains(.CartItemInstantPurchase))
        XCTAssertFalse(delegate.roktEvents.contains(.CartItemForwardPayment))
    }

    func testImpressionsUseItemIdentityWhileScrollUsesParentCreative() throws {
        let delegate = MockUXHelper()
        var events: [RoktEventRequest] = []
        let service = get_mock_event_processor(uxEventDelegate: delegate) { events.append($0) }
        let first = try CatalogProductActionFixture.context(itemIndex: 0)
        let second = try CatalogProductActionFixture.context()
        service.sendCatalogItemImpression(context: first)
        service.sendCatalogItemImpression(context: second)
        service.sendCatalogCarouselScroll(context: second, lastCardIndex: 1)

        XCTAssertEqual(events.map(\.eventType), [.SignalImpression, .SignalImpression, .SignalUserInteraction])
        XCTAssertEqual(events[0].parentGuid, first.catalogItem.instanceGuid)
        XCTAssertEqual(events[0].jwtToken, first.catalogItem.token)
        XCTAssertEqual(events[1].parentGuid, second.catalogItem.instanceGuid)
        XCTAssertEqual(events[1].jwtToken, second.catalogItem.token)
        XCTAssertEqual(events[2].parentGuid, second.offer.creative.instanceGuid)
        XCTAssertEqual(events[2].jwtToken, second.offer.creative.jwtToken)
        XCTAssertEqual(events[2].objectData, ["action": "Scroll", "context": "CatalogCarousel",
                                              "interaction_type": "Scroll", "cardIndex": "1", "lastCardIndex": "1"])
        XCTAssertTrue(delegate.roktEvents.isEmpty)
        service.sendCatalogCarouselScroll(context: second, lastCardIndex: 100)
        XCTAssertEqual(events.count, 3)
    }

    func testProductMetadataUsesCopyFallbackWithoutInventingIdentity() throws {
        let context = try CatalogProductActionFixture.context(updateItem: {
            $0["productSku"] = ""
            $0.removeValue(forKey: "catalogId")
            $0["copy"] = ["provider.productSku": "fallback-sku", "provider.catalogId": "fallback-catalog"]
        }, updateOffer: { $0.removeValue(forKey: "accountId") })
        let response = try XCTUnwrap(CatalogProductResponse(context: context))
        XCTAssertEqual(response.metadata, ["catalogItemId": "item:example/product-b", "productSku": "fallback-sku",
                                           "catalogId": "fallback-catalog"])
        XCTAssertEqual(response.option.instanceGuid, "response:example/card-b/view")
    }

    func testResponseKeysDoNotFallBackToSiblingOptions() throws {
        let first = try CatalogProductActionFixture.context(itemIndex: 0)
        XCTAssertNil(CatalogProductResponse(context: first))
        XCTAssertNil(CatalogProductResponse(context: first, responseKey: "missing"))
        let details = try XCTUnwrap(CatalogProductResponse(context: first, responseKey: "details"))
        XCTAssertEqual(details.url.absoluteString, "https://example.com/a/details")
        XCTAssertEqual(details.option.responseJWTToken, "example-details-token-a")
        XCTAssertNotNil(CatalogProductResponse(context: try CatalogProductActionFixture.context(), responseKey: ""))
    }

    func testWrongModulesActionsAndIncompleteResponseOptionsAreRejected() throws {
        for module in [nil, "add-to-cart", "instant-purchase"] as [String?] {
            XCTAssertNil(CatalogProductResponse(context: try CatalogProductActionFixture.context(moduleName: module)))
        }
        for (key, value) in [
            ("action", "CaptureOnly" as Any), ("action", "ExternalPaymentTrigger"), ("action", "unknown"),
            ("signalType", "SignalResponse"), ("signalType", "unknown"),
            ("isPositive", false), ("isPositive", NSNull()), ("instanceGuid", ""), ("token", "")
        ] {
            let context = try CatalogProductActionFixture.context(updateOption: { $0[key] = value })
            XCTAssertNil(CatalogProductResponse(context: context), key)
        }
        let context = try CatalogProductActionFixture.context(updateOffer: { $0["catalogItemResponseAction"] = "CaptureOnly" })
        XCTAssertNil(CatalogProductResponse(context: context))
    }

    func testURLBehaviorUsesExistingNativeOpenTypes() throws {
        let cases: [(String?, RoktUXOpenURLType)] = [
            (nil, .externally), ("newTab", .externally), ("future-behavior", .externally),
            ("self", .internally(sessionId: "session")), ("inApp", .internally(sessionId: "session")),
            ("roktWebViewSDK", .internally(sessionId: "session")), ("overrideLinkNavigation", .passthrough)
        ]
        for (behavior, expected) in cases {
            let context = try CatalogProductActionFixture.context(updateOption: { $0["urlBehavior"] = behavior })
            let response = try XCTUnwrap(CatalogProductResponse(context: context))
            XCTAssertEqual(response.openURLType(sessionId: "session"), expected)
        }
    }

    func testMalformedAndUnsafeURLsDoNotEmitOrOpen() throws {
        for url in ["", " ", "/relative", "https://", "javascript:alert(1)", "data:text/html,test", "file:///tmp/example"] {
            let context = try CatalogProductActionFixture.context(updateOption: { $0["url"] = url })
            let service = MockEventService()
            let state = MockLayoutState()
            var progressions = 0
            state.actionCollection[.nextOffer] = { _ in progressions += 1 }
            CatalogProductResponseViewModel(context: context, eventService: service, layoutState: state).handleResponse()
            XCTAssertTrue(service.productResponses.isEmpty, url)
            XCTAssertFalse(service.openURLCalled, url)
            XCTAssertFalse(service.cartItemInstantPurchaseCalled, url)
            XCTAssertEqual(progressions, 0, url)
        }
        let context = try CatalogProductActionFixture.context(updateOption: { $0["url"] = "exampleapp://product/one" })
        XCTAssertNotNil(CatalogProductResponse(context: context))
    }

    func testCustomSchemesNeverGoToTheInternalWebView() throws {
        for behavior in ["self", "inApp", "roktWebViewSDK", "newTab"] {
            let context = try CatalogProductActionFixture.context(updateOption: {
                $0["url"] = "exampleapp://product/one"
                $0["urlBehavior"] = behavior
            })
            XCTAssertEqual(try XCTUnwrap(CatalogProductResponse(context: context)).openURLType(sessionId: "session"), .externally)
        }
    }

    func testClickProgressesOnceAfterURLClosesWithoutPurchase() throws {
        let delegate = CatalogProductURLDelegate()
        var events: [RoktEventRequest] = []
        let service = get_mock_event_processor(uxEventDelegate: delegate) { events.append($0) }
        let state = MockLayoutState()
        var progressions = 0
        state.actionCollection[.nextOffer] = { _ in progressions += 1 }
        let model = CatalogProductResponseViewModel(context: try CatalogProductActionFixture.context(),
                                                    eventService: service, layoutState: state)
        model.handleResponse()
        XCTAssertEqual(events.filter { $0.eventType == .SignalProductItemResponse }.count, 1)
        XCTAssertEqual(delegate.url, "https://example.com/b")
        XCTAssertEqual(delegate.openUrlType, .internally(sessionId: "session"))
        XCTAssertEqual(progressions, 0)
        delegate.closures[0]()
        delegate.closures[0]()
        XCTAssertEqual(progressions, 1)
        XCTAssertFalse(delegate.roktEvents.contains(.CartItemInstantPurchase))
        XCTAssertFalse(delegate.roktEvents.contains(.CartItemForwardPayment))
        XCTAssertFalse(delegate.roktEvents.contains(.PlacementClosed))
    }

    func testRepeatedClicksKeepTheirEventsButCannotAdvanceANewerOffer() throws {
        let delegate = CatalogProductURLDelegate()
        var events: [RoktEventRequest] = []
        let service = get_mock_event_processor(uxEventDelegate: delegate) { events.append($0) }
        let state = MockLayoutState()
        var position = 1
        var progressions = 0
        state.items[LayoutState.currentProgressKey] = Binding(get: { position }, set: { position = $0 })
        state.actionCollection[.nextOffer] = { _ in
            position += 1
            progressions += 1
        }
        let model = CatalogProductResponseViewModel(context: try CatalogProductActionFixture.context(),
                                                    eventService: service, layoutState: state)
        model.handleResponse()
        model.handleResponse()
        XCTAssertEqual(events.filter { $0.eventType == .SignalProductItemResponse }.count, 2)
        XCTAssertEqual(delegate.closures.count, 2)
        delegate.closures[0]()
        delegate.closures[1]()
        XCTAssertEqual(progressions, 1)
        model.handleResponse()
        XCTAssertEqual(delegate.closures.count, 2)
    }

    func testFailedURLOpenDoesNotAdvanceOrStartPurchase() throws {
        let delegate = CatalogProductURLDelegate()
        let service = get_mock_event_processor(uxEventDelegate: delegate)
        let state = MockLayoutState()
        var progressions = 0
        state.actionCollection[.nextOffer] = { _ in progressions += 1 }
        let model = CatalogProductResponseViewModel(context: try CatalogProductActionFixture.context(),
                                                    eventService: service, layoutState: state)
        model.handleResponse()
        delegate.errors[0]()
        XCTAssertEqual(progressions, 0)
        XCTAssertFalse(delegate.roktEvents.contains(.CartItemInstantPurchase))
        model.handleResponse()
        XCTAssertEqual(delegate.closures.count, 2)
    }

    func testDifferentCardsCannotQueueTwoDelayedOfferTransitions() throws {
        let delegate = CatalogProductURLDelegate()
        let service = get_mock_event_processor(uxEventDelegate: delegate)
        let state = MockLayoutState()
        var position = 1
        var transitions: [() -> Void] = []
        state.items[LayoutState.currentProgressKey] = Binding(get: { position }, set: { position = $0 })
        state.actionCollection[.nextOffer] = { _ in
            transitions.append {
                position += 1
                state.publishStateChange()
            }
        }
        let first = CatalogProductResponseViewModel(context: try CatalogProductActionFixture.context(itemIndex: 0),
                                                    responseKey: "buy-now", eventService: service, layoutState: state)
        let second = CatalogProductResponseViewModel(context: try CatalogProductActionFixture.context(),
                                                     eventService: service, layoutState: state)
        first.handleResponse()
        second.handleResponse()
        delegate.closures[0]()
        delegate.closures[1]()
        XCTAssertEqual(transitions.count, 1)
        XCTAssertEqual(position, 1)
        transitions[0]()
        XCTAssertEqual(position, 2)
        position = 1
        state.publishStateChange()
        second.handleResponse()
        delegate.closures[2]()
        XCTAssertEqual(transitions.count, 2)
    }

    func testOldURLCompletionCannotProgressAfterLeavingAndRevisitingOffer() throws {
        let delegate = CatalogProductURLDelegate()
        let service = get_mock_event_processor(uxEventDelegate: delegate)
        let state = MockLayoutState()
        var position = 1
        var progressions = 0
        state.items[LayoutState.currentProgressKey] = Binding(get: { position }, set: { position = $0 })
        state.actionCollection[.nextOffer] = { _ in progressions += 1 }
        let model = CatalogProductResponseViewModel(context: try CatalogProductActionFixture.context(),
                                                    eventService: service, layoutState: state)
        model.handleResponse()
        position = 2
        state.publishStateChange()
        position = 1
        state.publishStateChange()
        delegate.closures[0]()
        XCTAssertEqual(progressions, 0)
        model.handleResponse()
        delegate.closures[1]()
        XCTAssertEqual(progressions, 1)
    }
}

@available(iOS 15, *)
private enum CatalogProductActionFixture {
    static func context(itemIndex: Int = 1,
                        moduleName: String? = "standard-marketing",
                        updateOption: (inout [String: Any]) -> Void = { _ in },
                        updateItem: (inout [String: Any]) -> Void = { _ in },
                        updateOffer: (inout [String: Any]) -> Void = { _ in }) throws -> CatalogItemContext {
        var slots = try CatalogProductFixture.slots()
        let slot = slots[1]
        let originalOffer = try XCTUnwrap(slot.offer)
        var offer = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(originalOffer)) as? [String: Any])
        var items = try XCTUnwrap(offer["catalogItems"] as? [[String: Any]])
        var item = items[itemIndex]
        var options = try XCTUnwrap(item["responseOptionsMap"] as? [String: [String: Any]])
        let key = itemIndex == 0 ? "buy-now" : "positive"
        var option = try XCTUnwrap(options[key])
        updateOption(&option)
        options[key] = option
        item["responseOptionsMap"] = options
        updateItem(&item)
        items[itemIndex] = item
        offer["catalogItems"] = items
        updateOffer(&offer)
        let mapped = try JSONDecoder().decode(OfferModel.self, from: JSONSerialization.data(withJSONObject: offer))
        slots[1] = SlotModel(instanceGuid: slot.instanceGuid, offer: mapped,
                             layoutVariant: LayoutVariantModel(layoutVariantSchema: nil, moduleName: moduleName),
                             jwtToken: slot.jwtToken)
        return try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: itemIndex))
    }
}

private final class CatalogProductURLDelegate: MockUXHelper {
    var closures: [() -> Void] = []
    var errors: [() -> Void] = []

    override func openURL(url: String, id: String, layoutId: String, type: RoktUXOpenURLType,
                          onClose: @escaping (String) -> Void, onError: @escaping (String, Error?) -> Void) {
        super.openURL(url: url, id: id, layoutId: layoutId, type: type, onClose: onClose, onError: onError)
        closures.append { onClose(id) }
        errors.append { onError(id, nil) }
    }
}
