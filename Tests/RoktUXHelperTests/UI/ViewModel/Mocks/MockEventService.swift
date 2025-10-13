import DcuiSchema
import Foundation

@testable import RoktUXHelper

@available(iOS 15, *)
class MockEventService: EventServicing & DiagnosticServicing {
    // MARK: - Test Tracking Properties

    var pluginInstanceGuid: String = "test-plugin-instance-guid"
    var pluginConfigJWTToken: String = "test-jwt-token"
    var useDiagnosticEvents: Bool = true
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
    var cartItemDevicePayCalled = false
    var cartItemDevicePaySuccessCalled = false
    var cartItemDevicePayFailureCalled = false
    var cartItemDevicePayCompletionCallback: (() -> Void)? = nil

    // MARK: - Protocol Properties

    var dismissOption: LayoutDismissOptions?

    // MARK: - Protocol Methods

    func sendEvent(
        _ eventType: RoktUXEventType,
        parentGuid: String,
        extraMetadata: [RoktEventNameValue],
        eventData: [String: String],
        jwtToken: String
    ) {}

    func sendDiagnostics(
        message: String,
        callStack: String,
        severity: Severity
    ) {}

    func sendFontDiagnostics(_ fontFamily: String) {}

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

    func cartItemDevicePay(catalogItem: CatalogItem, paymentProvider: PaymentProvider, completion: @escaping () -> Void) {
        cartItemDevicePayCalled = true
        cartItemDevicePayCompletionCallback = completion
    }

    func cartItemDevicePaySuccess(itemId: String) {
        cartItemDevicePaySuccessCalled = true
        cartItemDevicePayCompletionCallback?()
        cartItemDevicePayCompletionCallback = nil
    }

    func cartItemDevicePayFailure(itemId: String) {
        cartItemDevicePayFailureCalled = true
        cartItemDevicePayCompletionCallback = nil
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
        cartItemDevicePayCalled = false
        cartItemDevicePaySuccessCalled = false
        cartItemDevicePayFailureCalled = false
        cartItemDevicePayCompletionCallback = nil
        dismissOption = nil
    }
}
