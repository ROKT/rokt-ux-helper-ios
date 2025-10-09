import DcuiSchema
import Foundation

@testable import RoktUXHelper

@available(iOS 15, *)
class MockEventService: EventServicing {
    // MARK: - Test Tracking Properties

    var dismissalCollapsedEventSent = false
    var dismissalNoMoreOfferEventSent = false
    var signalLoadStartEventCalled = false
    var transformerSuccessEventsCalled = false
    var signalActivationEventCalled = false
    var eventsOnLoadCalled = false
    var slotImpressionEventCalled = false
    var signalViewedEventCalled = false
    var signalResponseEventCalled = false
    var gatedSignalResponseEventCalled = false
    var dismissalEventCalled = false
    var openURLCalled = false
    var cartItemInstantPurchaseCalled = false
    var cartItemInstantPurchaseSuccessCalled = false
    var cartItemInstantPurchaseFailureCalled = false

    // MARK: - Protocol Properties

    var dismissOption: LayoutDismissOptions?

    // MARK: - Protocol Methods

    func sendSignalLoadStartEvent() {
        signalLoadStartEventCalled = true
    }

    func sendEventsOnTransformerSuccess() {
        transformerSuccessEventsCalled = true
    }

    func sendSignalActivationEvent() {
        signalActivationEventCalled = true
    }

    func sendEventsOnLoad() {
        eventsOnLoadCalled = true
    }

    func sendSlotImpressionEvent(instanceGuid: String, jwtToken: String) {
        slotImpressionEventCalled = true
    }

    func sendSignalViewedEvent(instanceGuid: String, jwtToken: String) {
        signalViewedEventCalled = true
    }

    func sendSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool) {
        signalResponseEventCalled = true
    }

    func sendGatedSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool) {
        gatedSignalResponseEventCalled = true
    }

    func sendDismissalEvent() {
        dismissalEventCalled = true
    }

    func openURL(url: URL, type: RoktUXOpenURLType, completionHandler: @escaping () -> Void) {
        openURLCalled = true
        completionHandler()
    }

    func cartItemInstantPurchase(catalogItem: CatalogItem) {
        cartItemInstantPurchaseCalled = true
    }

    func cartItemInstantPurchaseSuccess(itemId: String) {
        cartItemInstantPurchaseSuccessCalled = true
    }

    func cartItemInstantPurchaseFailure(itemId: String) {
        cartItemInstantPurchaseFailureCalled = true
    }

    // MARK: - Additional Test Methods

    func sendImpressionEvents(currentOffer: Int) {
        // No-op for mock
    }

    func sendDismissalCollapsedEvent() {
        dismissalCollapsedEventSent = true
    }

    func sendDismissalNoMoreOfferEvent() {
        dismissalNoMoreOfferEventSent = true
    }

    // MARK: - Reset Test State

    func reset() {
        dismissalCollapsedEventSent = false
        dismissalNoMoreOfferEventSent = false
        signalLoadStartEventCalled = false
        transformerSuccessEventsCalled = false
        signalActivationEventCalled = false
        eventsOnLoadCalled = false
        slotImpressionEventCalled = false
        signalViewedEventCalled = false
        signalResponseEventCalled = false
        gatedSignalResponseEventCalled = false
        dismissalEventCalled = false
        openURLCalled = false
        cartItemInstantPurchaseCalled = false
        cartItemInstantPurchaseSuccessCalled = false
        cartItemInstantPurchaseFailureCalled = false
        dismissOption = nil
    }
}
