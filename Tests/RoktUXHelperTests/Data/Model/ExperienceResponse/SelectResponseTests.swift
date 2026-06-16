import XCTest
@testable import RoktUXHelper

// Matches the `@available(iOS 13, *)` gate on the models under test (SelectResponse
// and friends). The SPM package minimum is iOS 15, so this gate never actually
// excludes a supported run; it is aligned to the code under test rather than left
// stricter than the symbols it exercises.
@available(iOS 13, *)
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
        let catalogItem = try XCTUnwrap(offer.catalogItems?.first)
        XCTAssertEqual(catalogItem.instanceGuid, "catalog-instance-1")
        XCTAssertEqual(catalogItem.title, "Catalog title")
        // Campaign-specific fields are not surfaced as typed properties but remain
        // available via `raw`. NOTE: `SelectJSONValue` models every JSON number as
        // `.number(Double)`, so both fractional and integer literals land in the same
        // case — `9.99` and (elsewhere) `7` are both `.number`. If an `.int` case is
        // ever added to `SelectJSONValue`, integer literals would decode differently
        // and these `.number` expectations would need revisiting. The helper below
        // makes that assumption explicit instead of hard-coding `.number(...)`.
        assertNumber(catalogItem.raw["price"], equals: 9.99)
        XCTAssertEqual(catalogItem.raw["custom_field"]?.stringValue, "varies-by-campaign")

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

    func test_catalog_item_decodes_when_guaranteed_fields_are_absent() throws {
        // The catalog-item schema is open and campaign-specific; only `instance_guid`
        // and `title` are guaranteed. Decoding must not fail when they are absent —
        // the guaranteed properties are nil and the payload is retained in `raw`.
        let json = """
        { "campaign_only_field": 7, "nested": { "k": "v" } }
        """.data(using: .utf8)!

        let catalogItem = try decoder.decode(SelectCatalogItem.self, from: json)

        XCTAssertNil(catalogItem.instanceGuid)
        XCTAssertNil(catalogItem.title)
        XCTAssertEqual(catalogItem.raw["campaign_only_field"], .number(7))
        XCTAssertEqual(catalogItem.raw["nested"], .object(["k": .string("v")]))
    }

    func test_catalog_item_narrows_non_string_guaranteed_field_to_nil_but_retains_it_in_raw() throws {
        // A guaranteed field arriving as a non-string is a server contract violation.
        // Decoding deliberately tolerates it: the typed property narrows to nil (the
        // narrowing is lossy and pinned here on purpose), while the original value is
        // always preserved untyped in `raw`.
        let json = """
        { "instance_guid": 12345, "title": true }
        """.data(using: .utf8)!

        let catalogItem = try decoder.decode(SelectCatalogItem.self, from: json)

        XCTAssertNil(catalogItem.instanceGuid)
        XCTAssertNil(catalogItem.title)
        assertNumber(catalogItem.raw["instance_guid"], equals: 12345)
        XCTAssertEqual(catalogItem.raw["title"], .bool(true))
    }

    func test_offer_skips_non_object_catalog_items_without_failing_the_decode() throws {
        // `catalog_items` is open; a non-object element (string, number, null, array)
        // must not fail the whole response decode. Only object-shaped elements become
        // typed items; everything else is skipped.
        let json = """
        {
          "campaign_id": "campaign-x",
          "catalog_items": [
            { "instance_guid": "keep-1", "title": "Kept" },
            "bare-string",
            42,
            null,
            ["nested", "array"],
            { "instance_guid": "keep-2" }
          ]
        }
        """.data(using: .utf8)!

        let offer = try decoder.decode(SelectOffer.self, from: json)

        XCTAssertEqual(offer.catalogItems?.count, 2)
        XCTAssertEqual(offer.catalogItems?.map(\.instanceGuid), ["keep-1", "keep-2"])
    }

    func test_offer_distinguishes_empty_catalog_items_array_from_absent_field() throws {
        let absent = """
        { "campaign_id": "campaign-absent" }
        """.data(using: .utf8)!
        let empty = """
        { "campaign_id": "campaign-empty", "catalog_items": [] }
        """.data(using: .utf8)!

        let absentOffer = try decoder.decode(SelectOffer.self, from: absent)
        let emptyOffer = try decoder.decode(SelectOffer.self, from: empty)

        // Absent key → nil; present-but-empty array → empty (non-nil) collection.
        XCTAssertNil(absentOffer.catalogItems)
        XCTAssertEqual(emptyOffer.catalogItems?.count, 0)
    }

    // MARK: - Helpers

    /// Asserts a `SelectJSONValue` is a number equal to `expected`.
    ///
    /// `SelectJSONValue` models every JSON number as `.number(Double)`, so both
    /// integer and fractional literals land in the same case. This helper makes that
    /// assumption explicit at the call site rather than hard-coding `.number(...)`,
    /// so that if an `.int` case is ever added the failure points here.
    private func assertNumber(_ value: SelectJSONValue?,
                              equals expected: Double,
                              file: StaticString = #filePath,
                              line: UInt = #line) {
        guard case let .number(actual) = value else {
            XCTFail("Expected .number(\(expected)) but got \(String(describing: value))",
                    file: file, line: line)
            return
        }
        XCTAssertEqual(actual, expected, accuracy: 0.000_001, file: file, line: line)
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
                    "catalog_items": [ { "instance_guid": "catalog-instance-1", "title": "Catalog title", "price": 9.99, "custom_field": "varies-by-campaign" } ],
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
