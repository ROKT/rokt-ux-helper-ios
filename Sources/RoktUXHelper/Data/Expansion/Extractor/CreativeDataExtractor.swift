//
//  CreativeDataExtractor.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

@available(iOS 13, *)
class CreativeDataExtractor<Validator: DataValidating>: DataExtracting where Validator.T == String {

    private let dataValidator: Validator
    private let parser: PropertyChainDataParsing
    private let dataReflector: any DataReflecting

    init(
        dataValidator: Validator = PlaceholderValidator(),
        parser: PropertyChainDataParsing = PropertyChainDataParser(),
        dataReflector: any DataReflecting = DataReflector()
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
        from data: OfferModel?
    ) throws -> DataBinding<U> {
        guard dataValidator.isValid(data: propertyChain) else { return .value(propertyChain as! U) }

        let placeholder = parser.parse(propertyChain: propertyChain)

        var isStateType = false

        var mappedData: String?

        for keyAndNamespace in placeholder.parseableChains {
            switch keyAndNamespace.namespace {
            case .dataCreativeCopy:
                guard let data else { continue }

                let creativeCopy = data.creative.copy
                if let copyForKey = creativeCopy[keyAndNamespace.key],
                   !copyForKey.isEmpty {
                    mappedData = creativeCopy[keyAndNamespace.key]
                } else if keyAndNamespace.isMandatory {
                    throw BNFPlaceholderError.mandatoryKeyEmpty
                } else {
                    continue
                }
            case .dataCreativeResponse:
                guard let data,
                      let responseKey
                else { continue }

                var responseOption: RoktUXResponseOption?

                if responseKey.caseInsensitiveCompare(
                    BNFNamespace.CreativeResponseKey.positive.rawValue
                ) == .orderedSame {
                    responseOption = data.creative.responseOptionsMap?.positive
                } else if responseKey.caseInsensitiveCompare(
                    BNFNamespace.CreativeResponseKey.negative.rawValue
                ) == .orderedSame {
                    responseOption = data.creative.responseOptionsMap?.negative
                }

                guard let responseOption else { continue }

                let responseOptionMirror = Mirror(reflecting: responseOption)
                let chainAsList = toArray(propertyChain: keyAndNamespace.key)

                if let nestedValue = dataReflector.getReflectedValue(data: responseOptionMirror, keys: chainAsList) {
                    mappedData = (nestedValue as? String)
                    break
                }
            case .dataCreativeLink:
                guard let data else { continue }

                let linkObject = data.creative.links?[keyAndNamespace.key]

                let linkTitle = linkObject?.title ?? ""
                let linkURL = linkObject?.url ?? ""

                if !linkTitle.isEmpty && !linkURL.isEmpty {
                    mappedData = "<a href=\"\(linkURL)\" target=\"_blank\">\(linkTitle)</a>"
                } else if keyAndNamespace.isMandatory {
                    throw BNFPlaceholderError.mandatoryKeyEmpty
                } else {
                    continue
                }
            case .state:
                guard DataBindingStateKeys.isValidKey(keyAndNamespace.key) else { continue }

                mappedData = keyAndNamespace.key

                isStateType = true
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

    private func toArray(propertyChain: String) -> [String] {
        propertyChain.components(separatedBy: ".")
    }
}
