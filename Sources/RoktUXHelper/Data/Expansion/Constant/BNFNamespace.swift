import Foundation

enum BNFNamespace: String, CaseIterable {

    // MARK: Creative

    case dataCreativeCopy = "DATA.creativeCopy"
    case dataCreativeResponse = "DATA.creativeResponse"
    case dataCreativeLink = "DATA.creativeLink"
    case dataImageCarousel = "DATA.creativeImage"

    case state = "STATE"

    var withNamespaceSeparator: String { self.rawValue + BNFSeparator.namespace.rawValue }

    enum CreativeResponseKey: String {
        case positive
        case negative
    }

    // MARK: Catalog Item

    case dataCatalogItem = "DATA.catalogItem"
}
