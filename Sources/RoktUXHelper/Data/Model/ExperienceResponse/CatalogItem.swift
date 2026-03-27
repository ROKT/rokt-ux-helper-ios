import Foundation

struct CatalogItem: Codable {
    let images: [String: CreativeImage]
    let catalogItemId: String
    let cartItemId: String
    let instanceGuid: String
    let title: String
    let description: String
    let price: Decimal?
    let originalPrice: Decimal?
    let originalPriceFormatted: String?
    let currency: String
    let linkedProductId: String?
    let positiveResponseText: String
    let negativeResponseText: String
    let providerData: String
    let token: String
}
