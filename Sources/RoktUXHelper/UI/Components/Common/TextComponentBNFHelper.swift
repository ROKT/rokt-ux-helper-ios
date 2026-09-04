import SwiftUI

class TextComponentBNFHelper {
    // shared method for RichText and BasicText components to replace STATE placeholders
    static func replaceStates(
        _ originalString: String,
        currentOffer: String,
        totalOffers: String
    ) -> String {
        let placeholdersToResolved = statePlaceholdersToResolvedValues(
            originalString, currentOffer: currentOffer, totalOffers: totalOffers)

        var transformedText = originalString

        placeholdersToResolved.forEach {
            let keyWithDelimiters = BNFSeparator.startDelimiter.rawValue + $0 + BNFSeparator.endDelimiter.rawValue
            transformedText = transformedText.replacingOccurrences(of: keyWithDelimiters, with: $1)
        }

        return transformedText
    }

    // replace STATE placeholders in attributed string
    static func replaceStates(
        _ originalString: NSAttributedString,
        currentOffer: String,
        totalOffers: String
    ) -> NSAttributedString {
        let placeholdersToResolved = statePlaceholdersToResolvedValues(
            originalString.description, currentOffer: currentOffer, totalOffers: totalOffers)

        let transformedText = originalString.mutableCopy() as! NSMutableAttributedString

        placeholdersToResolved.forEach {
            let origString = transformedText.string as NSString
            let keyWithDelimiters = BNFSeparator.startDelimiter.rawValue + $0 + BNFSeparator.endDelimiter.rawValue

            let range = origString.range(of: keyWithDelimiters)

            transformedText.replaceCharacters(in: range, with: $1)
        }

        return transformedText as NSAttributedString
    }

    private static func statePlaceholdersToResolvedValues(
        _ originalString: String,
        currentOffer: String,
        totalOffers: String
    ) -> [String: String] {
        var placeHoldersToResolvedValues: [String: String] = [:]

        let bnfRegexPattern = BNFPlaceholder.expression
        let range = NSRange(originalString.startIndex..<originalString.endIndex, in: originalString)

        guard let regexCheck = try? NSRegularExpression(pattern: bnfRegexPattern) else { return [:] }
        let bnfMatches = regexCheck.matches(in: originalString, options: [], range: range)

        for match in bnfMatches {
            guard let swiftRange = Range(match.range, in: originalString) else { continue }

            let chainOfValues = String(originalString[swiftRange])
            guard PropertyChainDataParser().parse(propertyChain: chainOfValues).parseableChains.contains(where: {
                $0.namespace == .state
            }) else { continue }
            let resolvedValue = resolveStateChain(
                propertyChain: chainOfValues,
                currentOfferString: currentOffer,
                totalOffersString: totalOffers)

            // e.g. [STATE.IndicatorPosition: "1", STATE.TotalOffers: "4"]
            placeHoldersToResolvedValues[chainOfValues] = resolvedValue
        }

        return placeHoldersToResolvedValues
    }

    private static func resolveStateChain(
        propertyChain: String,
        currentOfferString: String,
        totalOffersString: String
    ) -> String {
        let validator = PlaceholderValidator(validatesTextOperations: false)
        let parser = PropertyChainDataParser()
        let parsedChain = parser.parse(propertyChain: propertyChain)
        guard validator.isValid(data: propertyChain) else {
            return parsedChain.hasTextOperations
                ? (parsedChain.defaultValue ?? "") : propertyChain
        }

        for keyAndNamespace in parsedChain.parseableChains {
            guard case .state = keyAndNamespace.namespace,
                  DataBindingStateKeys.isValidKey(keyAndNamespace.key),
                  !keyAndNamespace.textOperations.contains(.invalid)
            else {
                continue
            }

            if DataBindingStateKeys.isTotalOffers(keyAndNamespace.key) {
                return (try? keyAndNamespace.applyingTextOperations(to: totalOffersString)) ?? ""
            } else if DataBindingStateKeys.isIndicatorPosition(keyAndNamespace.key) {
                return (try? keyAndNamespace.applyingTextOperations(to: currentOfferString)) ?? ""
            }
        }

        // fallback if STATE placeholder unable to be resolved
        return parsedChain.defaultValue ?? ""
    }
}
