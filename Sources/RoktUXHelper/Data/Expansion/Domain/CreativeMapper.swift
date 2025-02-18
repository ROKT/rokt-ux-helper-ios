//
//  CreativeMapper.swift
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

enum CreativeContext {
    case outer
    case generic(OfferModel?)
    case positiveResponse(OfferModel)
    case negativeResponse(OfferModel)

    var creativeResponse: BNFNamespace.CreativeResponseKey? {
        switch self {
        case .generic, .outer: nil
        case .positiveResponse: .positive
        case .negativeResponse: .negative
        }
    }

    var offerModel: OfferModel? {
        switch self {
        case .generic(.some(let offerModel)),
                .positiveResponse(let offerModel),
                .negativeResponse(let offerModel):
            offerModel
        case .outer,
                .generic(.none): nil
        }
    }
}

/// Maps properties of `Node`s using values in `context`.
/// The mappable property of each `node` is known here (eg. `TextNode`'s value)
/// Bridge that knows the `LayoutSchemaModel` data type
@available(iOS 15, *)
struct CreativeMapper<Extractor: DataExtracting>: SyntaxMapping where Extractor.MappingSource == OfferModel {
    let extractor: Extractor

    init(extractor: Extractor = CreativeDataExtractor()) {
        self.extractor = extractor
    }

    func map(consumer: LayoutSchemaViewModel, context: CreativeContext) {
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

    private func resolveDataExpansion(_ fullText: String, context: CreativeContext) -> String {
        do {
            guard let offerModel = context.offerModel else { throw LayoutTransformerError.InvalidSyntaxMapping() }
            let placeholdersToResolved = try placeholdersToResolvedValues(fullText,
                                                                          responseKey: context.creativeResponse,
                                                                          dataSource: offerModel)

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
