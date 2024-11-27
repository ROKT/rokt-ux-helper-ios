//
//  BNFCreativeMapping.swift
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

enum BNFCreativeContext {
    case generic(OfferModel)
    case positiveResponse(OfferModel)
    case negativeResponse(OfferModel)

    var creativeResponse: BNFNamespace.CreativeResponseKey? {
        switch self {
        case .generic: nil
        case .positiveResponse: .positive
        case .negativeResponse: .negative
        }
    }

    var offerModel: OfferModel {
        switch self {
        case .generic(let offerModel),
                .positiveResponse(let offerModel),
                .negativeResponse(let offerModel):
            offerModel
        }
    }
}

/// Maps properties of `Node`s using values in `context`.
/// The mappable property of each `node` is known here (eg. `TextNode`'s value)
/// Bridge that knows the `LayoutSchemaModel` data type
@available(iOS 15, *)
struct BNFCreativeMapping<Extractor: DataExtractor>: BNFMapper where Extractor.MappingSource == OfferModel {
    let extractor: Extractor

    init(extractor: Extractor = BNFCreativeDataExtractor()) {
        self.extractor = extractor
    }

    func map(consumer: LayoutSchemaViewModel, context: BNFCreativeContext) {
        switch consumer {
            // assumption is that the `value` property will be the mappable value
            // this is where we decide that only creative.responseOptions is allowed for buttons
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
                responseKey: context.creativeResponse?.rawValue,
                from: context.offerModel
            ) else { return }
            indicatorModel.updateDataBinding(dataBinding: updatedText)
        default:
            break
        }
    }

    private func resolveDataExpansion(_ fullText: String, context: BNFCreativeContext) -> String {
        do {
            let placeholdersToResolved = try placeholdersToResolvedValues(fullText,
                                                                          responseKey: context.creativeResponse,
                                                                          dataSource: context.offerModel)

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
        responseKey: BNFNamespace.CreativeResponseKey?,
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
                responseKey: responseKey?.rawValue,
                from: dataSource
            )

            guard case .value(let resolvedValue) = resolvedDataBinding else { continue }

            // [DATA.creativeCopy.someValue1: "some-value1", DATA.creativeCopy.someValue2: "some-value2"]
            placeHolderToResolvedValue[chainOfValues] = resolvedValue
        }

        return placeHolderToResolvedValue
    }
}
