//
//  CatalogDataExtractor.swift
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
struct CatalogDataExtractor<Validator: DataValidating>: DataExtracting where Validator.T == String {

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

    func extractDataRepresentedBy<U>(
        _ type: U.Type,
        propertyChain: String,
        responseKey: String?,
        from data: CatalogItem?
    ) throws -> DataBinding<U> {
        guard dataValidator.isValid(data: propertyChain) else {
            return .value(propertyChain as! U)
        }

        let placeholder = parser.parse(propertyChain: propertyChain)

        var isStateType = false

        var mappedData: Any?

        for keyAndNamespace in placeholder.parseableChains {
            switch keyAndNamespace.namespace {
            case .dataCatalogItem:
                guard let data else { continue }
                mappedData = catalogItemValue(for: keyAndNamespace, in: data)
                if mappedData.isNil == true, keyAndNamespace.isMandatory {
                    throw BNFPlaceholderError.mandatoryKeyEmpty
                }
            case .state:
                guard DataBindingStateKeys.isValidKey(keyAndNamespace.key) else { continue }

                mappedData = keyAndNamespace.key

                isStateType = true
            case .dataCreativeCopy,
                    .dataCreativeResponse,
                    .dataCreativeLink,
                    .dataImageCarousel:
                throw LayoutTransformerError.InvalidSyntaxMapping()
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

        guard let normalizedData = unwrapOptional(mappedData) else {
            return .value("" as! U)
        }

        return castData(normalizedData, as: type, isState: isStateType)
    }

    private func catalogItemValue(for keyAndNamespace: BNFKeyAndNamespace, in data: CatalogItem) -> Any? {
        let keys = keyAndNamespace.key.split(separator: ".").map(String.init)
        guard let firstKey = keys.first else { return nil }

        if keys.count > 1 {
            if firstKey == "copy" {
                guard let copy = data.copy else { return nil }
                let copyKey = keys.dropFirst().joined(separator: ".")
                guard !copyKey.isEmpty else { return nil }
                return copy[copyKey]
            }

            let reflectedValue = dataReflector.getReflectedValue(
                data: Mirror(reflecting: data),
                keys: keys
            )

            return unwrapOptional(reflectedValue)
        }

        return Mirror(reflecting: data)
            .children
            .first { $0.label == firstKey }
            .flatMap { unwrapOptional($0.value) }
    }

    private func castData<U>(_ value: Any, as type: U.Type, isState: Bool) -> DataBinding<U> {
        let casted: U

        if let typed = value as? U {
            casted = typed
        } else if let stringValue = value as? String, U.self == Int.self, let intValue = Int(stringValue) {
            casted = intValue as! U
        } else if let decimalValue = value as? Decimal {
            if U.self == Decimal.self {
                casted = decimalValue as! U
            } else if U.self == Double.self {
                casted = NSDecimalNumber(decimal: decimalValue).doubleValue as! U
            } else if U.self == Int.self {
                casted = NSDecimalNumber(decimal: decimalValue).intValue as! U
            } else if U.self == String.self {
                casted = NSDecimalNumber(decimal: decimalValue).stringValue as! U
            } else if U.self == Any.self {
                let stateBinding: DataBinding<U> = isState ? .state(decimalValue as! U) : .value(decimalValue as! U)
                return stateBinding
            } else {
                casted = NSDecimalNumber(decimal: decimalValue).stringValue as! U
            }
        } else if let stringValue = value as? String, U.self == Double.self, let doubleValue = Double(stringValue) {
            casted = doubleValue as! U
        } else if let stringValue = value as? String, U.self == Decimal.self, let decimalValue = Decimal(string: stringValue) {
            casted = decimalValue as! U
        } else if let boolValue = value as? Bool, U.self == String.self {
            casted = String(boolValue) as! U
        } else if let stringValue = value as? CustomStringConvertible, U.self == String.self {
            casted = stringValue.description as! U
        } else if let stringValue = value as? String {
            casted = stringValue as! U
        } else {
            casted = value as! U
        }

        return isState ? .state(casted) : .value(casted)
    }

    private func unwrapOptional(_ value: Any) -> Any? {
        var currentValue = value
        var mirror = Mirror(reflecting: currentValue)

        while mirror.displayStyle == .optional {
            guard let child = mirror.children.first else {
                return nil
            }
            currentValue = child.value
            mirror = Mirror(reflecting: currentValue)
        }

        return currentValue
    }
}
