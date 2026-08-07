import Foundation
import DcuiSchema

/// Selection response for a `v2/sessions/offers` request — the single canonical,
/// helper-owned response model the renderer consumes.
///
/// The layout-schema fields arrive on the wire as JSON **strings** and are parsed
/// into the renderer's typed ``OuterLayoutSchemaNetworkModel`` / `LayoutSchemaModel`
/// during decode (see ``SelectSchemaParsing``). ``getPageModel()`` maps this tree
/// into the renderer's ``RoktUXPageModel`` / ``LayoutPlugin`` domain models.
///
/// Only the fields the renderer, events, catalog, payments and the Rokt SDK
/// consume are typed; any other keys on the wire are ignored.
///
/// > Important: `public` only so the Rokt SDK can read `sessionToken` / `eventData`
/// > off ``RoktUXParseResult/response``. Not a supported public integration type.
@available(iOS 13, *)
public struct SelectResponse: Decodable {
    public let sessionId: String
    public let sessionToken: SessionToken
    public let pageInstanceGuid: String
    let pageContext: SelectPageContext?
    let plugins: [SelectPlugin]?
    public let eventData: [String: SelectEventDataEntry]?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case sessionToken = "session_token"
        case pageInstanceGuid = "page_instance_guid"
        case pageContext = "page_context"
        case plugins
        case eventData = "event_data"
    }

    public init(from decoder: Decoder) throws {
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
public struct SessionToken: Decodable {
    public let token: String
    public let expiresAt: Int64

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
    let catalogItemGroup: SelectCatalogItemGroup?
    let transactionData: SelectTransactionData?

    enum CodingKeys: String, CodingKey {
        case campaignId = "campaign_id"
        case creative
        case catalogItems = "catalog_items"
        case catalogItemGroup = "catalog_item_group"
        case transactionData = "transaction_data"
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

struct SelectImage: Decodable, Equatable {
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

/// A group of catalog items with selectable attributes (e.g. size / colour).
/// Mirrors the backend `catalog_item_group`; maps to the renderer's ``CatalogItemGroup``.
struct SelectCatalogItemGroup: Decodable {
    let groupId: String?
    let catalogItemIds: [String]?
    let attributes: [SelectCatalogItemGroupAttribute]?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case catalogItemIds = "catalog_item_ids"
        case attributes
        case metadata
    }
}

struct SelectCatalogItemGroupAttribute: Decodable {
    let attributeId: String?
    let label: String?
    let options: [SelectCatalogItemGroupOption]?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case attributeId = "attribute_id"
        case label
        case options
        case metadata
    }
}

struct SelectCatalogItemGroupOption: Decodable {
    let label: String?
    let catalogItemIds: [String]?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case label
        case catalogItemIds = "catalog_item_ids"
        case metadata
    }
}

/// Partner-supplied transaction context on an offer (billing / shipping /
/// supported payment methods). Mirrors the backend `transaction_data`; maps to
/// the renderer's ``TransactionData``.
struct SelectTransactionData: Decodable {
    let shippingAddress: SelectAddress?
    let billingAddress: SelectAddress?
    let paymentType: String?
    let supportedPaymentMethods: [SelectPaymentMethod]?
    let isPartnerManagedPurchase: Bool?
    let partnerPaymentReference: String?
    let confirmationRef: String?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case shippingAddress = "shipping_address"
        case billingAddress = "billing_address"
        case paymentType = "payment_type"
        case supportedPaymentMethods = "supported_payment_methods"
        case isPartnerManagedPurchase = "is_partner_managed_purchase"
        case partnerPaymentReference = "partner_payment_reference"
        case confirmationRef = "confirmation_ref"
        case metadata
    }
}

struct SelectAddress: Decodable {
    let name: String?
    let address1: String?
    let address2: String?
    let city: String?
    let state: String?
    let stateCode: String?
    let country: String?
    let countryCode: String?
    let zip: String?

    enum CodingKeys: String, CodingKey {
        case name
        case address1
        case address2
        case city
        case state
        case stateCode = "state_code"
        case country
        case countryCode = "country_code"
        case zip
    }
}

struct SelectPaymentMethod: Decodable {
    let type: String?
}

/// Token lookup for a trackable entity, echoed back on events. Exposed so the
/// Rokt SDK can forward real-time events from ``RoktUXParseResult/response``.
public struct SelectEventDataEntry: Decodable {
    public let token: String
    public let events: [String: SelectRealTimeEvent]?
}

/// A pre-serialized real-time event payload, keyed by signal type.
public struct SelectRealTimeEvent: Decodable {
    public let eventType: String?
    public let payload: String?

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case payload
    }
}
