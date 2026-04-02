import Foundation
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15, *)
class MockEventService: EventDiagnosticServicing {
    var pluginInstanceGuid: String = "mock-plugin-guid"
    var pluginConfigJWTToken: String = "mock-jwt"
    var useDiagnosticEvents: Bool = false

    func sendEvent(
        _ eventType: RoktUXEventType,
        parentGuid: String,
        extraMetadata: [RoktEventNameValue],
        eventData: [String: String],
        objectData: [String: String]?,
        jwtToken: String
    ) {}

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
    var cartItemUserInteractionCalled = false
    var cartItemDevicePayCalled = false
    var cartItemDevicePaySuccessCalled = false
    var cartItemDevicePayFailureCalled = false

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

    var lastSlotImpressionInstanceGuid: String?
    var lastSlotImpressionJwtToken: String?

    func sendSlotImpressionEvent(instanceGuid: String, jwtToken: String) {
        slotImpressionEventCalled = true
        lastSlotImpressionInstanceGuid = instanceGuid
        lastSlotImpressionJwtToken = jwtToken
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

    var lastUserInteractionItemId: String?
    var lastUserInteractionAction: UserInteraction?
    var lastUserInteractionContext: UserInteractionContext?

    func cartItemUserInteraction(itemId: String, action: UserInteraction, context: UserInteractionContext) {
        cartItemUserInteractionCalled = true
        lastUserInteractionItemId = itemId
        lastUserInteractionAction = action
        lastUserInteractionContext = context
    }

    var cartItemDevicePayCompletionCallback: ((DevicePayStatus) -> Void)?

    func cartItemDevicePay(
        catalogItem: CatalogItem,
        paymentProvider: DcuiSchema.PaymentProvider,
        completion: @escaping (DevicePayStatus) -> Void
    ) {
        cartItemDevicePayCalled = true
        cartItemDevicePayCompletionCallback = completion
    }

    func cartItemDevicePaySuccess(itemId: String) {
        cartItemDevicePaySuccessCalled = true
    }

    func cartItemDevicePayFailure(itemId: String) {
        cartItemDevicePayFailureCalled = true
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
        cartItemUserInteractionCalled = false
        cartItemDevicePayCalled = false
        cartItemDevicePaySuccessCalled = false
        cartItemDevicePayFailureCalled = false
        dismissOption = nil
    }
}
