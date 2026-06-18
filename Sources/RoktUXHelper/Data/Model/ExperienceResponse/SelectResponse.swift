import Foundation
import DcuiSchema

/// Selection response for an offers request — the model the renderer consumes,
/// alongside ``RoktUXExperienceResponse``. The layout-schema fields are
/// parsed into the renderer's typed ``OuterLayoutSchemaNetworkModel`` /
/// `LayoutSchemaModel` (the SDK-side wire model keeps the same fields as raw
/// strings instead).
///
/// It is response-side only and not yet wired into rendering.
@available(iOS 13, *)
struct SelectResponse: Decodable {
    let sessionId: String
    let sessionToken: SessionToken
    let pageInstanceGuid: String
    let pageContext: SelectPageContext?
    let plugins: [SelectPlugin]?
    let eventData: [String: SelectEventDataEntry]?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case sessionToken = "session_token"
        case pageInstanceGuid = "page_instance_guid"
        case pageContext = "page_context"
        case plugins
        case eventData = "event_data"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        sessionToken = try container.decode(SessionToken.self, forKey: .sessionToken)
        // Defaults to an empty string when the key is absent.
        pageInstanceGuid = try container.decodeIfPresent(String.self, forKey: .pageInstanceGuid) ?? ""
        pageContext = try container.decodeIfPresent(SelectPageContext.self, forKey: .pageContext)
        plugins = try container.decodeIfPresent([SelectPlugin].self, forKey: .plugins)
        eventData = try container.decodeIfPresent([String: SelectEventDataEntry].self, forKey: .eventData)
    }
}

/// The session token is treated as **opaque** — only the raw token string and its
/// expiry are modelled. The JWT is deliberately NOT decoded here.
struct SessionToken: Decodable {
    let token: String
    let expiresAt: Int64

    enum CodingKeys: String, CodingKey {
        case token
        case expiresAt = "expires_at"
    }
}

struct SelectPageContext: Decodable {
    let roktTagId: String?
    let pageInstanceGuid: String?
    let pageId: String?
    let pageType: String?
    let language: String?
    let isPageDetected: Bool?
    let pageVariantName: String?
    let partnerContentTemplate: String?
    let token: String?

    enum CodingKeys: String, CodingKey {
        case roktTagId = "rokt_tag_id"
        case pageInstanceGuid = "page_instance_guid"
        case pageId = "page_id"
        case pageType = "page_type"
        case language
        case isPageDetected = "is_page_detected"
        case pageVariantName = "page_variant_name"
        case partnerContentTemplate = "partner_content_template"
        case token
    }
}

/// Each plugin object has a single key, `plugin`, whose value is the layout.
struct SelectPlugin: Decodable {
    let plugin: SelectPluginLayout?
}

struct SelectPluginLayout: Decodable {
    let id: String?
    let name: String?
    let targetElementSelector: String?
    let config: SelectPluginConfig?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case targetElementSelector = "target_element_selector"
        case config
    }
}

@available(iOS 13, *)
struct SelectPluginConfig: Decodable {
    let slots: [SelectSlot]
    let instanceGuid: String?
    /// Parsed from the `outer_layout_schema` JSON string into the renderer's typed
    /// schema model. Nullable.
    let outerLayoutSchema: OuterLayoutSchemaNetworkModel?
    let token: String?

    enum CodingKeys: String, CodingKey {
        case slots
        case instanceGuid = "instance_guid"
        case outerLayoutSchema = "outer_layout_schema"
        case token
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Defaults `slots` to an empty list when the key is absent.
        slots = try container.decodeIfPresent([SelectSlot].self, forKey: .slots) ?? []
        instanceGuid = try container.decodeIfPresent(String.self, forKey: .instanceGuid)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        outerLayoutSchema = try SelectSchemaParsing.decodeOuterLayoutSchema(from: container,
                                                                            forKey: .outerLayoutSchema)
    }
}

@available(iOS 13, *)
struct SelectSlot: Decodable {
    let instanceGuid: String?
    let layoutVariant: SelectLayoutVariant?
    let offer: SelectOffer?
    let token: String?

    enum CodingKeys: String, CodingKey {
        case instanceGuid = "instance_guid"
        case layoutVariant = "layout_variant"
        case offer
        case token
    }
}

@available(iOS 13, *)
struct SelectLayoutVariant: Decodable {
    let layoutVariantId: String?
    let moduleName: String?
    /// Parsed from the `layout_variant_schema` JSON string into the renderer's
    /// typed `LayoutSchemaModel`. Nullable.
    let layoutVariantSchema: LayoutSchemaModel?

    enum CodingKeys: String, CodingKey {
        case layoutVariantId = "layout_variant_id"
        case moduleName = "module_name"
        case layoutVariantSchema = "layout_variant_schema"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        layoutVariantId = try container.decodeIfPresent(String.self, forKey: .layoutVariantId)
        moduleName = try container.decodeIfPresent(String.self, forKey: .moduleName)
        layoutVariantSchema = try SelectSchemaParsing.decodeLayoutVariantSchema(from: container,
                                                                                forKey: .layoutVariantSchema)
    }
}

struct SelectOffer: Decodable {
    let campaignId: String?
    let creative: SelectCreative?
    let catalogItems: [SelectCatalogItem]?

    enum CodingKeys: String, CodingKey {
        case campaignId = "campaign_id"
        case creative
        case catalogItems = "catalog_items"
    }
}

struct SelectCreative: Decodable {
    let referralCreativeId: String?
    let instanceGuid: String?
    let token: String?
    let responseOptionsMap: [String: SelectResponseOption]?
    let copy: [String: String]?
    let images: [String: SelectImage]?
    let links: [String: SelectLink]?
    let icons: [String: SelectIcon]?

    enum CodingKeys: String, CodingKey {
        case referralCreativeId = "referral_creative_id"
        case instanceGuid = "instance_guid"
        case token
        case responseOptionsMap = "response_options_map"
        case copy
        case images
        case links
        case icons
    }
}

struct SelectResponseOption: Decodable {
    let id: String?
    let action: String?
    let instanceGuid: String?
    let token: String?
    let signalType: String?
    let shortLabel: String?
    let longLabel: String?
    let shortSuccessLabel: String?
    let isPositive: Bool
    let url: String?
    let ignoreBranch: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case action
        case instanceGuid = "instance_guid"
        case token
        case signalType = "signal_type"
        case shortLabel = "short_label"
        case longLabel = "long_label"
        case shortSuccessLabel = "short_success_label"
        case isPositive = "is_positive"
        case url
        case ignoreBranch = "ignore_branch"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        action = try container.decodeIfPresent(String.self, forKey: .action)
        instanceGuid = try container.decodeIfPresent(String.self, forKey: .instanceGuid)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        signalType = try container.decodeIfPresent(String.self, forKey: .signalType)
        shortLabel = try container.decodeIfPresent(String.self, forKey: .shortLabel)
        longLabel = try container.decodeIfPresent(String.self, forKey: .longLabel)
        shortSuccessLabel = try container.decodeIfPresent(String.self, forKey: .shortSuccessLabel)
        // Defaults `is_positive` to false when absent.
        isPositive = try container.decodeIfPresent(Bool.self, forKey: .isPositive) ?? false
        url = try container.decodeIfPresent(String.self, forKey: .url)
        ignoreBranch = try container.decodeIfPresent(Bool.self, forKey: .ignoreBranch)
    }
}

struct SelectImage: Decodable {
    let light: String?
    let dark: String?
    let alt: String?
    let title: String?
}

struct SelectLink: Decodable {
    let url: String?
    let title: String?
}

struct SelectIcon: Decodable {
    let name: String?
}

struct SelectEventDataEntry: Decodable {
    let token: String
    /// Opaque per-event payloads.
    let events: [String: SelectJSONValue]?
}
