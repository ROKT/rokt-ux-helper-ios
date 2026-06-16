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
    ///
    /// Surfaced only when the wire value is a JSON string. If the backend sends a
    /// non-string (number, bool, or `null`) for this guaranteed field — a server
    /// contract violation — this narrows to `nil`, indistinguishable from the
    /// field being absent. This lossiness is deliberate: decoding never fails on
    /// shape drift. The original, untyped value is always preserved in ``raw``, so
    /// callers needing to observe a wrong-typed value can read ``raw`` directly.
    let instanceGuid: String?
    /// Guaranteed by the backend for every catalog item.
    ///
    /// See ``instanceGuid`` for the non-string narrowing behaviour: a non-string
    /// wire value narrows to `nil` here while the original is retained in ``raw``.
    let title: String?

    /// The complete decoded payload. This is the *full* object, including the
    /// surfaced ``instanceGuid`` / ``title`` keys as well as any campaign-specific
    /// fields — nothing is excluded. Keyed by the raw (snake_case) JSON key.
    ///
    /// Because the guaranteed keys remain here, ``raw`` is the canonical map:
    /// renderers can treat it as the single source for every field, and it also
    /// retains values the typed accessors drop (see ``instanceGuid``).
    let raw: [String: SelectJSONValue]

    private enum CodingKeys: String, CodingKey {
        case instanceGuid = "instance_guid"
        case title
    }

    init(from decoder: Decoder) throws {
        // Decode the whole object once so unknown/campaign-specific fields are
        // preserved, then read the guaranteed fields back out of it. This keeps a
        // single source of truth for the wire keys.
        self.init(raw: try decoder.singleValueContainer().decode([String: SelectJSONValue].self))
    }

    /// Builds an item from an already-decoded JSON object. Used by ``SelectOffer``
    /// when it decodes `catalog_items` as opaque values so it can skip non-object
    /// elements (see ``SelectOffer`` decoding). Reads the guaranteed fields back
    /// out of `raw`, keeping a single source of truth for the wire keys.
    init(raw: [String: SelectJSONValue]) {
        self.raw = raw
        instanceGuid = raw[CodingKeys.instanceGuid.rawValue]?.stringValue
        title = raw[CodingKeys.title.rawValue]?.stringValue
    }
}
