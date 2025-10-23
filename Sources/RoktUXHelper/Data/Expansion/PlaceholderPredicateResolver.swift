//
//  PlaceholderPredicateResolver.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

struct PlaceholderResolutionContext {
    let offers: [OfferModel?]
    let currentOfferIndex: Int
    let activeCatalogItem: CatalogItem?
}

@available(iOS 13.0, *)
final class PlaceholderPredicateResolver {

    private let creativeExtractor: CreativeDataExtractor<PlaceholderValidator<DataSanitiser>>
    private let catalogExtractor: CatalogDataExtractor<PlaceholderValidator<DataSanitiser>>
    private let parser: PropertyChainDataParsing

    init(creativeExtractor: CreativeDataExtractor<PlaceholderValidator<DataSanitiser>> = CreativeDataExtractor(),
         catalogExtractor: CatalogDataExtractor<PlaceholderValidator<DataSanitiser>> = CatalogDataExtractor(),
         parser: PropertyChainDataParsing = PropertyChainDataParser()) {
        self.creativeExtractor = creativeExtractor
        self.catalogExtractor = catalogExtractor
        self.parser = parser
    }

    func resolveString(placeholder: String,
                       context: PlaceholderResolutionContext) -> String? {
        do {
            guard let extracted = try extract(placeholder: placeholder, context: context) else { return nil }
            if let stringValue = extracted.value as? String {
                return stringValue
            }
            if let decimalValue = extracted.value as? Decimal {
                return NSDecimalNumber(decimal: decimalValue).stringValue
            }
            if let convertible = extracted.value as? CustomStringConvertible {
                return convertible.description
            }
            return nil
        } catch {
            return nil
        }
    }

    func resolveDecimal(placeholder: String,
                        context: PlaceholderResolutionContext) -> Decimal? {
        do {
            guard let extracted = try extract(placeholder: placeholder, context: context) else { return nil }

            if let decimalValue = extracted.value as? Decimal {
                return decimalValue
            }

            if let stringValue = extracted.value as? String {
                return Decimal(string: stringValue)
            }

            if let intValue = extracted.value as? Int {
                return Decimal(intValue)
            }

            if let number = extracted.value as? NSNumber {
                return number.decimalValue
            }

            return nil
        } catch {
            return nil
        }
    }

    func resolveInt(placeholder: String,
                    context: PlaceholderResolutionContext) -> Int? {
        if let decimal = resolveDecimal(placeholder: placeholder, context: context) {
            return NSDecimalNumber(decimal: decimal).intValue
        }
        return nil
    }

    func resolveTextLength(placeholder: String,
                           context: PlaceholderResolutionContext) -> Int? {
        guard let rawValue = resolveString(placeholder: placeholder, context: context) else { return nil }
        return rawValue.count
    }

    private func extract(placeholder: String,
                         context: PlaceholderResolutionContext) throws -> (value: Any, isState: Bool)? {
        let parsedPlaceholder = parser.parse(propertyChain: placeholder)

        for keyAndNamespace in parsedPlaceholder.parseableChains {
            switch keyAndNamespace.namespace {
            case .dataCreativeCopy, .dataCreativeResponse, .dataCreativeLink, .dataImageCarousel:
                guard let offer = context.offers[safe: context.currentOfferIndex] else { continue }
                let result = try creativeExtractor.extractDataRepresentedBy(String.self,
                                                                            propertyChain: keyAndNamespace.withNamespace,
                                                                            responseKey: nil,
                                                                            from: offer)
            return mapDataBinding(result)
            case .dataCatalogItem:
                if let catalogItem = context.activeCatalogItem {
                    let result = try catalogExtractor.extractDataRepresentedBy(String.self,
                                                                               propertyChain: keyAndNamespace.withNamespace,
                                                                               responseKey: nil,
                                                                               from: catalogItem)
                    return mapDataBinding(result)
                }
            case .state:
                if keyAndNamespace.key == DataBindingStateKeys.indicatorPosition {
                    return (String(context.currentOfferIndex), true)
                }
                if keyAndNamespace.key == DataBindingStateKeys.totalOffers {
                    let total = context.offers.count
                    return (String(total), true)
                }
            }
        }

        if let defaultValue = parsedPlaceholder.defaultValue {
            return (defaultValue, false)
        }

        return nil
    }

    private func mapDataBinding(_ binding: DataBinding<String>) -> (value: Any, isState: Bool) {
        switch binding {
        case .value(let value):
            return (value, false)
        case .state(let value):
            return (value, true)
        }
    }

}

private extension BNFKeyAndNamespace {
    var withNamespace: String {
        namespace.rawValue + BNFSeparator.namespace.rawValue + key
    }
}
