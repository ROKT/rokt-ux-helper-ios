import XCTest
@testable import RoktUXHelper

@available(iOS 15, *)
final class SelectResponseTests: XCTestCase {

    private let decoder = JSONDecoder()

    func test_decodes_a_fully_populated_selection_response() throws {
        let response = try decoder.decode(SelectResponse.self, from: Self.fullPayload)

        XCTAssertEqual(response.sessionId, "session-1")
        XCTAssertEqual(response.sessionToken.token, "token-1")
        XCTAssertEqual(response.sessionToken.expiresAt, 1_711_038_600_000)
        XCTAssertEqual(response.pageInstanceGuid, "page-instance-1")
        XCTAssertEqual(response.pageContext?.pageId, "page-1")
        XCTAssertEqual(response.pageContext?.language, "en")

        let plugin = try XCTUnwrap(response.plugins?.first?.plugin)
        XCTAssertEqual(plugin.id, "plugin-1")
        XCTAssertEqual(plugin.name, "Layout")
        XCTAssertEqual(plugin.targetElementSelector, "#target")

        let config = try XCTUnwrap(plugin.config)
        XCTAssertEqual(config.instanceGuid, "plugin-instance-1")
        // Typed layout schemas are parsed by the renderer's schema models (covered by
        // the render-model tests); this fixture omits them, so they decode as nil.
        XCTAssertNil(config.outerLayoutSchema)

        let slot = try XCTUnwrap(config.slots.first)
        XCTAssertEqual(slot.instanceGuid, "slot-1")
        XCTAssertEqual(slot.layoutVariant?.layoutVariantId, "variant-1")
        XCTAssertEqual(slot.layoutVariant?.moduleName, "module-1")
        XCTAssertNil(slot.layoutVariant?.layoutVariantSchema)

        let offer = try XCTUnwrap(slot.offer)
        XCTAssertEqual(offer.campaignId, "campaign-1")
        XCTAssertEqual(offer.catalogItems?.count, 1)
        XCTAssertEqual(offer.catalogItems?.first?["id"]?.stringValue, "catalog-1")

        let creative = try XCTUnwrap(offer.creative)
        XCTAssertEqual(creative.referralCreativeId, "creative-1")
        XCTAssertEqual(creative.copy?["title"], "Hello")
        XCTAssertEqual(creative.images?["hero"]?.light, "https://example.com/light.png")
        XCTAssertEqual(creative.images?["hero"]?.dark, "https://example.com/dark.png")
        XCTAssertEqual(creative.links?["privacy"]?.url, "https://example.com/privacy")
        XCTAssertEqual(creative.icons?["close"]?.name, "close")

        let responseOption = try XCTUnwrap(creative.responseOptionsMap?["positive"])
        XCTAssertEqual(responseOption.action, "url")
        XCTAssertEqual(responseOption.signalType, "signal-response")
        XCTAssertEqual(responseOption.shortLabel, "Yes")
        XCTAssertEqual(responseOption.longLabel, "Yes please")
        XCTAssertEqual(responseOption.shortSuccessLabel, "Done")
        XCTAssertTrue(responseOption.isPositive)
        XCTAssertEqual(responseOption.ignoreBranch, false)

        XCTAssertEqual(response.eventData?["entity-1"]?.token, "event-token")
    }

    func test_applies_defaults_and_nulls_when_optional_fields_are_omitted() throws {
        let response = try decoder.decode(SelectResponse.self, from: Self.minimalPayload)

        XCTAssertEqual(response.sessionId, "session-2")
        XCTAssertEqual(response.pageInstanceGuid, "")
        XCTAssertNil(response.pageContext)
        XCTAssertNil(response.plugins)
        XCTAssertNil(response.eventData)
    }

    func test_is_positive_defaults_to_false_when_omitted() throws {
        let json = """
        { "id": "ro-x", "action": "url" }
        """.data(using: .utf8)!

        let responseOption = try decoder.decode(SelectResponseOption.self, from: json)

        XCTAssertFalse(responseOption.isPositive)
        XCTAssertNil(responseOption.ignoreBranch)
    }

    // MARK: - Fixtures

    private static let fullPayload = """
    {
      "session_id": "session-1",
      "session_token": { "token": "token-1", "expires_at": 1711038600000 },
      "page_instance_guid": "page-instance-1",
      "page_context": { "page_instance_guid": "page-instance-1", "page_id": "page-1", "language": "en", "token": "ctx-token" },
      "plugins": [
        {
          "plugin": {
            "id": "plugin-1",
            "name": "Layout",
            "target_element_selector": "#target",
            "config": {
              "instance_guid": "plugin-instance-1",
              "token": "config-token",
              "slots": [
                {
                  "instance_guid": "slot-1",
                  "token": "slot-token",
                  "layout_variant": { "layout_variant_id": "variant-1", "module_name": "module-1" },
                  "offer": {
                    "campaign_id": "campaign-1",
                    "catalog_items": [ { "id": "catalog-1" } ],
                    "creative": {
                      "referral_creative_id": "creative-1",
                      "instance_guid": "creative-instance-1",
                      "token": "creative-token",
                      "copy": { "title": "Hello" },
                      "images": { "hero": { "light": "https://example.com/light.png", "dark": "https://example.com/dark.png", "alt": "alt", "title": "title" } },
                      "links": { "privacy": { "url": "https://example.com/privacy", "title": "Privacy" } },
                      "icons": { "close": { "name": "close" } },
                      "response_options_map": {
                        "positive": {
                          "id": "ro-1",
                          "action": "url",
                          "instance_guid": "ro-instance-1",
                          "token": "ro-token",
                          "signal_type": "signal-response",
                          "short_label": "Yes",
                          "long_label": "Yes please",
                          "short_success_label": "Done",
                          "is_positive": true,
                          "url": "https://example.com/accept",
                          "ignore_branch": false
                        }
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      ],
      "event_data": { "entity-1": { "token": "event-token", "events": { "impression": {} } } }
    }
    """.data(using: .utf8)!

    private static let minimalPayload = """
    { "session_id": "session-2", "session_token": { "token": "token-2", "expires_at": 0 } }
    """.data(using: .utf8)!
}
