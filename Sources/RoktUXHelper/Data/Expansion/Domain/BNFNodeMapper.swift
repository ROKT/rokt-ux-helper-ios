//
//  BNFNodeMapper.swift
//  RoktUXHelper
//
//  Copyright 2020 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

@available(iOS 15, *)
protocol DomainMapper {
    associatedtype T: DomainMappingSource

    @discardableResult
    func map(
        consumer: LayoutSchemaViewModel,
        creativeParent: CreativeResponseViewModel?,
        dataSource: T
    ) -> DomainMappable?
}

/// Maps properties of `Node`s using values in `dataSource`.
/// The mappable property of each `node` is known here (eg. `TextNode`'s value)
/// Bridge that knows the `LayoutSchemaModel` data type
@available(iOS 15, *)
class BNFNodeMapper<DE: DataExtractor>: DomainMapper where DE.U == OfferModel {
    let extractor: DE

    init(extractor: DE = BNFDataExtractor()) {
        self.extractor = extractor
    }

    /// Given a node `consumer` with a BNF-formatted property. Extract the value from `dataSource` and mutate `consumer`
    /// - Parameters:
    ///   - consumer: Entity with a BNF-formatted property
    ///   - parent: Top-level parent of the consumer
    ///   - dataSource: Entity of values
    /// - Returns: Updated `consumer` DATA MODEL whose BNF-formatted property was parsed and replaced with values from `dataSource`
    @discardableResult
    func map(
        consumer: LayoutSchemaViewModel,
        creativeParent: CreativeResponseViewModel?,
        dataSource: OfferModel
    ) -> DomainMappable? {
        switch consumer {
        // assumption is that the `value` property will be the mappable value
        // this is where we decide that only creative.responseOptions is allowed for buttons
        case .richText(let textModel):
            let originalText = textModel.value ?? ""

            let transformedText = resolveDataExpansion(
                originalText,
                creativeParent: creativeParent,
                dataSource: dataSource
            )

            textModel.updateDataBinding(dataBinding: .value(transformedText))

            return textModel
        case .basicText(let textModel):
            let originalText = textModel.value ?? ""

            let transformedText = resolveDataExpansion(
                originalText,
                creativeParent: creativeParent,
                dataSource: dataSource
            )

            textModel.updateDataBinding(dataBinding: .value(transformedText))

            return textModel
        case .progressIndicator(let indicatorModel):
            do {
                let updatedText = try extractor.extractDataRepresentedBy(
                    String.self,
                    propertyChain: indicatorModel.indicator,
                    responseKey: creativeParent?.responseKey.rawValue,
                    from: dataSource
                )
                indicatorModel.updateDataBinding(dataBinding: updatedText)

                return indicatorModel
            } catch {
                return nil
            }
        default:
            return consumer
        }
    }

    private func resolveDataExpansion(
        _ fullText: String,
        creativeParent: CreativeResponseViewModel? = nil,
        dataSource: OfferModel
    ) -> String {
        do {
            let placeholdersToResolved = try placeholdersToResolvedValues(fullText,
                                                                          creativeParent: creativeParent,
                                                                          dataSource: dataSource)
            
            var transformedText = fullText
            
            placeholdersToResolved.forEach {
                let keyWithDelimiters = BNFSeparator.startDelimiter.rawValue + $0 + BNFSeparator.endDelimiter.rawValue
                transformedText = transformedText.replacingOccurrences(of: keyWithDelimiters, with: $1)
            }
            
            return transformedText
        } catch {
            return ""
        }
    }

    // return type is a hashmap of placeholders to their resolved values
    private func placeholdersToResolvedValues(
        _ fullText: String,
        creativeParent: CreativeResponseViewModel?,
        dataSource: OfferModel
    ) throws -> [String: String] {
        // given fullText = "Hello %^DATA.creativeCopy.someValue1^ AND %^DATA.creativeCopy.someValue2^%"
        var placeHolderToResolvedValue: [String: String] = [:]

        let bnfRegexPattern = "(?<=\\%\\^)[a-zA-Z0-9 .|]*(?=\\^\\%)"
        let fullTextRange = NSRange(fullText.startIndex..<fullText.endIndex, in: fullText)

        guard let regexCheck = try? NSRegularExpression(pattern: bnfRegexPattern) else { return [:] }

        // [DATA.creativeCopy.someValue1, DATA.creativeCopy.someValue2]
        let bnfMatches = regexCheck.matches(in: fullText, options: [], range: fullTextRange)

        for match in bnfMatches {
            guard let swiftRange = Range(match.range, in: fullText) else { continue }

            // DATA.creativeCopy.someValue1, DATA.creativeCopy.someValue2
            let chainOfValues = String(fullText[swiftRange])

            let resolvedDataBinding = try extractor.extractDataRepresentedBy(
                String.self,
                propertyChain: chainOfValues,
                responseKey: creativeParent?.responseKey.rawValue,
                from: dataSource
            )

            guard case .value(let resolvedValue) = resolvedDataBinding else { continue }

            // [DATA.creativeCopy.someValue1: "some-value1", DATA.creativeCopy.someValue2: "some-value2"]
            placeHolderToResolvedValue[chainOfValues] = resolvedValue
        }

        return placeHolderToResolvedValue
    }
}
