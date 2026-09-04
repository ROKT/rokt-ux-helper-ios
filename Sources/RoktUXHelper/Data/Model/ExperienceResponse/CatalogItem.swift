import Foundation

struct CatalogItem: Codable {
    let images: [String: CreativeImage]
    let catalogItemId: String
    let cartItemId: String
    let instanceGuid: String
    let title: String
    let description: String
    let price: Decimal?
    let priceFormatted: String?
    let originalPrice: Decimal?
    let originalPriceFormatted: String?
    let currency: String
    let signalType: String?
    let url: String?
    let minItemCount: Int?
    let maxItemCount: Int?
    let preSelectedQuantity: Int?
    let providerData: String
    let urlBehavior: String?
    let positiveResponseText: String
    let negativeResponseText: String
    let addOns: [String]?
    let copy: [String: String]?
    let inventoryStatus: String?
    let linkedProductId: String?
    let token: String
    let responseOptionsMap: [String: RoktUXResponseOption]?
    let productCartAttribute1: String?
    let productCartAttribute2: String?
    let productSku: String?
    let catalogId: String?

    init(images: [String: CreativeImage],
         catalogItemId: String,
         cartItemId: String,
         instanceGuid: String,
         title: String,
         description: String,
         price: Decimal?,
         priceFormatted: String?,
         originalPrice: Decimal?,
         originalPriceFormatted: String?,
         currency: String,
         signalType: String?,
         url: String?,
         minItemCount: Int?,
         maxItemCount: Int?,
         preSelectedQuantity: Int?,
         providerData: String,
         urlBehavior: String?,
         positiveResponseText: String,
         negativeResponseText: String,
         addOns: [String]?,
         copy: [String: String]?,
         inventoryStatus: String?,
         linkedProductId: String?,
         token: String,
         responseOptionsMap: [String: RoktUXResponseOption]? = nil,
         productCartAttribute1: String? = nil,
         productCartAttribute2: String? = nil,
         productSku: String? = nil,
         catalogId: String? = nil) {
        self.images = images
        self.catalogItemId = catalogItemId
        self.cartItemId = cartItemId
        self.instanceGuid = instanceGuid
        self.title = title
        self.description = description
        self.price = price
        self.priceFormatted = priceFormatted
        self.originalPrice = originalPrice
        self.originalPriceFormatted = originalPriceFormatted
        self.currency = currency
        self.signalType = signalType
        self.url = url
        self.minItemCount = minItemCount
        self.maxItemCount = maxItemCount
        self.preSelectedQuantity = preSelectedQuantity
        self.providerData = providerData
        self.urlBehavior = urlBehavior
        self.positiveResponseText = positiveResponseText
        self.negativeResponseText = negativeResponseText
        self.addOns = addOns
        self.copy = copy
        self.inventoryStatus = inventoryStatus
        self.linkedProductId = linkedProductId
        self.token = token
        self.responseOptionsMap = responseOptionsMap
        self.productCartAttribute1 = productCartAttribute1
        self.productCartAttribute2 = productCartAttribute2
        self.productSku = productSku
        self.catalogId = catalogId
    }
}
