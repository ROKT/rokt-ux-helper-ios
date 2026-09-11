import Foundation
import SwiftUI
import Combine
import DcuiSchema

enum LayoutDismissOptions {
    case closeButton, noMoreOffer, endMessage, collapsed, defaultDismiss, partnerTriggered, instantPurchaseDismiss
}

enum DevicePayStatus {
    case success
    case failure
    case retry
    /// Intermediate state emitted when the host SDK has fetched the cart breakdown
    /// (subtotal/tax/shipping/total + e.g. PayPal URL) and the UX should now display
    /// the confirmation screen before the user finalizes the purchase.
    case pendingConfirmation(catalogRuntimeData: [String: String])
}

enum ForwardPaymentStatus {
    case success
    case failure(reason: String?)
}

typealias EventDiagnosticServicing = EventServicing & DiagnosticServicing

@available(iOS 13.0, *)
class EventService: Hashable, EventDiagnosticServicing {
    private struct ActiveDevicePayAttempt {
        let catalogItemId: String
        let paymentAttemptId: String
        let paymentProvider: PaymentProvider
        var isProviderUIOpen = false
    }

    private struct ActiveForwardPayment {
        let catalogItemId: String
        let paymentAttemptId: String?
        let completion: (_ status: ForwardPaymentStatus) -> Void
    }

    let pageId: String?
    let pageInstanceGuid: String
    let sessionId: String
    let pluginInstanceGuid: String
    let pluginId: String
    let pluginName: String?
    let startDate: Date
    let pluginConfigJWTToken: String
    let useDiagnosticEvents: Bool
    let processor: EventProcessing
    let catalogItems: [CatalogItem]

    weak var uxEventDelegate: UXEventsDelegate?
    var responseReceivedDate: Date
    var isFirstPositiveEngagementSend = false
    var dismissOption: LayoutDismissOptions?

    // No helper-owned timeout is scheduled here: the helper does not know the provider SLA and
    // cannot distinguish an intentionally backgrounded app from an abandoned payment safely.
    // The owning payment SDK must finalize the attempt with DEVICE_PAY_RESPONSE_TIMEOUT when its
    // provider-specific, lifecycle-aware deadline expires.
    private var devicePayCompletion: ((_ status: DevicePayStatus) -> Void)?
    private var activeDevicePayAttempt: ActiveDevicePayAttempt?
    private var activeForwardPayment: ActiveForwardPayment?

    init(pageId: String?,
         pageInstanceGuid: String,
         sessionId: String,
         pluginInstanceGuid: String,
         pluginId: String,
         pluginName: String?,
         startDate: Date,
         catalogItems: [CatalogItem] = [],
         uxEventDelegate: UXEventsDelegate,
         processor: EventProcessing,
         responseReceivedDate: Date,
         isFirstPositiveEngagementSend: Bool = false,
         pluginConfigJWTToken: String,
         dismissOption: LayoutDismissOptions? = nil,
         useDiagnosticEvents: Bool) {
        self.pageId = pageId
        self.pageInstanceGuid = pageInstanceGuid
        self.sessionId = sessionId
        self.pluginInstanceGuid = pluginInstanceGuid
        self.pluginId = pluginId
        self.pluginName = pluginName
        self.startDate = startDate
        self.uxEventDelegate = uxEventDelegate
        self.responseReceivedDate = responseReceivedDate
        self.isFirstPositiveEngagementSend = isFirstPositiveEngagementSend
        self.pluginConfigJWTToken = pluginConfigJWTToken
        self.dismissOption = dismissOption
        self.useDiagnosticEvents = useDiagnosticEvents
        self.processor = processor
        self.catalogItems = catalogItems
    }

    func sendSignalLoadStartEvent() {
        sendEvent(.SignalLoadStart, parentGuid: pluginInstanceGuid, jwtToken: pluginConfigJWTToken)
    }

    func sendEventsOnTransformerSuccess() {
        sendPlacementReadyEventCallback()
        sendSignalLoadCompleteEvent()
    }

    private func sendPlacementReadyEventCallback() {
        uxEventDelegate?.onPlacementReady(pluginId)
    }

    private func sendSignalLoadCompleteEvent() {
        sendEvent(.SignalLoadComplete, parentGuid: pluginInstanceGuid, jwtToken: pluginConfigJWTToken)
    }

    func sendSignalActivationEvent() {
        sendEvent(.SignalActivation, parentGuid: pluginInstanceGuid, jwtToken: pluginConfigJWTToken)
    }

    func sendEventsOnLoad() {
        sendPlacementInteractiveEventCallback()
        sendPluginImpressionEvent()
    }

    func sendSlotImpressionEvent(instanceGuid: String, jwtToken: String) {
        sendEvent(.SignalImpression, parentGuid: instanceGuid, jwtToken: jwtToken)
    }

    func sendSignalViewedEvent(instanceGuid: String, jwtToken: String) {
        sendEvent(.SignalViewed, parentGuid: instanceGuid, jwtToken: jwtToken)
    }

    func sendSignalResponseEvent(
        instanceGuid: String,
        jwtToken: String,
        isPositive: Bool,
        destinationURL: String?
    ) {
        sendEngagementEventCallback(isPositive: isPositive)
        sendEvent(
            .SignalResponse,
            parentGuid: instanceGuid,
            extraMetadata: clickDestinationMetadata(destinationURL),
            jwtToken: jwtToken
        )
    }

    func sendGatedSignalResponseEvent(
        instanceGuid: String,
        jwtToken: String,
        isPositive: Bool,
        destinationURL: String?
    ) {
        sendEngagementEventCallback(isPositive: isPositive)
        sendEvent(
            .SignalGatedResponse,
            parentGuid: instanceGuid,
            extraMetadata: clickDestinationMetadata(destinationURL),
            jwtToken: jwtToken
        )
    }

    private func clickDestinationMetadata(_ destinationURL: String?) -> [RoktEventNameValue] {
        guard let destinationURL, !destinationURL.isEmpty else { return [] }
        return [RoktEventNameValue(name: kTransformedTrafficURL, value: destinationURL)]
    }

    func sendDismissalEvent() {
        cancelActivePayment()
        sendDismissalEventCallback()
        switch dismissOption {
        case .noMoreOffer:
            sendDismissalNoMoreOfferEvent()
        case .closeButton:
            sendDismissalCloseEvent()
        case .endMessage:
            sendDismissalEndMessageEvent()
        case .collapsed:
            sendDismissalCollapsedEvent()
        case .partnerTriggered:
            sendDismissalPartnerTriggeredEvent()
        case .instantPurchaseDismiss:
            sendInstantPurchaseDissmissOfferEvent()
        default:
            sendDefaultDismissEvent()
        }
    }

    func sendEvent(
        _ eventType: RoktUXEventType,
        parentGuid: String,
        extraMetadata: [RoktEventNameValue] = [RoktEventNameValue](),
        eventData: [String: String] = [:],
        objectData: [String: String]? = nil,
        jwtToken: String
    ) {
        processor.handle(
            event: RoktEventRequest(
                sessionId: sessionId,
                eventType: eventType,
                parentGuid: parentGuid,
                extraMetadata: extraMetadata,
                eventData: eventData,
                objectData: objectData,
                pageInstanceGuid: pageInstanceGuid,
                jwtToken: jwtToken
            )
        )
    }

    func openURL(url: URL, type: RoktUXOpenURLType, completionHandler: @escaping () -> Void) {
        canOpenUrl(url)
        let id = UUID().uuidString
        uxEventDelegate?.openURL(url: url.absoluteString, id: id, layoutId: pluginId, type: type, onClose: { incomingId in
            if id == incomingId {
                completionHandler()
            }
        }, onError: { [weak self] incomingId, error in
            if id == incomingId {
                self?.sendDiagnostics(message: kWebViewErrorCode,
                                      callStack: error?.localizedDescription ?? kStaticPageError)
            }
        })
    }

    func cartItemInstantPurchase(catalogItem: CatalogItem) {
        sendCartItemEvent(eventType: .SignalCartItemInstantPurchaseInitiated, catalogItem: catalogItem)
        uxEventDelegate?.onCartItemInstantPurchase(pluginId, catalogItem: catalogItem)
    }

    func cartItemInstantPurchaseSuccess(itemId: String) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }
        sendCartItemEvent(eventType: .SignalCartItemInstantPurchase, catalogItem: catalogItem)
    }

    func cartItemInstantPurchaseFailure(itemId: String) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }
        sendCartItemEvent(eventType: .SignalCartItemInstantPurchaseFailure, catalogItem: catalogItem)
    }

    func sendUserInteraction(action: UserInteraction, context: UserInteractionContext) {
        let objectData = [
            kAction: action.rawValue,
            kContext: context.rawValue,
            // Canonical classification the ledger reads; mirrors action so downstream
            // consumers get a populated interactionType without SDK-side derivation.
            kInteractionType: action.rawValue
        ]
        sendEvent(
            .SignalUserInteraction,
            parentGuid: pluginInstanceGuid,
            objectData: objectData,
            jwtToken: pluginConfigJWTToken
        )
    }

    func cartItemUserInteraction(itemId: String, action: UserInteraction, context: UserInteractionContext) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }
        let objectData = [
            kAction: action.rawValue,
            kContext: context.rawValue,
            // Canonical classification the ledger reads; mirrors action so downstream
            // consumers get a populated interactionType without SDK-side derivation.
            kInteractionType: action.rawValue
        ]
        sendCartItemEvent(eventType: .SignalUserInteraction, catalogItem: catalogItem, objectData: objectData)
    }

    func cartItemDevicePay(
        catalogItem: CatalogItem,
        paymentProvider: PaymentProvider,
        transactionData: TransactionData?,
        completion: @escaping (_ status: DevicePayStatus) -> Void
    ) {
        guard activeDevicePayAttempt == nil, activeForwardPayment == nil else {
            sendDiagnostics(
                message: kDevicePayProcessingErrorCode,
                callStack: "Device pay already processing for layout \(pluginId); dropped \(catalogItem.catalogItemId)"
            )
            completion(.failure)
            return
        }

        let attempt = ActiveDevicePayAttempt(
            catalogItemId: catalogItem.catalogItemId,
            paymentAttemptId: UUID().uuidString,
            paymentProvider: paymentProvider
        )
        activeDevicePayAttempt = attempt
        devicePayCompletion = completion

        let objectData = devicePayObjectData(catalogItem: catalogItem, attempt: attempt)
        sendCartItemEvent(eventType: .SignalCartItemInstantPurchaseInitiated, catalogItem: catalogItem, objectData: objectData)
        uxEventDelegate?.onCartItemDevicePay(
            pluginId,
            catalogItem: catalogItem,
            paymentProvider: paymentProvider,
            transactionData: transactionData,
            paymentAttemptId: attempt.paymentAttemptId
        )

    }

    func cartItemDevicePaySuccess(itemId: String, paymentAttemptId: String) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }
        // For two-step flows that already transitioned to .pendingConfirmation,
        // devicePayCompletion was cleared by cartItemDevicePayPendingConfirmation and the
        // Step-2 SignalCartItemForwardPayment* signals own the terminal state. Skip emitting
        // SignalCartItemInstantPurchase here to avoid double-counting.
        guard let attempt = matchingDevicePayAttempt(
            itemId: itemId,
            paymentAttemptId: paymentAttemptId
        ),
              let completion = devicePayCompletion else { return }
        devicePayCompletion = nil
        activeDevicePayAttempt = nil
        sendCartItemEvent(
            eventType: .SignalCartItemInstantPurchase,
            catalogItem: catalogItem,
            objectData: devicePayObjectData(catalogItem: catalogItem, attempt: attempt)
        )
        sendDevicePayInteraction(
            catalogItem: catalogItem,
            attempt: attempt,
            action: .DevicePaySucceeded
        )
        completion(.success)
    }

    func cartItemDevicePayFailure(
        itemId: String,
        failureReason: String?,
        paymentAttemptId: String
    ) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }
        // Symmetric guard with cartItemDevicePaySuccess — once the flow transitioned to
        // forward-payment Step-2, that branch owns the terminal failure signal.
        guard let attempt = matchingDevicePayAttempt(
            itemId: itemId,
            paymentAttemptId: paymentAttemptId
        ),
              let completion = devicePayCompletion else { return }
        devicePayCompletion = nil
        activeDevicePayAttempt = nil
        sendDevicePayFailureSignal(
            catalogItem: catalogItem,
            attempt: attempt,
            failureReason: normalizedDevicePayFailureReason(failureReason)
        )
        sendDevicePayInteraction(
            catalogItem: catalogItem,
            attempt: attempt,
            action: .DevicePayFailed
        )
        completion(.failure)
    }

    func cartItemDevicePayLoadingFailure(
        itemId: String,
        failureReason: String?,
        paymentAttemptId: String
    ) {
        cartItemDevicePayFailure(
            itemId: itemId,
            failureReason: normalizedDevicePayFailureReason(
                failureReason,
                fallback: "INSTANT_PURCHASE_PAYMENT_LOADING_FAILURE"
            ),
            paymentAttemptId: paymentAttemptId
        )
    }

    func cartItemDevicePayRetryableFailure(itemId: String, paymentAttemptId: String) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }
        guard let attempt = matchingDevicePayAttempt(
            itemId: itemId,
            paymentAttemptId: paymentAttemptId
        ),
              let completion = devicePayCompletion else { return }
        devicePayCompletion = nil
        activeDevicePayAttempt = nil
        sendDevicePayInteraction(
            catalogItem: catalogItem,
            attempt: attempt,
            action: .DevicePayRetryableFailure
        )
        sendDevicePayFailureSignal(
            catalogItem: catalogItem,
            attempt: attempt,
            failureReason: "DEVICE_PAY_RETRYABLE_DECLINE"
        )
        completion(.retry)
    }

    func cartItemDevicePayRetry(itemId: String, paymentAttemptId: String) {
        guard matchingDevicePayAttempt(
            itemId: itemId,
            paymentAttemptId: paymentAttemptId
        ) != nil else { return }
        cancelActivePayment()
    }

    func cartItemDevicePayProviderUIOpened(itemId: String, paymentAttemptId: String) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }),
              var attempt = matchingDevicePayAttempt(
                  itemId: itemId,
                  paymentAttemptId: paymentAttemptId
              ),
              !attempt.isProviderUIOpen else { return }
        attempt.isProviderUIOpen = true
        activeDevicePayAttempt = attempt
        sendDevicePayInteraction(
            catalogItem: catalogItem,
            attempt: attempt,
            action: .PaymentProviderUIOpened
        )
    }

    func cartItemDevicePayProviderUIClosed(itemId: String, paymentAttemptId: String) {
        guard matchingDevicePayAttempt(
            itemId: itemId,
            paymentAttemptId: paymentAttemptId
        ) != nil else { return }
        cancelActivePayment()
    }

    private func cancelActivePayment() {
        if let forwardPayment = activeForwardPayment {
            cancelActiveForwardPayment(forwardPayment)
            return
        }
        cancelActiveDevicePay()
    }

    private func cancelActiveDevicePay() {
        guard let attempt = activeDevicePayAttempt else { return }
        let completion = devicePayCompletion
        devicePayCompletion = nil
        activeDevicePayAttempt = nil
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == attempt.catalogItemId }) else {
            completion?(.retry)
            return
        }
        if attempt.isProviderUIOpen {
            sendDevicePayInteraction(
                catalogItem: catalogItem,
                attempt: attempt,
                action: .PaymentProviderUIClosed
            )
        }
        sendDevicePayInteraction(
            catalogItem: catalogItem,
            attempt: attempt,
            action: .DevicePayCancelled
        )
        sendDevicePayFailureSignal(
            catalogItem: catalogItem,
            attempt: attempt,
            failureReason: "DEVICE_PAY_CANCELLED"
        )
        completion?(.retry)
    }

    private func sendDevicePayFailureSignal(
        catalogItem: CatalogItem,
        attempt: ActiveDevicePayAttempt,
        failureReason: String
    ) {
        var objectData = devicePayObjectData(catalogItem: catalogItem, attempt: attempt)
        objectData["failureReason"] = failureReason
        sendCartItemEvent(
            eventType: .SignalCartItemInstantPurchaseFailure,
            catalogItem: catalogItem,
            objectData: objectData
        )
    }

    private func sendDevicePayInteraction(
        catalogItem: CatalogItem,
        attempt: ActiveDevicePayAttempt,
        action: UserInteraction
    ) {
        var objectData = devicePayObjectData(catalogItem: catalogItem, attempt: attempt)
        objectData[kAction] = action.rawValue
        objectData[kContext] = attempt.paymentProvider.rawValue
        objectData[kInteractionType] = action.rawValue
        sendCartItemEvent(
            eventType: .SignalUserInteraction,
            catalogItem: catalogItem,
            objectData: objectData
        )
    }

    private func devicePayObjectData(
        catalogItem: CatalogItem,
        attempt: ActiveDevicePayAttempt
    ) -> [String: String] {
        [
            kCatalogItemId: catalogItem.catalogItemId,
            kQuantity: "1",
            kPaymentAttemptId: attempt.paymentAttemptId
        ]
    }

    private func matchingDevicePayAttempt(
        itemId: String,
        paymentAttemptId: String
    ) -> ActiveDevicePayAttempt? {
        guard let attempt = activeDevicePayAttempt,
              attempt.catalogItemId == itemId,
              attempt.paymentAttemptId == paymentAttemptId else { return nil }
        return attempt
    }

    private func normalizedDevicePayFailureReason(
        _ failureReason: String?,
        fallback: String = "DEVICE_PAY_UNKNOWN_FAILURE"
    ) -> String {
        let normalized = failureReason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalized.isEmpty ? fallback : normalized
    }

    /// Invoked when the host SDK has fetched the order breakdown from
    /// `/v1/cart/initialize-purchase` (or equivalent) and wants the UX to display the
    /// confirmation screen. Resolves the stored `devicePayCompletion` with the breakdown
    /// payload so the button view model can publish it to the layout. The purchase initiation
    /// was already recorded when the user tapped.
    func cartItemDevicePayPendingConfirmation(
        itemId: String,
        catalogRuntimeData: [String: String],
        paymentAttemptId: String
    ) {
        guard matchingDevicePayAttempt(
            itemId: itemId,
            paymentAttemptId: paymentAttemptId
        ) != nil else { return }
        devicePayCompletion?(.pendingConfirmation(catalogRuntimeData: catalogRuntimeData))
        devicePayCompletion = nil
    }

    func cartItemForwardPayment(
        catalogItem: CatalogItem,
        transactionData: TransactionData?,
        completion: @escaping (_ status: ForwardPaymentStatus) -> Void
    ) {
        guard activeForwardPayment == nil else {
            sendDiagnostics(
                message: kForwardPaymentProcessingErrorCode,
                callStack: "Forward payment already processing for layout \(pluginId); dropped \(catalogItem.catalogItemId)"
            )
            return
        }

        let linkedAttempt: ActiveDevicePayAttempt?
        if let activeDevicePayAttempt {
            guard activeDevicePayAttempt.catalogItemId == catalogItem.catalogItemId else {
                let callStack = "Forward payment item \(catalogItem.catalogItemId) does not match "
                    + "active device-pay item \(activeDevicePayAttempt.catalogItemId) on layout \(pluginId)"
                sendDiagnostics(
                    message: kForwardPaymentProcessingErrorCode,
                    callStack: callStack
                )
                return
            }
            linkedAttempt = activeDevicePayAttempt
        } else {
            linkedAttempt = nil
        }

        let paymentAttemptId = linkedAttempt?.paymentAttemptId
        activeForwardPayment = ActiveForwardPayment(
            catalogItemId: catalogItem.catalogItemId,
            paymentAttemptId: paymentAttemptId,
            completion: completion
        )

        let objectData = linkedAttempt.map {
            forwardPaymentObjectData(catalogItem: catalogItem, attempt: $0)
        }
        sendCartItemEvent(
            eventType: .SignalCartItemInstantPurchaseInitiated,
            catalogItem: catalogItem,
            objectData: objectData
        )
        uxEventDelegate?.onCartItemForwardPayment(
            pluginId,
            catalogItem: catalogItem,
            transactionData: transactionData,
            paymentAttemptId: paymentAttemptId
        )
    }

    func cartItemForwardPaymentSuccess(itemId: String, paymentAttemptId: String?) {
        guard let forwardPayment = matchingForwardPayment(
            itemId: itemId,
            paymentAttemptId: paymentAttemptId,
            transition: "success"
        ),
              let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }

        let linkedAttempt: ActiveDevicePayAttempt?
        if let paymentAttemptId = forwardPayment.paymentAttemptId {
            guard let attempt = matchingDevicePayAttempt(
                itemId: itemId,
                paymentAttemptId: paymentAttemptId
            ) else {
                sendForwardPaymentAttemptMismatchDiagnostic(transition: "success")
                return
            }
            linkedAttempt = attempt
        } else {
            linkedAttempt = nil
        }

        activeForwardPayment = nil
        if let attempt = linkedAttempt {
            activeDevicePayAttempt = nil
            sendCartItemEvent(
                eventType: .SignalCartItemInstantPurchase,
                catalogItem: catalogItem,
                objectData: forwardPaymentObjectData(catalogItem: catalogItem, attempt: attempt)
            )
            sendDevicePayInteraction(
                catalogItem: catalogItem,
                attempt: attempt,
                action: .DevicePaySucceeded
            )
        }
        forwardPayment.completion(.success)
    }

    func cartItemForwardPaymentFailure(
        itemId: String,
        failureReason: String?,
        paymentAttemptId: String?
    ) {
        guard let forwardPayment = matchingForwardPayment(
            itemId: itemId,
            paymentAttemptId: paymentAttemptId,
            transition: "failure"
        ),
              let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }

        let linkedAttempt: ActiveDevicePayAttempt?
        if let paymentAttemptId = forwardPayment.paymentAttemptId {
            guard let attempt = matchingDevicePayAttempt(
                itemId: itemId,
                paymentAttemptId: paymentAttemptId
            ) else {
                sendForwardPaymentAttemptMismatchDiagnostic(transition: "failure")
                return
            }
            linkedAttempt = attempt
        } else {
            linkedAttempt = nil
        }

        activeForwardPayment = nil
        if let attempt = linkedAttempt {
            activeDevicePayAttempt = nil
            let normalizedReason = normalizedDevicePayFailureReason(failureReason)
            var objectData = forwardPaymentObjectData(catalogItem: catalogItem, attempt: attempt)
            objectData["failureReason"] = normalizedReason
            sendCartItemEvent(
                eventType: .SignalCartItemInstantPurchaseFailure,
                catalogItem: catalogItem,
                objectData: objectData
            )
            sendDevicePayInteraction(
                catalogItem: catalogItem,
                attempt: attempt,
                action: .DevicePayFailed
            )
        }
        forwardPayment.completion(.failure(reason: failureReason))
    }

    private func forwardPaymentObjectData(
        catalogItem: CatalogItem,
        attempt: ActiveDevicePayAttempt
    ) -> [String: String] {
        var objectData = devicePayObjectData(catalogItem: catalogItem, attempt: attempt)
        objectData[kPaymentStage] = "ForwardPayment"
        return objectData
    }

    private func matchingForwardPayment(
        itemId: String,
        paymentAttemptId: String?,
        transition: String
    ) -> ActiveForwardPayment? {
        guard let forwardPayment = activeForwardPayment else { return nil }
        guard forwardPayment.catalogItemId == itemId,
              forwardPayment.paymentAttemptId == paymentAttemptId else {
            sendDiagnostics(
                message: kForwardPaymentProcessingErrorCode,
                callStack: "Forward payment \(transition) did not match active item/attempt on layout \(pluginId); ignoring"
            )
            return nil
        }
        return forwardPayment
    }

    private func sendForwardPaymentAttemptMismatchDiagnostic(transition: String) {
        let callStack = "Forward payment \(transition) no longer matches its originating "
            + "device-pay attempt on layout \(pluginId); ignoring"
        sendDiagnostics(
            message: kForwardPaymentProcessingErrorCode,
            callStack: callStack
        )
    }

    private func cancelActiveForwardPayment(_ forwardPayment: ActiveForwardPayment) {
        activeForwardPayment = nil
        let cancellationReason = "DEVICE_PAY_CANCELLED"
        let linkedAttempt = forwardPayment.paymentAttemptId.flatMap {
            matchingDevicePayAttempt(
                itemId: forwardPayment.catalogItemId,
                paymentAttemptId: $0
            )
        }
        devicePayCompletion = nil
        activeDevicePayAttempt = nil

        if let attempt = linkedAttempt,
           let catalogItem = catalogItems.first(where: { $0.catalogItemId == attempt.catalogItemId }) {
            if attempt.isProviderUIOpen {
                sendDevicePayInteraction(
                    catalogItem: catalogItem,
                    attempt: attempt,
                    action: .PaymentProviderUIClosed
                )
            }
            sendDevicePayInteraction(
                catalogItem: catalogItem,
                attempt: attempt,
                action: .DevicePayCancelled
            )
            var objectData = forwardPaymentObjectData(catalogItem: catalogItem, attempt: attempt)
            objectData["failureReason"] = cancellationReason
            sendCartItemEvent(
                eventType: .SignalCartItemInstantPurchaseFailure,
                catalogItem: catalogItem,
                objectData: objectData
            )
        }

        forwardPayment.completion(.failure(reason: cancellationReason))
    }

    private func sendCartItemEvent(eventType: RoktUXEventType, catalogItem: CatalogItem, objectData: [String: String]? = nil) {
        sendEvent(
            eventType,
            parentGuid: catalogItem.instanceGuid,
            objectData: objectData,
            jwtToken: catalogItem.token
        )
    }

    private func canOpenUrl(_ url: URL) {
        if !UIApplication.shared.canOpenURL(url) {
            sendDiagnostics(message: kUrlErrorCode,
                            callStack: url.absoluteString)
        }
    }

    private func sendPlacementInteractiveEventCallback() {
        uxEventDelegate?.onPlacementInteractive(pluginId)
    }

    private func sendPluginImpressionEvent() {
        var metaData = [
            RoktEventNameValue(name: BE_PAGE_SIGNAL_LOAD,
                               value: EventDateFormatter.getDateString(startDate)),
            RoktEventNameValue(name: BE_PAGE_RENDER_ENGINE,
                               value: BE_RENDER_ENGINE_LAYOUTS),
            RoktEventNameValue(name: BE_PAGE_SIGNAL_COMPLETE,
                               value: EventDateFormatter.getDateString(responseReceivedDate)),
            RoktEventNameValue(name: BE_TIMINGS_EVENT_TIME_KEY,
                               value: EventDateFormatter.getDateString(DateHandler.currentDate())),
            RoktEventNameValue(name: BE_HEADER_PAGE_INSTANCE_GUID_KEY,
                               value: pageInstanceGuid),
            RoktEventNameValue(name: BE_TIMINGS_PLUGIN_ID_KEY,
                               value: pluginId)
        ]
        pageId.map {
            metaData.append(
                RoktEventNameValue(name: BE_VIEW_NAME_KEY, value: $0)
            )
        }
        pluginName.map {
            metaData.append(
                RoktEventNameValue(name: BE_TIMINGS_PLUGIN_NAME_KEY,
                                   value: $0)
            )
        }
        sendEvent(.SignalImpression,
                  parentGuid: pluginInstanceGuid,
                  extraMetadata: metaData,
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDismissalEndMessageEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kEndMessage)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDismissalCollapsedEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kCollapsed)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDismissalCloseEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kCloseButton)],
                  jwtToken: pluginConfigJWTToken)
    }
    private func sendDismissalPartnerTriggeredEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kPartnerTriggered)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendInstantPurchaseDissmissOfferEvent() {
        sendEvent(.SignalInstantPurchaseDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kInstantPurchaseDismiss)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDismissalNoMoreOfferEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kNoMoreOfferToShow)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDefaultDismissEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kDismissed)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendEngagementEventCallback(isPositive: Bool) {
        uxEventDelegate?.onOfferEngagement(pluginId)

        if isPositive {
            uxEventDelegate?.onPositiveEngagement(pluginId)

            if !isFirstPositiveEngagementSend {
                uxEventDelegate?.onFirstPositiveEngagement(
                    sessionId: sessionId,
                    pluginInstanceGuid: pluginInstanceGuid,
                    jwtToken: pluginConfigJWTToken,
                    layoutId: pluginId
                )
                isFirstPositiveEngagementSend = true
            }
        }
    }

    private func sendDismissalEventCallback() {
        switch dismissOption {
        case .noMoreOffer, .endMessage, .collapsed:
            uxEventDelegate?.onPlacementCompleted(pluginId)
        case .closeButton, .partnerTriggered, .instantPurchaseDismiss:
            uxEventDelegate?.onPlacementClosed(pluginId)
        default:
            uxEventDelegate?.onPlacementClosed(pluginId)
        }
    }
}

class DateHandler {
    static var customDate: Date?

    static func currentDate() -> Date {
        return self.customDate ?? Date()
    }
}

class EventDateFormatter {

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: kBaseLocale)
        dateFormatter.dateFormat = kEventTimeStamp
        dateFormatter.timeZone = TimeZone(abbreviation: kUTCTimeStamp)
        return dateFormatter
    }()

    static func getDateString(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
