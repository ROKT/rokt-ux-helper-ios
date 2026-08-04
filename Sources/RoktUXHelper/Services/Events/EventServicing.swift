import Foundation
import DcuiSchema

protocol EventServicing: AnyObject {
    var dismissOption: LayoutDismissOptions? { get set }
    func sendSignalLoadStartEvent()
    func sendEventsOnTransformerSuccess()
    func sendSignalActivationEvent()
    func sendEventsOnLoad()
    func sendSlotImpressionEvent(instanceGuid: String, jwtToken: String)
    func sendSignalViewedEvent(instanceGuid: String, jwtToken: String)
    func sendSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool, destinationURL: String?)
    func sendGatedSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool, destinationURL: String?)
    func sendDismissalEvent()
    func openURL(url: URL, type: RoktUXOpenURLType, completionHandler: @escaping () -> Void)
    func cartItemInstantPurchase(catalogItem: CatalogItem)
    func cartItemInstantPurchaseSuccess(itemId: String)
    func sendUserInteraction(action: UserInteraction, context: UserInteractionContext)
    func cartItemUserInteraction(itemId: String, action: UserInteraction, context: UserInteractionContext)
    func cartItemInstantPurchaseFailure(itemId: String)
    func cartItemDevicePay(
        catalogItem: CatalogItem,
        paymentProvider: PaymentProvider,
        transactionData: TransactionData?,
        completion: @escaping (_ status: DevicePayStatus) -> Void
    )
    func cartItemDevicePaySuccess(itemId: String, paymentAttemptId: String?)
    func cartItemDevicePayFailure(itemId: String, failureReason: String?, paymentAttemptId: String?)
    func cartItemDevicePayLoadingFailure(itemId: String, failureReason: String?, paymentAttemptId: String?)
    func cartItemDevicePayRetryableFailure(itemId: String, paymentAttemptId: String?)
    func cartItemDevicePayRetry(itemId: String, paymentAttemptId: String?)
    func cartItemDevicePayDetailsOpened(itemId: String, paymentAttemptId: String?)
    func cartItemDevicePayDetailsClosed(itemId: String, paymentAttemptId: String?)
    func cartItemDevicePayPendingConfirmation(
        itemId: String,
        catalogRuntimeData: [String: String],
        paymentAttemptId: String?
    )
    func cartItemForwardPayment(
        catalogItem: CatalogItem,
        transactionData: TransactionData?,
        completion: @escaping (_ status: ForwardPaymentStatus) -> Void
    )
    func cartItemForwardPaymentSuccess(itemId: String)
    func cartItemForwardPaymentFailure(itemId: String, failureReason: String?)
}
