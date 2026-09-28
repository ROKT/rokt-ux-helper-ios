import Foundation

/// Final-pass guard that runs after every mapper has had a chance to resolve placeholders
/// in a text node. Two responsibilities:
///
/// 1. **Optional orphans** (`%^X | fallback^%` that no mapper resolved) are substituted with
///    their `|` default literal — matching the original BNF semantic that "if a `|` is
///    present, the layout never fails; we render the fallback instead".
///
/// 2. **Mandatory orphans** (`%^X^%` with no `|` that no mapper resolved) cause the entire
///    line to be zeroed — restoring the original "fail-loud when a critical copy is missing"
///    contract that existed before mappers became chainable.
///
/// **Deferred namespaces** (`DATA.catalogRuntime.*` and any `STATE.*`) are intentionally
/// skipped: they have separate runtime / render-time resolution paths and may be unresolved
/// at finalize time without indicating a defect.
enum OrphanedPlaceholderResolver {

    private static let bnfRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: BNFPlaceholder.deferredExpression)
    }()

    /// - Returns: the validated text with optional orphans replaced by their `|` defaults,
    ///   or `nil` if a mandatory orphan was found (caller should render an empty string).
    static func resolve(text: String) -> String? {
        guard let regex = bnfRegex else { return text }
        let tokens = BNFTokenScanner.tokens(in: text, matching: regex)
        guard !tokens.isEmpty else { return text }

        let parser = PropertyChainDataParser()
        let deferredPrefixes = [
            BNFNamespace.dataCatalogRuntime.withNamespaceSeparator,
            BNFNamespace.state.withNamespaceSeparator
        ]

        // Walk in reverse, mutating right to left in UTF-16 units, so a not-yet-processed token's
        // stored range is never touched by an earlier splice — including when a `|` default
        // starts with a Unicode combining mark, which would merge into the preceding character
        // and invalidate that range if this were done through Swift's grapheme-cluster-aware
        // String APIs.
        let result = NSMutableString(string: text)
        for token in tokens.reversed() {
            if deferredPrefixes.contains(where: { token.chain.contains($0) }) { continue }

            let parsed = parser.parse(propertyChain: token.chain)
            guard let fallback = parsed.defaultValue else {
                // Mandatory and unresolved → fail-loud, even for a token that overlaps its
                // neighbor's delimiter and so cannot itself be spliced (see BNFTokenScanner).
                return nil
            }
            // A token that overlaps its neighbor's delimiter is checked above but never spliced;
            // its span stays in the result as literal text.
            guard token.isSpliceable else { continue }
            // Replace at the scanned position (a global string search would re-target the first
            // identical token if the same placeholder appears multiple times).
            result.replaceCharacters(in: token.tokenRange, with: fallback)
        }
        return result as String
    }
}
