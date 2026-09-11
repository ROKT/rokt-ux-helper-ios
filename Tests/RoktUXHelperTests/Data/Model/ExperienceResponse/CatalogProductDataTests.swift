import XCTest
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogProductDataTests: XCTestCase {
    func test_completePayload_preservesBothCardsAndTheirResponseKeys() throws {
        let slots = try CatalogProductFixture.slots()
        let offer = try XCTUnwrap(slots[1].offer)
        let items = try XCTUnwrap(offer.catalogItems)

        XCTAssertEqual(offer.accountId, "example-product-account")
        XCTAssertEqual(offer.catalogItemResponseAction, "Url")
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.map(\.catalogItemId), ["item:example/product-a", "item:example/product-b"])
        XCTAssertEqual(items.map(\.instanceGuid), ["catalog:example/card-a", "catalog:example/card-b"])
        XCTAssertEqual(items.map(\.productSku), ["example-sku-a", "example-sku-b"])
        XCTAssertEqual(items.map(\.catalogId), ["example-catalog-a", "example-catalog-b"])
        XCTAssertEqual(items.map(\.productCartAttribute1), ["title", "price"])
        XCTAssertEqual(items.map(\.productCartAttribute2), ["price", "title"])
        XCTAssertEqual(items.map(\.token), ["example-item-token-a", "example-item-token-b"])

        let first = items[0]
        XCTAssertEqual(first.title, "Example product A")
        XCTAssertEqual(first.price, Decimal(string: "12.5"))
        XCTAssertEqual(first.originalPriceFormatted, "$15.00")
        XCTAssertEqual(first.copy?["provider.productName"], "Example product A")
        XCTAssertEqual(first.images["catalogItemImage0"]?.light, "https://example.com/a.png")
        XCTAssertEqual(first.url, "https://example.com/item-a")
        XCTAssertEqual(first.urlBehavior, "self")
        XCTAssertEqual(Set(first.responseOptionsMap?.keys.map { $0 } ?? []), ["buy-now", "details"])
        XCTAssertNil(first.responseOptionsMap?["positive"])

        let response = try XCTUnwrap(first.responseOptionsMap?["buy-now"])
        XCTAssertEqual(response.id, "example-response-a")
        XCTAssertEqual(response.instanceGuid, "response:example/card-a/buy")
        XCTAssertEqual(response.responseJWTToken, "example-response-token-a")
        XCTAssertNotEqual(response.responseJWTToken, first.token)
        XCTAssertEqual(response.action, .url)
        XCTAssertEqual(response.signalType, .signalProductItemResponse)
        XCTAssertEqual(response.url, "https://example.com/a?source=card&value=%2F")
        XCTAssertEqual(response.urlBehavior, "newTab")
        XCTAssertEqual(response.ignoreBranch, true)
        XCTAssertEqual(response.shortLabel, "View product A")
        XCTAssertEqual(response.longLabel, "View example product A")
        XCTAssertEqual(response.shortSuccessLabel, "Viewed")
        XCTAssertEqual(first.responseOptionsMap?["details"]?.isPositive, true)
        XCTAssertEqual(first.responseOptionsMap?["details"]?.responseJWTToken, "example-details-token-a")
        XCTAssertEqual(items[1].responseOptionsMap?["positive"]?.instanceGuid, "response:example/card-b/view")
        XCTAssertEqual(items[1].responseOptionsMap?["positive"]?.responseJWTToken, "example-response-token-b")
    }

    func test_creativeResponseMapping_keepsExistingPolarityAndAdditionalURLFields() throws {
        let offer = try XCTUnwrap(CatalogProductFixture.slots()[1].offer)
        let response = try XCTUnwrap(offer.creative.responseOptionsMap?.positive)

        XCTAssertEqual(response.id, "example-creative-response")
        XCTAssertEqual(response.signalType, .signalResponse)
        XCTAssertEqual(response.urlBehavior, "inApp")
        XCTAssertEqual(response.ignoreBranch, false)
        XCTAssertEqual(response.responseJWTToken, "example-creative-response-token")
        XCTAssertNil(offer.creative.responseOptionsMap?.negative)
    }

    func test_optionalCatalogAndOfferFields_canBeMissingOrNull() throws {
        for item in [[:], CatalogProductFixture.optionalItemKeys.reduce(into: [String: Any]()) { $0[$1] = NSNull() }] {
            let offer = try CatalogProductFixture.offer([
                "creative": [:], "catalog_items": [item],
                "account_id": NSNull(), "catalog_item_response_action": NSNull()
            ])
            let catalogItem = try XCTUnwrap(offer.catalogItems?.first)
            XCTAssertNil(offer.accountId)
            XCTAssertNil(offer.catalogItemResponseAction)
            XCTAssertNil(catalogItem.responseOptionsMap)
            XCTAssertNil(catalogItem.productCartAttribute1)
            XCTAssertNil(catalogItem.productCartAttribute2)
            XCTAssertNil(catalogItem.productSku)
            XCTAssertNil(catalogItem.catalogId)
            XCTAssertEqual(catalogItem.token, "")
            XCTAssertEqual(catalogItem.instanceGuid, "")
        }
        let missing = try CatalogProductFixture.offer(["creative": [:]])
        XCTAssertNil(missing.accountId)
        XCTAssertNil(missing.catalogItemResponseAction)
        XCTAssertNil(missing.catalogItems)
    }

    func test_responseMap_distinguishesAbsentEmptyAndIncompleteOptions() throws {
        let offer = try CatalogProductFixture.offer([
            "creative": [:],
            "catalog_items": [[:], ["response_options_map": [:]], ["response_options_map": ["custom-key": [:]]]]
        ])
        let items = try XCTUnwrap(offer.catalogItems)
        XCTAssertNil(items[0].responseOptionsMap)
        XCTAssertEqual(items[1].responseOptionsMap?.count, 0)
        let incomplete = try XCTUnwrap(items[2].responseOptionsMap?["custom-key"])
        XCTAssertEqual(incomplete.id, "")
        XCTAssertEqual(incomplete.instanceGuid, "")
        XCTAssertEqual(incomplete.responseJWTToken, "")
        XCTAssertNil(incomplete.url)
        XCTAssertNil(incomplete.urlBehavior)
        XCTAssertNil(incomplete.ignoreBranch)
        XCTAssertEqual(incomplete.isPositive, false)
    }

    func test_unknownActionAndURLValues_remainForwardCompatible() throws {
        let offer = try CatalogProductFixture.offer([
            "creative": [:], "catalog_item_response_action": "future-action",
            "catalog_items": [["response_options_map": ["custom-key": [
                "action": "future-action", "signal_type": "future-signal", "url_behavior": "future-behavior"
            ]]]]
        ])
        let response = try XCTUnwrap(offer.catalogItems?.first?.responseOptionsMap?["custom-key"])
        XCTAssertEqual(offer.catalogItemResponseAction, "future-action")
        XCTAssertEqual(response.action, .unknown)
        XCTAssertEqual(response.signalType, .unknown)
        XCTAssertEqual(response.urlBehavior, "future-behavior")
    }

    func test_malformedCatalogFields_throwDecodingErrors() throws {
        for key in CatalogProductFixture.optionalItemKeys {
            let json = try JSONSerialization.data(withJSONObject: [key: 7])
            XCTAssertThrowsError(try JSONDecoder().decode(SelectCatalogItem.self, from: json), key) {
                XCTAssertTrue($0 is DecodingError)
            }
        }
        for key in ["url_behavior", "ignore_branch", "instance_guid", "token"] {
            let json = try JSONSerialization.data(withJSONObject: ["response_options_map": ["positive": [key: []]]])
            XCTAssertThrowsError(try JSONDecoder().decode(SelectCatalogItem.self, from: json), key) {
                XCTAssertTrue($0 is DecodingError)
            }
        }
    }

    func test_malformedOfferFields_throwDecodingErrors() throws {
        for key in ["account_id", "catalog_item_response_action"] {
            let json = try JSONSerialization.data(withJSONObject: [key: 7])
            XCTAssertThrowsError(try JSONDecoder().decode(SelectOffer.self, from: json), key) {
                XCTAssertTrue($0 is DecodingError)
            }
        }
    }

    func test_domainCodableRoundTrip_preservesCatalogResponseData() throws {
        let original = try XCTUnwrap(CatalogProductFixture.slots()[1].offer)
        let decoded = try JSONDecoder().decode(OfferModel.self, from: JSONEncoder().encode(original))

        XCTAssertEqual(decoded.accountId, original.accountId)
        XCTAssertEqual(decoded.catalogItemResponseAction, original.catalogItemResponseAction)
        XCTAssertEqual(decoded.catalogItems?.first?.responseOptionsMap, original.catalogItems?.first?.responseOptionsMap)
        XCTAssertEqual(decoded.catalogItems?.last?.productCartAttribute2, "title")
    }

    func test_existingPurchaseData_mapsWithoutProductResponseFields() throws {
        let offer = try CatalogProductFixture.offer([
            "creative": [:],
            "catalog_items": [[
                "cart_item_id": "example-cart", "catalog_item_id": "example-purchase-item",
                "price": 10.5, "original_price": 12, "currency": "USD",
                "min_item_count": 1, "max_item_count": 3, "pre_selected_quantity": 2,
                "provider_data": "example-provider-data", "linked_product_id": "example-linked-item",
                "positive_response_text": "Add", "negative_response_text": "Dismiss",
                "url": "https://example.com/purchase", "url_behavior": "inApp", "token": "example-purchase-token"
            ]],
            "transaction_data": [
                "is_partner_managed_purchase": true, "payment_type": "CARD",
                "partner_payment_reference": "example-payment-reference",
                "supported_payment_methods": [["type": "CARD"]]
            ]
        ])
        let item = try XCTUnwrap(offer.catalogItems?.first)
        XCTAssertEqual(item.cartItemId, "example-cart")
        XCTAssertEqual(item.price, Decimal(string: "10.5"))
        XCTAssertEqual(item.originalPrice, 12)
        XCTAssertEqual(item.minItemCount, 1)
        XCTAssertEqual(item.maxItemCount, 3)
        XCTAssertEqual(item.preSelectedQuantity, 2)
        XCTAssertEqual(item.providerData, "example-provider-data")
        XCTAssertEqual(item.linkedProductId, "example-linked-item")
        XCTAssertEqual(item.positiveResponseText, "Add")
        XCTAssertEqual(item.negativeResponseText, "Dismiss")
        XCTAssertEqual(item.urlBehavior, "inApp")
        XCTAssertEqual(item.token, "example-purchase-token")
        XCTAssertNil(item.responseOptionsMap)
        XCTAssertEqual(offer.transactionData?.isPartnerManagedPurchase, true)
        XCTAssertEqual(offer.transactionData?.partnerPaymentReference, "example-payment-reference")
        XCTAssertEqual(offer.transactionData?.supportedPaymentMethods?.first?.type, .card)
    }
}

@available(iOS 15, *)
enum CatalogProductFixture {
    static let optionalItemKeys = [
        "response_options_map", "product_cart_attribute1", "product_cart_attribute2", "product_sku", "catalog_id"
    ]

    static func slots() throws -> [SlotModel] {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "catalog_product_data", withExtension: "json"))
        let response = try JSONDecoder().decode(SelectResponse.self, from: Data(contentsOf: url))
        return try XCTUnwrap(response.getPageModel(useDiagnosticEvents: false)?.layoutPlugins?.first?.slots)
    }

    static func offer(_ offer: [String: Any]) throws -> OfferModel {
        let outerSchema = #"{"layout":{"type":"Column","node":{"children":[]}}}"#
        let payload: [String: Any] = [
            "session_id": "example-session",
            "session_token": ["token": "example-token", "expires_at": 0],
            "plugins": [["plugin": ["config": [
                "outer_layout_schema": outerSchema, "slots": [["offer": offer]]
            ]]]]
        ]
        let response = try JSONDecoder().decode(SelectResponse.self, from: JSONSerialization.data(withJSONObject: payload))
        return try XCTUnwrap(response.getPageModel(useDiagnosticEvents: false)?.layoutPlugins?.first?.slots.first?.offer)
    }
}
