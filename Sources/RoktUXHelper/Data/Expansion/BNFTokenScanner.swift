import Foundation

/// Locates the placeholders a `BNFPlaceholder` pattern matches and reports, for each one, the span
/// of the whole token — `%^`, the chain, and `^%` — so callers can splice a replacement in by
/// position instead of searching for the token text.
enum BNFTokenScanner {

    struct Token {
        /// The property chain between the delimiters, as the pattern matched it.
        let chain: String
        /// The span of `%^` + `chain` + `^%`, in UTF-16 offsets into the scanned text.
        let tokenRange: NSRange
    }

    /// - Returns: the tokens in `text`, in reading order, with spans that never overlap.
    ///
    /// The pattern's delimiters are lookarounds, so they are not consumed and the `%` that closes
    /// one token can also open the next: `%^a^%^b^%` matches twice over spans that share that
    /// character. Replacing both would splice overlapping ranges of a string whose length changes
    /// as it is edited. The first token wins and the one overlapping it stays literal text, which
    /// is what the mappers' `replacingOccurrences` substitutions already do with such input.
    static func tokens(in text: String, matching regex: NSRegularExpression) -> [Token] {
        let searchRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let startLength = BNFSeparator.startDelimiter.utf16Count
        let endLength = BNFSeparator.endDelimiter.utf16Count

        var tokens: [Token] = []
        for match in regex.matches(in: text, options: [], range: searchRange) {
            let tokenRange = NSRange(location: match.range.location - startLength,
                                     length: match.range.length + startLength + endLength)
            guard tokenRange.location >= tokens.last.map({ NSMaxRange($0.tokenRange) }) ?? 0,
                  NSMaxRange(tokenRange) <= searchRange.length,
                  let chainRange = Range(match.range, in: text)
            else { continue }

            tokens.append(Token(chain: String(text[chainRange]), tokenRange: tokenRange))
        }
        return tokens
    }
}
