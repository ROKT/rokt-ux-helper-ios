import Foundation

/// A catalog item from a v2 offers selection response.
///
/// The transactions backend does not expose a stable catalog-item schema: the
/// object is open (`additionalProperties: true`) and only `instance_guid` and
/// `title` are guaranteed — every other field varies by campaign type. To stay
/// type-safe without risking decode failures as that shape changes, the
/// guaranteed fields are surfaced as (optional) typed properties while the full
/// payload is retained in ``raw`` so any campaign-specific field still
/// round-trips. Decoding never fails on an unrecognised shape.
///
/// When the renderer starts consuming catalog items, promote the fields it needs
/// from ``raw`` into typed (optional) properties here.
struct SelectCatalogItem: Decodable, Equatable {
    /// Guaranteed by the backend for every catalog item.
    let instanceGuid: String?
    /// Guaranteed by the backend for every catalog item.
    let title: String?

    /// The complete decoded payload, including any campaign-specific fields not
    /// surfaced as typed properties above. Keyed by the raw (snake_case) JSON key.
    let raw: [String: SelectJSONValue]

    private enum CodingKeys: String, CodingKey {
        case instanceGuid = "instance_guid"
        case title
    }

    init(from decoder: Decoder) throws {
        // Decode the whole object once so unknown/campaign-specific fields are
        // preserved, then read the guaranteed fields back out of it. This keeps a
        // single source of truth for the wire keys.
        let raw = try decoder.singleValueContainer().decode([String: SelectJSONValue].self)
        self.raw = raw
        instanceGuid = raw[CodingKeys.instanceGuid.rawValue]?.stringValue
        title = raw[CodingKeys.title.rawValue]?.stringValue
    }
}
