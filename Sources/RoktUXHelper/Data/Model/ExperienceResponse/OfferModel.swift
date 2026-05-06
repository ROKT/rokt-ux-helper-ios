import Foundation

struct OfferModel: Codable {
    let campaignId: String?
    let creative: CreativeModel
    let catalogItems: [CatalogItem]?
    let catalogItemGroup: CatalogItemGroup?
    let transactionData: TransactionData?
}

struct CreativeModel: Codable {
    let referralCreativeId: String
    let instanceGuid: String
    let copy: [String: String]
    let images: [String: CreativeImage]?
    let links: [String: CreativeLink]?

    let responseOptionsMap: ResponseOptionList?
    let jwtToken: String

    enum CodingKeys: String, CodingKey {
        case referralCreativeId
        case instanceGuid
        case copy
        case images
        case links
        case responseOptionsMap
        case jwtToken = "token"
    }
}

struct CreativeImage: Codable, Hashable {
    let light: String?
    let dark: String?
    let alt: String?
    let title: String?

    var hasImageURL: Bool { light?.isEmpty == false || dark?.isEmpty == false }
}

struct ResponseOptionList: Codable {
    let positive: RoktUXResponseOption?
    let negative: RoktUXResponseOption?
}

struct CreativeLink: Codable, Hashable {
    let url: String?
    let title: String?
}

@available(iOS 15, *)
extension OfferModel {
    /// Returns true when image alt text matches title-like creative copy so the image can be hidden from VoiceOver as decorative.
    func imageAltDuplicatesTitleLikeCopy(_ alt: String) -> Bool {
        let normalizedAlt = Self.normalizeAccessibilityComparisonString(alt)
        guard !normalizedAlt.isEmpty else { return false }

        for (key, value) in creative.copy {
            guard Self.isTitleLikeCopyField(key) else { continue }
            let comparableCopy = Self.normalizeAccessibilityComparisonString(
                Self.plainTextFromCreativeCopyForAccessibilityComparison(value)
            )
            if comparableCopy == normalizedAlt {
                return true
            }
        }
        return false
    }

    /// Whether a creative image alt duplicates title-like copy on the active offer (VoiceOver hides redundant logo imagery).
    static func decorativeAccessibilityDueToDuplicateOfferCopy(
        alt: String?,
        layoutState: (any LayoutStateRepresenting)?
    ) -> Bool {
        guard let alt else { return false }
        guard let offer = layoutState?.items[LayoutState.fullOfferKey] as? OfferModel else { return false }
        return offer.imageAltDuplicatesTitleLikeCopy(alt)
    }

    /// Title-like copy may contain DCUI HTML (`<h2>…</h2>`) or entities (`&amp;`); alt is plain—parse to comparable text before matching.
    private static func plainTextFromCreativeCopyForAccessibilityComparison(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard trimmed.contains("<") || trimmed.contains("&") else {
            return trimmed
        }
        let (parsed, _) = LightweightHTMLParser.parse(html: trimmed, baseFont: nil)
        return parsed.string
    }

    private static func isTitleLikeCopyField(_ key: String) -> Bool {
        let k = key.lowercased()
        if k.contains("subtitle") { return false }
        if k == "title" || k == "headline" { return true }
        if k.contains("headline") { return true }
        if k.contains("brand") || k.contains("advertiser") { return true }
        if k.hasSuffix("title") { return true }
        return false
    }

    private static func normalizeAccessibilityComparisonString(_ string: String) -> String {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
