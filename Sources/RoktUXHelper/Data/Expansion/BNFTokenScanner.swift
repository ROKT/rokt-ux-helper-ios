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
        /// False when this token's span overlaps the previous token's — two placeholders sharing
        /// a delimiter character, since the pattern's delimiters are lookarounds and are not
        /// consumed. Splicing a non-spliceable token's range is not safe (see `tokens(in:matching:)`),
        /// but its `chain` is still a real placeholder: a caller must still evaluate it — for
        /// example, to fail loud on a mandatory placeholder — rather than discarding it unseen.
        let isSpliceable: Bool
    }

    /// - Returns: every token `regex` matches in `text`, in reading order.
    ///
    /// The pattern's delimiters are lookarounds, so they are not consumed and the `%` that closes
    /// one token can also open the next: `%^a^%^b^%` matches twice over spans that share that
    /// character. Splicing both would combine overlapping ranges of a string whose length changes
    /// as it is edited, so only the first of an overlapping pair is `isSpliceable`. The rest of
    /// that pair is still returned: a caller must not replace its range, but must not silently
    /// drop it either, since its chain can still be a mandatory placeholder that has to fail loud.
    static func tokens(in text: String, matching regex: NSRegularExpression) -> [Token] {
        let searchRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let startLength = BNFSeparator.startDelimiter.utf16Count
        let endLength = BNFSeparator.endDelimiter.utf16Count

        var tokens: [Token] = []
        var nextSpliceableStart = 0
        for match in regex.matches(in: text, options: [], range: searchRange) {
            let tokenRange = NSRange(location: match.range.location - startLength,
                                     length: match.range.length + startLength + endLength)
            guard NSMaxRange(tokenRange) <= searchRange.length,
                  let chainRange = Range(match.range, in: text)
            else { continue }

            let isSpliceable = tokenRange.location >= nextSpliceableStart
            if isSpliceable {
                nextSpliceableStart = NSMaxRange(tokenRange)
            }

            tokens.append(Token(chain: String(text[chainRange]), tokenRange: tokenRange, isSpliceable: isSpliceable))
        }
        return tokens
    }
}
