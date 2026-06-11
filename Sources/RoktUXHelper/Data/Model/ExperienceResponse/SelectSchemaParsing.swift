import Foundation
import DcuiSchema

/// Helpers for decoding the v2 selection-response layout-schema fields, which
/// arrive on the wire as JSON **strings** and are parsed into the renderer's
/// typed schema models. This matches the existing v1 pattern in
/// ``LayoutVariantModel`` / `PluginConfig`.
@available(iOS 13, *)
enum SelectSchemaParsing {

    /// Decodes the `outer_layout_schema` field — a JSON string — into the typed
    /// ``OuterLayoutSchemaNetworkModel``. Returns `nil` when the field is absent
    /// or an empty string.
    static func decodeOuterLayoutSchema<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> OuterLayoutSchemaNetworkModel? {
        guard let schemaString = try container.decodeIfPresent(String.self, forKey: key),
              !schemaString.isEmpty,
              let schemaData = schemaString.data(using: .utf8)
        else { return nil }
        return try JSONDecoder().decode(OuterLayoutSchemaNetworkModel.self, from: schemaData)
    }

    /// Decodes the `layout_variant_schema` field — a JSON string — into the typed
    /// `LayoutSchemaModel`. Returns `nil` when the field is absent or an empty
    /// string.
    static func decodeLayoutVariantSchema<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> LayoutSchemaModel? {
        guard let schemaString = try container.decodeIfPresent(String.self, forKey: key),
              !schemaString.isEmpty,
              let schemaData = schemaString.data(using: .utf8)
        else { return nil }
        return try JSONDecoder().decode(LayoutSchemaModel.self, from: schemaData)
    }
}
