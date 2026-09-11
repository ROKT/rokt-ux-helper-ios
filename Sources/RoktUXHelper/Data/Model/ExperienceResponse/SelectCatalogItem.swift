import Foundation

/// A shoppable catalog item from an offers selection response.
///
/// Unknown fields are ignored. All modelled fields are optional and type-checked;
/// the mapping into the renderer's ``CatalogItem`` supplies defaults for the
/// keys the renderer requires but the response can omit.
struct SelectCatalogItem: Decodable, Equatable {
    let catalogItemId: String?
    let instanceGuid: String?
    let cartItemId: String?
    let title: String?
    let description: String?
    let price: Double?
    let originalPrice: Double?
    let priceFormatted: String?
    let originalPriceFormatted: String?
    let currency: String?
    let url: String?
    let urlBehavior: String?
    let signalType: String?
    let minItemCount: Int?
    let maxItemCount: Int?
    let preSelectedQuantity: Int?
    let providerData: String?
    let linkedProductId: String?
    let quantityMustBeSynchronized: Bool?
    let positiveResponseText: String?
    let negativeResponseText: String?
    let inventoryStatus: String?
    let copy: [String: String]?
    let images: [String: SelectImage]?
    let token: String?
    let responseOptionsMap: [String: SelectResponseOption]?
    let productCartAttribute1: String?
    let productCartAttribute2: String?
    let productSku: String?
    let catalogId: String?

    private enum CodingKeys: String, CodingKey {
        case catalogItemId = "catalog_item_id"
        case instanceGuid = "instance_guid"
        case cartItemId = "cart_item_id"
        case title
        case description
        case price
        case originalPrice = "original_price"
        case priceFormatted = "price_formatted"
        case originalPriceFormatted = "original_price_formatted"
        case currency
        case url
        case urlBehavior = "url_behavior"
        case signalType = "signal_type"
        case minItemCount = "min_item_count"
        case maxItemCount = "max_item_count"
        case preSelectedQuantity = "pre_selected_quantity"
        case providerData = "provider_data"
        case linkedProductId = "linked_product_id"
        case quantityMustBeSynchronized = "quantity_must_be_synchronized"
        case positiveResponseText = "positive_response_text"
        case negativeResponseText = "negative_response_text"
        case inventoryStatus = "inventory_status"
        case copy
        case images
        case token
        case responseOptionsMap = "response_options_map"
        case productCartAttribute1 = "product_cart_attribute1"
        case productCartAttribute2 = "product_cart_attribute2"
        case productSku = "product_sku"
        case catalogId = "catalog_id"
    }
}
