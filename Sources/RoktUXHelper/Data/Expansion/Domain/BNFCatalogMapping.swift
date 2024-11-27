//
//  BNFCatalogMapping.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

@available(iOS 15, *)
struct BNFCatalogMapping<Extractor: DataExtractor>: BNFMapper where Extractor.MappingSource == CatalogItem {

    private let extractor: Extractor

    init(extractor: Extractor = BNFCatalogDataExtractor()) {
        self.extractor = extractor
    }

    func map(consumer: LayoutSchemaViewModel, context: CatalogItem) {
        switch consumer {
        case .richText(let textModel):
            let originalText = textModel.value ?? ""

            let transformedText = resolveDataExpansion(
                originalText,
                context: context
            )

            textModel.updateDataBinding(dataBinding: .value(transformedText))
        case .basicText(let textModel):
            let originalText = textModel.value ?? ""

            let transformedText = resolveDataExpansion(
                originalText,
                context: context
            )

            textModel.updateDataBinding(dataBinding: .value(transformedText))
        case .progressIndicator(let indicatorModel):
            guard let updatedText = try? extractor.extractDataRepresentedBy(
                String.self,
                propertyChain: indicatorModel.indicator,
                responseKey: nil,
                from: nil
            ) else { return }
            indicatorModel.updateDataBinding(dataBinding: updatedText)
        default:
            break
        }
    }

    private func resolveDataExpansion(_ fullText: String, context: CatalogItem) -> String {
        do {
            let placeholdersToResolved = try placeholdersToResolvedValues(fullText, data: context)

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
        data: CatalogItem
    ) throws -> [String: String] {
        // given fullText = "Hello %^DATA.catalogItem.someValue1^ AND %^DATA.catalogItem.someValue2^%"
        var placeHolderToResolvedValue: [String: String] = [:]

        let bnfRegexPattern = "(?<=\\%\\^)[a-zA-Z0-9 .|]*(?=\\^\\%)"
        let fullTextRange = NSRange(fullText.startIndex..<fullText.endIndex, in: fullText)

        guard let regexCheck = try? NSRegularExpression(pattern: bnfRegexPattern) else { return [:] }

        // [DATA.catalogItem.someValue1, DATA.catalogItem.someValue2]
        let bnfMatches = regexCheck.matches(in: fullText, options: [], range: fullTextRange)

        for match in bnfMatches {
            guard let swiftRange = Range(match.range, in: fullText) else { continue }

            // DATA.catalogItem.someValue1, DATA.catalogItem.someValue2
            let chainOfValues = String(fullText[swiftRange])

            let resolvedDataBinding = try extractor.extractDataRepresentedBy(
                String.self,
                propertyChain: chainOfValues,
                responseKey: nil,
                from: data
            )

            guard case .value(let resolvedValue) = resolvedDataBinding else { continue }

            // [DATA.catalogItem.someValue1: "some-value1", DATA.catalogItem.someValue2: "some-value2"]
            placeHolderToResolvedValue[chainOfValues] = resolvedValue
        }

        return placeHolderToResolvedValue
    }
}
