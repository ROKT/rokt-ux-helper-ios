import Foundation

/// A minimal opaque JSON value, used for selection-response fields the
/// renderer does not (yet) consume in a typed way — the campaign-specific
/// portion of a ``SelectCatalogItem`` (``SelectCatalogItem/raw``) and the
/// per-entity `event_data.events` payloads. It round-trips arbitrary JSON
/// without imposing a schema.
enum SelectJSONValue: Decodable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: SelectJSONValue])
    case array([SelectJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([SelectJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: SelectJSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value in selection response"
            )
        }
    }
}

extension SelectJSONValue {
    /// Convenience accessor for the value at a key when this is a JSON object.
    subscript(key: String) -> SelectJSONValue? {
        guard case let .object(dictionary) = self else { return nil }
        return dictionary[key]
    }

    /// The underlying string when this value is a `.string`, otherwise `nil`.
    var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }
}
