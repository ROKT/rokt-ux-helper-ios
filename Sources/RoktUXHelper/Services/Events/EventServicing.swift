import Foundation

protocol EventServicing: AnyObject {
    var dismissOption: LayoutDismissOptions? { get set }
    func sendSignalLoadStartEvent()
    func sendEventsOnTransformerSuccess()
    func sendSignalActivationEvent()
    func sendEventsOnLoad()
    func sendSlotImpressionEvent(instanceGuid: String, jwtToken: String)
    func sendSignalViewedEvent(instanceGuid: String, jwtToken: String)
    func sendSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool)
    func sendGatedSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool)
    func sendDismissalEvent()
    func openURL(url: URL, type: RoktUXOpenURLType, completionHandler: @escaping () -> Void)
    func cartItemInstantPurchase(catalogItem: CatalogItem)
    func cartItemInstantPurchaseSuccess(itemId: String)
    func cartItemInstantPurchaseFailure(itemId: String)
}
