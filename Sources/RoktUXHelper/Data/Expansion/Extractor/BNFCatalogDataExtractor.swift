//
//  BNFCreativeDataExtractor.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

/// Expands a BNF-formatted String using values nested in an `OfferModel` entity
@available(iOS 13, *)
struct BNFCatalogDataExtractor<Validator: DataValidator>: DataExtractor where Validator.T == String {

    private let dataValidator: Validator
    private let parser: PropertyChainDataParser
    private let dataReflector: any DataReflector

    init(
        dataValidator: Validator = BNFPlaceholderValidator(),
        parser: PropertyChainDataParser = BNFPropertyChainDataParser(),
        dataReflector: any DataReflector = BNFDataReflector()
    ) {
        self.dataValidator = dataValidator
        self.parser = parser
        self.dataReflector = dataReflector
    }

    // maps `propertyChain` to a value inside `Offer`, if possible
    // note that you can chain statements like A? | B? | Default?
    // if A does not exist, check B, else use default
    func extractDataRepresentedBy<U>(
        _ type: U.Type,
        propertyChain: String,
        responseKey: String?,
        from data: CatalogItem?
    ) throws -> DataBinding<U> {
        guard dataValidator.isValid(data: propertyChain) else { return .value(propertyChain as! U) }

        let placeholder = parser.parse(propertyChain: propertyChain)

        var isStateType = false

        var mappedData: String?

        for keyAndNamespace in placeholder.parseableChains {
            switch keyAndNamespace.namespace {
            case .dataCatalogItem:
                guard let data else { continue }
                mappedData = Mirror.init(reflecting: data)
                    .children
                    .first {
                        $0.label == keyAndNamespace.key
                    }
                    .map(\.value) as? String
                if mappedData.isEmpty == true, keyAndNamespace.isMandatory {
                    throw BNFPlaceholderError.mandatoryKeyEmpty
                }
            case .state:
                guard DataBindingStateKeys.isValidKey(keyAndNamespace.key) else { continue }

                mappedData = keyAndNamespace.key

                isStateType = true
            case .dataCreativeCopy,
                    .dataCreativeResponse,
                    .dataCreativeLink:
                throw LayoutTransformerError.InvalidBNFMapping()
            }

            // found a match
            if mappedData != nil {
                break
            }
        }

        if mappedData == nil {
            mappedData = placeholder.defaultValue
        }

        // return empty if the mapped data is not found
        guard let mappedData else { return .value("" as! U) }

        if isStateType {
            return .state(mappedData as! U)
        } else {
            return .value(mappedData as! U)
        }
    }
}
