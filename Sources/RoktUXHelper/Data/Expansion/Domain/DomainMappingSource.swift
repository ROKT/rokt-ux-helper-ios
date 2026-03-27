import Foundation

/// Entities with values that can be used to transform `DomainMappable` properties
protocol DomainMappingSource {}

@available(iOS 13, *)
extension OfferModel: DomainMappingSource {}

@available(iOS 13, *)
extension CatalogItem: DomainMappingSource {}
