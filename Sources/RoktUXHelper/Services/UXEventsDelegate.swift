import Foundation

protocol UXEventsDelegate: AnyObject {
    func onOfferEngagement(_ layoutId: String)
    func onPositiveEngagement(_ layoutId: String)
    func onPlacementInteractive(_ layoutId: String)
    func onPlacementReady(_ layoutId: String)
    func onPlacementClosed(_ layoutId: String)
    func onPlacementCompleted(_ layoutId: String)
    func onPlacementFailure(_ layoutId: String)
    func onFirstPositiveEngagement(
        sessionId: String,
        pluginInstanceGuid: String,
        jwtToken: String,
        layoutId: String
    )
    func openURL(url: String,
                 id: String,
                 layoutId: String,
                 type: RoktUXOpenURLType,
                 onClose: @escaping (String) -> Void,
                 onError: @escaping (String, Error?) -> Void)

    func onCartItemInstantPurchase(_ layoutId: String, catalogItem: CatalogItem)
}
