import Foundation

/// A catalog item from an offers selection response.
///
/// Only `instance_guid` and `title` are part of the agreed contract, so they are
/// the only fields modelled here. Both are optional; campaign-specific fields are
/// intentionally not surfaced. As the renderer starts consuming catalog items,
/// add the fields it needs as typed (optional) properties here.
struct SelectCatalogItem: Decodable, Equatable {
    let instanceGuid: String?
    let title: String?

    private enum CodingKeys: String, CodingKey {
        case instanceGuid = "instance_guid"
        case title
    }
}
