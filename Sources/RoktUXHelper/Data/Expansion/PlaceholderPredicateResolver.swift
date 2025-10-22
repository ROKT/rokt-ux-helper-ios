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
            return try extract(placeholder: placeholder, context: context)?.value
        } catch {
            return nil
        }
    }

    func resolveInt(placeholder: String,
                    context: PlaceholderResolutionContext) -> Int? {
        guard let rawValue = resolveString(placeholder: placeholder, context: context) else { return nil }
        return Int(rawValue)
    }

    func resolveTextLength(placeholder: String,
                           context: PlaceholderResolutionContext) -> Int? {
        guard let rawValue = resolveString(placeholder: placeholder, context: context) else { return nil }
        return rawValue.count
    }

    private func extract(placeholder: String,
                         context: PlaceholderResolutionContext) throws -> (value: String, isState: Bool)? {
        let parsedPlaceholder = parser.parse(propertyChain: placeholder)

        for keyAndNamespace in parsedPlaceholder.parseableChains {
            switch keyAndNamespace.namespace {
            case .dataCreativeCopy, .dataCreativeResponse, .dataCreativeLink, .dataImageCarousel:
                guard let offer = context.offers[safe: context.currentOfferIndex] else { continue }
                let result = try creativeExtractor.extractDataRepresentedBy(String.self,
                                                                            propertyChain: keyAndNamespace.withNamespace,
                                                                            responseKey: nil,
                                                                            from: offer)
                switch result {
                case .value(let value):
                    return (value, false)
                case .state(let value):
                    return (value, true)
                }
            case .dataCatalogItem:
                if let catalogItem = context.activeCatalogItem {
                    let result = try catalogExtractor.extractDataRepresentedBy(String.self,
                                                                               propertyChain: keyAndNamespace.withNamespace,
                                                                               responseKey: nil,
                                                                               from: catalogItem)
                    switch result {
                    case .value(let value):
                        return (value, false)
                    case .state(let value):
                        return (value, true)
                    }
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
}

private extension BNFKeyAndNamespace {
    var withNamespace: String {
        namespace.rawValue + BNFSeparator.namespace.rawValue + key
    }
}
