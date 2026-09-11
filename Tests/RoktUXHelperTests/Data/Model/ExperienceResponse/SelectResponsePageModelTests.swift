import XCTest
@testable import RoktUXHelper

/// Verifies ``SelectResponse/getPageModel(useDiagnosticEvents:)`` re-homes the
/// snake_case selection response into the renderer's domain models with no field
/// loss — including catalog, response-option, transaction and catalog-group data
/// that the supplied fixtures don't exercise.
@available(iOS 15, *)
final class SelectResponsePageModelTests: XCTestCase {

    private let decoder = JSONDecoder()

    private func decode(_ json: String) throws -> SelectResponse {
        try decoder.decode(SelectResponse.self, from: Data(json.utf8))
    }

    // MARK: - Full mapping

    func test_getPageModel_mapsFullResponseIntoDomainModels() throws {
        let response = try decode(Self.fullPayload)
        let page = try XCTUnwrap(response.getPageModel(useDiagnosticEvents: true))

        XCTAssertEqual(page.sessionId, "session-1")
        XCTAssertEqual(page.pageId, "page-1")
        XCTAssertEqual(page.pageInstanceGuid, "page-instance-1")
        XCTAssertEqual(page.token, "ctx-token")
        XCTAssertEqual(page.options?.useDiagnosticEvents, true)

        let plugin = try XCTUnwrap(page.layoutPlugins?.first)
        XCTAssertEqual(page.layoutPlugins?.count, 1)
        XCTAssertEqual(plugin.pluginId, "plugin-1")
        XCTAssertEqual(plugin.pluginInstanceGuid, "plugin-instance-1")
        XCTAssertEqual(plugin.pluginName, "Layout")
        XCTAssertEqual(plugin.targetElementSelector, "#target")
        XCTAssertEqual(plugin.pluginConfigJWTToken, "config-token")
        XCTAssertNotNil(plugin.layout)

        let offer = try XCTUnwrap(plugin.slots.first?.offer)
        XCTAssertEqual(offer.campaignId, "campaign-1")
        XCTAssertEqual(offer.creative.referralCreativeId, "creative-1")
        XCTAssertEqual(offer.creative.jwtToken, "creative-token")
        XCTAssertEqual(offer.creative.copy["title"], "Hello")
        XCTAssertEqual(offer.creative.images?["hero"]?.light, "https://example.com/light.png")
        XCTAssertEqual(offer.creative.links?["privacy"]?.url, "https://example.com/privacy")
    }

    func test_getPageModel_bucketsResponseOptionsByIsPositive() throws {
        let response = try decode(Self.fullPayload)
        let page = try XCTUnwrap(response.getPageModel(useDiagnosticEvents: true))
        let options = try XCTUnwrap(page.layoutPlugins?.first?.slots.first?.offer?.creative.responseOptionsMap)

        // Bucketed on `is_positive`, independent of the response map key.
        XCTAssertEqual(options.positive?.id, "ro-pos")
        XCTAssertEqual(options.positive?.action, .url)
        XCTAssertEqual(options.positive?.signalType, .signalResponse)
        XCTAssertEqual(options.positive?.isPositive, true)
        XCTAssertEqual(options.negative?.id, "ro-neg")
        XCTAssertEqual(options.negative?.isPositive, false)
    }

    func test_getPageModel_mapsCatalogItemFields() throws {
        let response = try decode(Self.fullPayload)
        let page = try XCTUnwrap(response.getPageModel(useDiagnosticEvents: true))
        let item = try XCTUnwrap(page.layoutPlugins?.first?.slots.first?.offer?.catalogItems?.first)

        XCTAssertEqual(item.catalogItemId, "cat-1")
        XCTAssertEqual(item.cartItemId, "cart-1")
        XCTAssertEqual(item.title, "Item")
        XCTAssertEqual(item.currency, "USD")
        XCTAssertEqual(item.price, Decimal(string: "14.99"))
        XCTAssertEqual(item.priceFormatted, "$14.99")
        XCTAssertEqual(item.positiveResponseText, "Add to order")
        XCTAssertEqual(item.negativeResponseText, "Dismiss")
        XCTAssertEqual(item.inventoryStatus, "InStock")
        XCTAssertEqual(item.copy?["provider.discountLabel"], "Save 20%")
        XCTAssertEqual(item.images["catalogImage"]?.light, "https://example.com/cat.png")
        XCTAssertEqual(item.providerData, "provider-1")
    }

    func test_getPageModel_mapsTransactionData() throws {
        let response = try decode(Self.fullPayload)
        let page = try XCTUnwrap(response.getPageModel(useDiagnosticEvents: true))
        let txn = try XCTUnwrap(page.layoutPlugins?.first?.slots.first?.offer?.transactionData)

        XCTAssertEqual(txn.paymentType, "CARD")
        XCTAssertEqual(txn.isPartnerManagedPurchase, true)
        XCTAssertEqual(txn.partnerPaymentReference, "ref-1")
        XCTAssertEqual(txn.shippingAddress?.address1, "1 Main St")
        XCTAssertEqual(txn.shippingAddress?.stateCode, "NY")
        XCTAssertEqual(txn.supportedPaymentMethods?.map(\.type), [.card, .applePay])
        XCTAssertEqual(txn.metadata["k"], "v")
    }

    func test_getPageModel_mapsCatalogItemGroup() throws {
        let response = try decode(Self.fullPayload)
        let page = try XCTUnwrap(response.getPageModel(useDiagnosticEvents: true))
        let group = try XCTUnwrap(page.layoutPlugins?.first?.slots.first?.offer?.catalogItemGroup)

        XCTAssertEqual(group.groupId, "group-1")
        XCTAssertEqual(group.catalogItemIds, ["cat-1", "cat-2"])
        XCTAssertEqual(group.attributes?.first?.attributeId, "size")
        XCTAssertEqual(group.attributes?.first?.options?.first?.label, "Small")
    }

    // MARK: - Diagnostic-event flag (SDK vs S2S)

    func test_getPageModel_diagnosticEventsFlagControlsOptions() throws {
        let response = try decode(Self.fullPayload)
        XCTAssertEqual(response.getPageModel(useDiagnosticEvents: true)?.options?.useDiagnosticEvents, true)
        XCTAssertNil(response.getPageModel(useDiagnosticEvents: false)?.options)
    }

    // MARK: - No renderable layout

    func test_getPageModel_returnsNilWhenNoOuterLayout() throws {
        // Valid response, but the plugin config has no outer layout schema.
        let json = """
        {
          "session_id": "s", "session_token": { "token": "t", "expires_at": 0 },
          "plugins": [ { "plugin": { "id": "p", "config": { "instance_guid": "g", "slots": [] } } } ]
        }
        """
        let response = try decode(json)
        XCTAssertNil(response.getPageModel(useDiagnosticEvents: true))
    }

    // MARK: - Fixtures

    /// A minimal valid DCUI outer layout schema (as the wire's escaped JSON string)
    /// so the page-model guard (`layout != nil`) passes.
    private static let outerSchema =
        "{\\\"layout\\\":{\\\"type\\\":\\\"Column\\\",\\\"node\\\":{\\\"children\\\":[]}}}"

    private static let fullPayload = """
    {
      "session_id": "session-1",
      "session_token": { "token": "session-token", "expires_at": 0 },
      "page_instance_guid": "page-instance-1",
      "page_context": { "page_id": "page-1", "page_instance_guid": "page-instance-1", "token": "ctx-token" },
      "plugins": [
        {
          "plugin": {
            "id": "plugin-1",
            "name": "Layout",
            "target_element_selector": "#target",
            "config": {
              "instance_guid": "plugin-instance-1",
              "token": "config-token",
              "outer_layout_schema": "\(outerSchema)",
              "slots": [
                {
                  "instance_guid": "slot-1",
                  "token": "slot-token",
                  "layout_variant": { "layout_variant_id": "v1", "module_name": "m1" },
                  "offer": {
                    "campaign_id": "campaign-1",
                    "creative": {
                      "referral_creative_id": "creative-1",
                      "instance_guid": "creative-instance-1",
                      "token": "creative-token",
                      "copy": { "title": "Hello" },
                      "images": { "hero": { "light": "https://example.com/light.png", "dark": "https://example.com/dark.png" } },
                      "links": { "privacy": { "url": "https://example.com/privacy", "title": "Privacy" } },
                      "response_options_map": {
                        "b_key": { "id": "ro-neg", "is_positive": false, "action": "CaptureOnly", "signal_type": "SignalResponse", "token": "neg-token", "instance_guid": "neg" },
                        "a_key": { "id": "ro-pos", "is_positive": true, "action": "Url", "signal_type": "SignalResponse", "short_label": "Yes", "url": "https://example.com/accept", "token": "pos-token", "instance_guid": "pos" }
                      }
                    },
                    "catalog_items": [
                      {
                        "catalog_item_id": "cat-1", "cart_item_id": "cart-1", "instance_guid": "ci-1",
                        "title": "Item", "description": "Desc", "price": 14.99, "price_formatted": "$14.99",
                        "currency": "USD", "provider_data": "provider-1", "positive_response_text": "Add to order",
                        "negative_response_text": "Dismiss", "inventory_status": "InStock",
                        "copy": { "provider.discountLabel": "Save 20%" },
                        "images": { "catalogImage": { "light": "https://example.com/cat.png" } },
                        "token": "cat-token"
                      }
                    ],
                    "catalog_item_group": {
                      "group_id": "group-1",
                      "catalog_item_ids": ["cat-1", "cat-2"],
                      "attributes": [ { "attribute_id": "size", "label": "Size", "options": [ { "label": "Small", "catalog_item_ids": ["cat-1"] } ] } ]
                    },
                    "transaction_data": {
                      "payment_type": "CARD",
                      "is_partner_managed_purchase": true,
                      "partner_payment_reference": "ref-1",
                      "shipping_address": { "name": "Jane", "address1": "1 Main St", "city": "NYC", "state": "New York", "state_code": "NY", "country": "United States", "country_code": "US", "zip": "10001" },
                      "supported_payment_methods": [ { "type": "CARD" }, { "type": "APPLE_PAY" } ],
                      "metadata": { "k": "v" }
                    }
                  }
                }
              ]
            }
          }
        }
      ]
    }
    """
}
