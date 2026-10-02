import UIKit

/// Synchronous HTML-to-NSAttributedString parser that avoids WebKit entirely.
///
/// Supports the DCUI rich text tag surface:
///   `<b>`, `<strong>`, `<i>`, `<em>`, `<u>`, `<s>`, `<strike>`,
///   `<a href="…" target="…">`, `<font color="…">`, `<br>`, `<br/>`, `<p>`,
///   `<ul>`, `<ol>`, `<li>` (markers only — wrapped lines fall to the left
///   margin because SwiftUI's `Text(AttributedString)` does not honor
///   `NSParagraphStyle` indent attributes)
///
/// Also decodes common HTML entities (`&amp;`, `&lt;`, `&gt;`, `&quot;`,
/// `&apos;`, `&nbsp;`, `&#NNN;`, `&#xHHH;`).
@available(iOS 15, *)
enum LightweightHTMLParser {

    // MARK: - Constants

    private static let paragraphTag = "p"
    private static let lineBreakTag = "br"
    private static let unorderedListTag = "ul"
    private static let orderedListTag = "ol"
    private static let listItemTag = "li"
    private static let newline = "\n"
    private static let paragraphSpacing: CGFloat = 8
    /// Whitespace inserted between a list marker (• or 1.) and the item content.
    /// Widen or tighten the visual gap by editing this string.
    ///     "•Item"   ←  ""
    ///     "• Item"  ←  " "
    ///     "•   Item" ← "   "
    private static let listMarkerSeparator = " "
    /// Font size used for the invisible spacer line inserted between paragraphs.
    /// SwiftUI's `Text(AttributedString)` does not honor `NSParagraphStyle.paragraphSpacing`,
    /// so we fake the gap by emitting a tiny-font NBSP on its own line.
    private static let paragraphSpacerFontSize: CGFloat = 6
    private static let paragraphSpacerCharacter = "\u{00A0}"
    /// Fraction of the caller-provided `blockSpacerHeight` used as the actual
    /// spacer font size. Callers pass their full text `lineHeight`; a 1.0
    /// ratio renders an entire blank line between blocks, which is too loose.
    /// ~0.4 approximates the visual gap of CSS `margin: 0.5em 0` on `<p>`
    /// once the parser's surrounding newlines are accounted for.
    private static let blockSpacerLineHeightRatio: CGFloat = 0.4

    // MARK: - Public API

    /// - Parameter blockSpacerHeight: Optional line-height hint used to size
    ///   the invisible spacer line inserted between `<p>` blocks and between
    ///   sibling `<li>` items. Pass the DCUI `style?.text?.lineHeight` and the
    ///   parser scales it down (see `blockSpacerLineHeightRatio`) to a
    ///   paragraph-sized gap. `nil` falls back to the default 6pt spacer.
    static func parse(
        html: String,
        baseFont: UIFont?,
        blockSpacerHeight: CGFloat? = nil
    ) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        var index = html.startIndex
        var tagStack: [Tag] = []
        var styledRanges: [(NSRange, NSParagraphStyle)] = []
        var paragraphStart: Int?
        var listStack: [ListContext] = []
        var listItemStarts: [OpenListItem] = []
        // Keep the tags from the first space in a collapsed run. A tag may close
        // before the space is emitted, or a different tag may open after it.
        var pendingWhitespaceTags: [Tag]?
        let spacerFontSize = blockSpacerHeight.map { $0 * blockSpacerLineHeightRatio }
            ?? paragraphSpacerFontSize

        while index < html.endIndex {
            if html[index] == "<" {
                if html[index...].hasPrefix("<!--") {
                    if let end = html[index...].range(of: "-->")?.upperBound {
                        index = end
                    } else {
                        index = html.endIndex
                    }
                    continue
                }
                if let (tag, nextIndex) = scanTag(in: html, from: index) {
                    index = nextIndex
                    handleTag(
                        tag,
                        stack: &tagStack,
                        result: result,
                        baseFont: baseFont,
                        spacerFontSize: spacerFontSize,
                        pendingWhitespaceTags: &pendingWhitespaceTags,
                        paragraphStart: &paragraphStart,
                        listStack: &listStack,
                        listItemStarts: &listItemStarts,
                        styledRanges: &styledRanges
                    )
                } else {
                    appendCollapsedText(
                        "<", to: result, stack: tagStack, baseFont: baseFont,
                        pendingWhitespaceTags: &pendingWhitespaceTags
                    )
                    index = html.index(after: index)
                }
            } else {
                let (text, nextIndex) = scanText(in: html, from: index)
                index = nextIndex
                let decoded = decodeHTMLEntities(text)
                appendCollapsedText(
                    decoded, to: result, stack: tagStack, baseFont: baseFont,
                    pendingWhitespaceTags: &pendingWhitespaceTags
                )
            }
        }

        applyParagraphStyles(to: result, ranges: styledRanges)
        return result
    }

    // MARK: - Tag model

    struct Tag {
        let name: String
        let isClosing: Bool
        let attributes: [String: String]
    }

    private struct ListContext {
        enum Kind { case unordered, ordered }
        let kind: Kind
        var counter: Int
        /// Whether the most recently closed `<li>` at this depth contained a
        /// block-level child (currently `<p>`). Drives the CSS-style rule
        /// that bare `<li>` siblings sit flush (no inter-item gap) while
        /// `<li><p>...</p></li>` siblings get a spacer from the `<p>`'s
        /// implied margin.
        var lastClosedHadBlock: Bool
    }

    private struct OpenListItem {
        let contentStart: Int
        let depth: Int
        var containedBlock: Bool
    }

    // MARK: - Tag dispatch

    private static func handleTag(
        _ tag: Tag,
        stack: inout [Tag],
        result: NSMutableAttributedString,
        baseFont: UIFont?,
        spacerFontSize: CGFloat,
        pendingWhitespaceTags: inout [Tag]?,
        paragraphStart: inout Int?,
        listStack: inout [ListContext],
        listItemStarts: inout [OpenListItem],
        styledRanges: inout [(NSRange, NSParagraphStyle)]
    ) {
        if tag.isClosing {
            handleClosingTag(
                tag,
                stack: &stack,
                result: result,
                pendingWhitespaceTags: &pendingWhitespaceTags,
                paragraphStart: &paragraphStart,
                listStack: &listStack,
                listItemStarts: &listItemStarts,
                styledRanges: &styledRanges
            )
        } else if tag.name == lineBreakTag {
            pendingWhitespaceTags = nil
            result.append(NSAttributedString(string: newline))
        } else {
            handleOpeningTag(
                tag,
                stack: &stack,
                result: result,
                baseFont: baseFont,
                spacerFontSize: spacerFontSize,
                pendingWhitespaceTags: &pendingWhitespaceTags,
                paragraphStart: &paragraphStart,
                listStack: &listStack,
                listItemStarts: &listItemStarts,
                styledRanges: &styledRanges
            )
        }
    }

    private static func handleOpeningTag(
        _ tag: Tag,
        stack: inout [Tag],
        result: NSMutableAttributedString,
        baseFont: UIFont?,
        spacerFontSize: CGFloat,
        pendingWhitespaceTags: inout [Tag]?,
        paragraphStart: inout Int?,
        listStack: inout [ListContext],
        listItemStarts: inout [OpenListItem],
        styledRanges: inout [(NSRange, NSParagraphStyle)]
    ) {
        switch tag.name {
        case paragraphTag:
            pendingWhitespaceTags = nil
            // If a previous <p> is still open (no explicit </p>), finalize it
            // so its range is preserved instead of overwritten.
            finalizeOpenParagraph(
                result: result,
                paragraphStart: &paragraphStart,
                stack: &stack,
                styledRanges: &styledRanges
            )
            insertBlockSeparatorIfNeeded(
                in: result,
                listItemStarts: listItemStarts,
                spacerFontSize: spacerFontSize
            )
            // Mark the innermost open <li> as block-bearing so its closing
            // propagates the flag to ListContext.lastClosedHadBlock.
            if !listItemStarts.isEmpty {
                listItemStarts[listItemStarts.count - 1].containedBlock = true
            }
            paragraphStart = result.length
            stack.append(tag)
        case unorderedListTag:
            pendingWhitespaceTags = nil
            insertBlockSeparatorIfNeeded(
                in: result,
                listItemStarts: listItemStarts,
                spacerFontSize: spacerFontSize
            )
            listStack.append(ListContext(kind: .unordered, counter: 1, lastClosedHadBlock: false))
            stack.append(tag)
        case orderedListTag:
            pendingWhitespaceTags = nil
            insertBlockSeparatorIfNeeded(
                in: result,
                listItemStarts: listItemStarts,
                spacerFontSize: spacerFontSize
            )
            listStack.append(ListContext(kind: .ordered, counter: 1, lastClosedHadBlock: false))
            stack.append(tag)
        case listItemTag:
            guard !listStack.isEmpty else {
                stack.append(tag)
                return
            }
            let currentDepth = listStack.count - 1
            // If a previous <li> at the same depth is still open (no explicit </li>),
            // finalize it (HTML5 allows omitting </li>).
            if let last = listItemStarts.last, last.depth == currentDepth {
                pendingWhitespaceTags = nil
                finalizeOpenListItem(
                    last,
                    result: result,
                    listStack: &listStack,
                    listItemStarts: &listItemStarts,
                    stack: &stack,
                    styledRanges: &styledRanges
                )
            }
            pendingWhitespaceTags = nil
            ensureTrailingNewline(in: result)
            // CSS analogue: bare `<li>` has `margin: 0` (no gap), but a `<p>`
            // child contributes its own margin. We emit the spacer only when
            // the prior sibling at this depth contained a block child.
            if listStack[currentDepth].counter > 1, listStack[currentDepth].lastClosedHadBlock {
                appendBlockSpacer(to: result, fontSize: spacerFontSize)
            }
            // Apply the active tag-stack attributes to the marker so it inherits
            // surrounding font/color/etc. (e.g. <font color=...><ul>...).
            let prefix = listItemPrefix(for: listStack[currentDepth])
            let prefixAttrs = buildAttributes(from: stack, baseFont: baseFont)
            result.append(NSAttributedString(string: prefix, attributes: prefixAttrs))
            listItemStarts.append(
                OpenListItem(contentStart: result.length, depth: currentDepth, containedBlock: false)
            )
            stack.append(tag)
        default:
            stack.append(tag)
        }
    }

    private static func handleClosingTag(
        _ tag: Tag,
        stack: inout [Tag],
        result: NSMutableAttributedString,
        pendingWhitespaceTags: inout [Tag]?,
        paragraphStart: inout Int?,
        listStack: inout [ListContext],
        listItemStarts: inout [OpenListItem],
        styledRanges: inout [(NSRange, NSParagraphStyle)]
    ) {
        switch tag.name {
        case paragraphTag:
            pendingWhitespaceTags = nil
            finalizeOpenParagraph(
                result: result,
                paragraphStart: &paragraphStart,
                stack: &stack,
                styledRanges: &styledRanges
            )
        case listItemTag:
            pendingWhitespaceTags = nil
            if let last = listItemStarts.last, !listStack.isEmpty {
                finalizeOpenListItem(
                    last,
                    result: result,
                    listStack: &listStack,
                    listItemStarts: &listItemStarts,
                    stack: &stack,
                    styledRanges: &styledRanges
                )
            }
        case unorderedListTag, orderedListTag:
            pendingWhitespaceTags = nil
            if !listStack.isEmpty { listStack.removeLast() }
        default:
            break
        }

        if let idx = stack.lastIndex(where: { $0.name == tag.name }) {
            stack.remove(at: idx)
        }
    }

    // MARK: - Finalizers

    private static func finalizeOpenParagraph(
        result: NSMutableAttributedString,
        paragraphStart: inout Int?,
        stack: inout [Tag],
        styledRanges: inout [(NSRange, NSParagraphStyle)]
    ) {
        guard let start = paragraphStart else { return }
        ensureTrailingNewline(in: result)
        let length = result.length - start
        if length > 0 {
            styledRanges.append((NSRange(location: start, length: length), paragraphStyleForP))
        }
        paragraphStart = nil
        if let openP = stack.lastIndex(where: { $0.name == paragraphTag }) {
            stack.remove(at: openP)
        }
    }

    private static func finalizeOpenListItem(
        _ item: OpenListItem,
        result: NSMutableAttributedString,
        listStack: inout [ListContext],
        listItemStarts: inout [OpenListItem],
        stack: inout [Tag],
        styledRanges: inout [(NSRange, NSParagraphStyle)]
    ) {
        ensureTrailingNewline(in: result)
        if item.depth < listStack.count {
            listStack[item.depth].counter += 1
            listStack[item.depth].lastClosedHadBlock = item.containedBlock
        }
        listItemStarts.removeLast()
        if let openLi = stack.lastIndex(where: { $0.name == listItemTag }) {
            stack.remove(at: openLi)
        }
    }

    // MARK: - List helpers

    private static func listItemPrefix(for context: ListContext) -> String {
        switch context.kind {
        case .unordered: return "•" + listMarkerSeparator
        case .ordered: return "\(context.counter)." + listMarkerSeparator
        }
    }

    private static let paragraphStyleForP: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = paragraphSpacing
        return style
    }()

    private static func ensureTrailingNewline(in result: NSMutableAttributedString) {
        trimTrailingCollapsedSpace(in: result)
        guard result.length > 0, !result.string.hasSuffix(newline) else { return }
        result.append(NSAttributedString(string: newline))
    }

    /// Appends a small-font NBSP + newline so SwiftUI Text renders a visible
    /// gap between block-level elements (`<p>`, `<li>`). Used because
    /// `NSParagraphStyle.paragraphSpacing` is ignored by `Text(AttributedString)`.
    private static func appendBlockSpacer(to result: NSMutableAttributedString, fontSize: CGFloat) {
        let spacer = NSAttributedString(
            string: paragraphSpacerCharacter + newline,
            attributes: [.font: UIFont.systemFont(ofSize: fontSize)]
        )
        result.append(spacer)
    }

    /// Ensures a visible gap precedes a block-level element opening (`<p>`,
    /// `<ul>`, `<ol>`) when there's already content above it. No-op when:
    /// - the document is empty (block is the very first content);
    /// - we're inside an `<li>` whose marker prefix was just emitted (the
    ///   block flows into the marker line; common WYSIWYG pattern).
    private static func insertBlockSeparatorIfNeeded(
        in result: NSMutableAttributedString,
        listItemStarts: [OpenListItem],
        spacerFontSize: CGFloat
    ) {
        if listItemStarts.last?.contentStart == result.length { return }
        ensureTrailingNewline(in: result)
        guard result.length > newline.count else { return }
        appendBlockSpacer(to: result, fontSize: spacerFontSize)
    }

    private static func appendCollapsedText(
        _ text: String,
        to result: NSMutableAttributedString,
        stack: [Tag],
        baseFont: UIFont?,
        pendingWhitespaceTags: inout [Tag]?
    ) {
        var visibleRun = ""
        let currentAttributes = buildAttributes(from: stack, baseFont: baseFont)
        var hasVisibleText = result.string.last.map { !isCollapsedWhitespaceBoundary($0) } ?? false

        func flushVisibleRun() {
            guard !visibleRun.isEmpty else { return }
            result.append(NSAttributedString(string: visibleRun, attributes: currentAttributes))
            visibleRun = ""
        }

        for character in text {
            if isCollapsibleHTMLWhitespace(character) {
                flushVisibleRun()
                if pendingWhitespaceTags == nil, hasVisibleText {
                    pendingWhitespaceTags = stack
                }
            } else {
                if let authoredTags = pendingWhitespaceTags {
                    let authoredAttributes = buildAttributes(from: authoredTags, baseFont: baseFont)
                    result.append(NSAttributedString(string: " ", attributes: authoredAttributes))
                    pendingWhitespaceTags = nil
                }
                visibleRun.append(character)
                hasVisibleText = true
            }
        }

        flushVisibleRun()
    }

    private static func trimTrailingCollapsedSpace(in result: NSMutableAttributedString) {
        while result.string.last == " " {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }
    }

    private static func isCollapsedWhitespaceBoundary(_ character: Character) -> Bool {
        character == " " || character == "\n"
    }

    private static func isCollapsibleHTMLWhitespace(_ character: Character) -> Bool {
        switch character {
        case " ", "\n", "\t", "\r", "\r\n", "\u{000C}":
            return true
        default:
            return false
        }
    }

    private static func applyParagraphStyles(
        to result: NSMutableAttributedString,
        ranges: [(NSRange, NSParagraphStyle)]
    ) {
        for (range, style) in ranges {
            let clamped = NSRange(
                location: range.location,
                length: min(range.length, result.length - range.location)
            )
            guard clamped.length > 0 else { continue }
            result.addAttribute(.paragraphStyle, value: style, range: clamped)
        }
    }

    // MARK: - Tag scanning

    private static func scanTag(
        in html: String,
        from start: String.Index
    ) -> (Tag, String.Index)? {
        guard html[start] == "<" else { return nil }

        var idx = html.index(after: start)
        guard idx < html.endIndex else { return nil }

        let isClosing = html[idx] == "/"
        if isClosing {
            idx = html.index(after: idx)
            guard idx < html.endIndex else { return nil }
        }

        guard isASCIIAlpha(html[idx]) else { return nil }
        let nameStart = idx
        while idx < html.endIndex, isASCIIAlpha(html[idx]) || isASCIIDigit(html[idx]) || html[idx] == "-" {
            idx = html.index(after: idx)
        }
        let name = String(html[nameStart..<idx]).lowercased()
        guard !name.isEmpty else { return nil }

        var attributes: [String: String] = [:]

        if !isClosing {
            while idx < html.endIndex, html[idx] != ">", html[idx] != "/" {
                idx = skipWhitespace(in: html, from: idx)
                if idx >= html.endIndex || html[idx] == ">" || html[idx] == "/" { break }

                let (attrName, attrEnd) = scanWord(in: html, from: idx)
                idx = attrEnd
                guard !attrName.isEmpty else { idx = advanceSafely(html, idx); continue }

                idx = skipWhitespace(in: html, from: idx)

                if idx < html.endIndex, html[idx] == "=" {
                    idx = html.index(after: idx)
                    idx = skipWhitespace(in: html, from: idx)
                    let (value, valueEnd) = scanAttributeValue(in: html, from: idx)
                    idx = valueEnd
                    attributes[attrName.lowercased()] = decodeHTMLEntities(value)
                }
            }
        } else {
            idx = skipWhitespace(in: html, from: idx)
        }

        if idx < html.endIndex, html[idx] == "/" {
            idx = html.index(after: idx)
        }
        guard idx < html.endIndex, html[idx] == ">" else { return nil }
        idx = html.index(after: idx)

        return (
            Tag(name: name, isClosing: isClosing, attributes: attributes),
            idx
        )
    }

    // MARK: - Text scanning

    private static func scanText(
        in html: String,
        from start: String.Index
    ) -> (String, String.Index) {
        var idx = start
        while idx < html.endIndex, html[idx] != "<" {
            idx = html.index(after: idx)
        }
        return (String(html[start..<idx]), idx)
    }

    // MARK: - Attribute value scanning

    private static func scanAttributeValue(
        in html: String,
        from start: String.Index
    ) -> (String, String.Index) {
        guard start < html.endIndex else { return ("", start) }

        if html[start] == "\"" || html[start] == "'" {
            let quote = html[start]
            var idx = html.index(after: start)
            let valueStart = idx
            while idx < html.endIndex, html[idx] != quote {
                idx = html.index(after: idx)
            }
            let value = String(html[valueStart..<idx])
            if idx < html.endIndex { idx = html.index(after: idx) }
            return (value, idx)
        }

        var idx = start
        while idx < html.endIndex, html[idx] != ">", !html[idx].isWhitespace {
            idx = html.index(after: idx)
        }
        return (String(html[start..<idx]), idx)
    }

    // MARK: - Attribute building

    private static func buildAttributes(
        from tagStack: [Tag],
        baseFont: UIFont?
    ) -> [NSAttributedString.Key: Any] {
        var isBold = false
        var isItalic = false
        var isUnderline = false
        var isStrikethrough = false
        var linkURL: URL?
        var foregroundColor: UIColor?

        for tag in tagStack {
            switch tag.name {
            case "b", "strong": isBold = true
            case "i", "em": isItalic = true
            case "u": isUnderline = true
            case "s", "strike": isStrikethrough = true
            case "a":
                if let href = tag.attributes["href"] { linkURL = URL(string: href) }
            case "font":
                if let color = tag.attributes["color"] { foregroundColor = UIColor(hexString: color) }
            default: break
            }
        }

        var attrs: [NSAttributedString.Key: Any] = [:]

        let resolvedFont = baseFont ?? .systemFont(ofSize: UIFont.systemFontSize)
        var font = resolvedFont
        if isBold, let bold = font.including(symbolicTraits: .traitBold) { font = bold }
        if isItalic, let italic = font.including(symbolicTraits: .traitItalic) { font = italic }
        attrs[.font] = font

        if let foregroundColor { attrs[.foregroundColor] = foregroundColor }
        if isUnderline { attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue }
        if isStrikethrough { attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
        if let linkURL { attrs[.link] = linkURL }

        return attrs
    }

    // MARK: - HTML entity decoding

    private static func decodeHTMLEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }

        var result = ""
        result.reserveCapacity(text.count)
        var idx = text.startIndex

        while idx < text.endIndex {
            if text[idx] == "&" {
                let entityStart = idx
                idx = text.index(after: idx)
                var entityName = ""
                while idx < text.endIndex, text[idx] != ";", entityName.count < 10 {
                    entityName.append(text[idx])
                    idx = text.index(after: idx)
                }
                if idx < text.endIndex, text[idx] == ";" {
                    idx = text.index(after: idx)
                    if let resolved = resolveEntity(entityName) {
                        result.append(resolved)
                    } else {
                        result.append(contentsOf: text[entityStart..<idx])
                    }
                } else {
                    result.append(contentsOf: text[entityStart..<idx])
                }
            } else {
                result.append(text[idx])
                idx = text.index(after: idx)
            }
        }

        return result
    }

    private static func resolveEntity(_ name: String) -> Character? {
        switch name {
        case "amp": return "&"
        case "lt": return "<"
        case "gt": return ">"
        case "quot": return "\""
        case "apos": return "'"
        case "nbsp": return "\u{00A0}"
        default:
            if name.hasPrefix("#x") || name.hasPrefix("#X") {
                let hex = String(name.dropFirst(2))
                if let cp = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(cp) {
                    return Character(scalar)
                }
            } else if name.hasPrefix("#") {
                let decimal = String(name.dropFirst(1))
                if let cp = UInt32(decimal, radix: 10), let scalar = Unicode.Scalar(cp) {
                    return Character(scalar)
                }
            }
            return nil
        }
    }

    // MARK: - Scanning helpers

    private static func scanWord(
        in html: String,
        from start: String.Index
    ) -> (String, String.Index) {
        var idx = start
        while idx < html.endIndex,
              html[idx] != "=", html[idx] != ">", html[idx] != "/", !html[idx].isWhitespace {
            idx = html.index(after: idx)
        }
        return (String(html[start..<idx]), idx)
    }

    private static func skipWhitespace(in html: String, from start: String.Index) -> String.Index {
        var idx = start
        while idx < html.endIndex, html[idx].isWhitespace { idx = html.index(after: idx) }
        return idx
    }

    private static func advanceSafely(_ html: String, _ idx: String.Index) -> String.Index {
        idx < html.endIndex ? html.index(after: idx) : idx
    }

    private static func isASCIIAlpha(_ character: Character) -> Bool {
        character.unicodeScalars.count == 1 && character.unicodeScalars.first.map {
            (65...90).contains($0.value) || (97...122).contains($0.value)
        } == true
    }

    private static func isASCIIDigit(_ character: Character) -> Bool {
        character.unicodeScalars.count == 1 && character.unicodeScalars.first.map {
            (48...57).contains($0.value)
        } == true
    }
}
