import DcuiSchema
import Foundation

@testable import RoktUXHelper

@available(iOS 15, *)
class MockEventService: EventDiagnosticServicing {
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
    var cartItemDevicePayCalled = false
    var cartItemDevicePaySuccessCalled = false
    var cartItemDevicePayFailureCalled = false
    var diagnosticsSent: [(message: String, callStack: String, severity: Severity)] = []
    var fontDiagnosticsSent: [String] = []
    var eventsSent: [(
        eventType: RoktUXEventType,
        parentGuid: String,
        extraMetadata: [RoktEventNameValue],
        eventData: [String: String],
        jwtToken: String
    )] = []

    // MARK: - Protocol Properties

    var dismissOption: LayoutDismissOptions?
    var pluginInstanceGuid: String = "mock-instance"
    var pluginConfigJWTToken: String = "mock-token"
    var useDiagnosticEvents: Bool = false

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

    func cartItemDevicePay(catalogItem: CatalogItem, paymentProvider: PaymentProvider) {
        cartItemDevicePayCalled = true
    }

    func cartItemDevicePaySuccess(itemId: String) {
        cartItemDevicePaySuccessCalled = true
    }

    func cartItemDevicePayFailure(itemId: String) {
        cartItemDevicePayFailureCalled = true
    }

    func sendEvent(
        _ eventType: RoktUXEventType,
        parentGuid: String,
        extraMetadata: [RoktEventNameValue],
        eventData: [String: String],
        jwtToken: String
    ) {
        eventsSent.append((eventType, parentGuid, extraMetadata, eventData, jwtToken))
    }

    func sendDiagnostics(
        message: String,
        callStack: String,
        severity: Severity
    ) {
        diagnosticsSent.append((message, callStack, severity))
    }

    func sendFontDiagnostics(_ fontFamily: String) {
        fontDiagnosticsSent.append(fontFamily)
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
        dismissOption = nil
        diagnosticsSent = []
        fontDiagnosticsSent = []
        eventsSent = []
    }
}
