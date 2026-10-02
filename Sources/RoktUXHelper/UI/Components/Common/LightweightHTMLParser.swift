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
/// Also decodes numeric character references (`&#NNN;`, `&#xHHH;`) and the
/// named entities in `namedEntities` (`&amp;`, `&nbsp;`, `&copy;`, `&rsquo;`, …).
@available(iOS 15, *)
enum LightweightHTMLParser {

    // MARK: - Constants

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
    private static let spaceUnit = unichar(0x20)
    private static let newlineUnit = unichar(0x0A)
    /// `scanTag` accepts any ASCII letter/digit/hyphen name, not just the
    /// documented tag set, so a misnesting/stray-tag warning must not log a
    /// tag name verbatim — it may be a slice of authored content (e.g. an
    /// unescaped "<" in campaign copy) rather than an actual supported tag.
    private static let knownTagNames: Set<String> = [
        "b", "strong", "i", "em", "u", "s", "strike", "a", "font", "br", "p", "ul", "ol", "li"
    ]

    private static func loggableTagName(_ name: String) -> String {
        knownTagNames.contains(name) ? name : "tag"
    }

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
        var builder = Builder(
            baseFont: baseFont,
            spacerFontSize: blockSpacerHeight.map { $0 * blockSpacerLineHeightRatio } ?? paragraphSpacerFontSize
        )
        var rest = html[...]
        // A tag needs a closing ">". After the last one, a "<" can only be text,
        // so skip the scan instead of rereading the rest of the input each time.
        let lastTagEnd = html.utf8.lastIndex(of: UInt8(ascii: ">"))

        while !rest.isEmpty {
            if rest.hasPrefix("<!--") {
                rest = rest[(rest.range(of: "-->")?.upperBound ?? rest.endIndex)...]
            } else if rest.first == "<", let lastTagEnd, rest.startIndex < lastTagEnd,
                      let (tag, afterTag) = scanTag(rest) {
                builder.handle(tag)
                rest = afterTag
            } else {
                // A `<` that does not start a tag is literal text.
                let textEnd = rest.dropFirst().firstIndex(of: "<") ?? rest.endIndex
                builder.appendText(decodeHTMLEntities(rest[..<textEnd]))
                rest = rest[textEnd...]
            }
        }

        return builder.result
    }

    // MARK: - Model

    private struct Tag {
        let name: String
        let isClosing: Bool
        let attributes: [String: String]
    }

    private struct ListContext {
        let isOrdered: Bool
        var counter = 1
        /// Whether the most recently closed `<li>` at this depth contained a
        /// block-level child (currently `<p>`). Drives the CSS-style rule
        /// that bare `<li>` siblings sit flush (no inter-item gap) while
        /// `<li><p>...</p></li>` siblings get a spacer from the `<p>`'s
        /// implied margin.
        var lastClosedHadBlock = false

        var marker: String {
            (isOrdered ? "\(counter)." : "•") + listMarkerSeparator
        }
    }

    private struct OpenListItem {
        let contentStart: Int
        let depth: Int
        var containedBlock = false
    }

    private static let paragraphStyleForP: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = paragraphSpacing
        return style
    }()

    // MARK: - Builder

    /// Accumulates output while the scanner walks the HTML. Block tags (`p`,
    /// `ul`, `ol`, `li`, `br`) only shape structure, so `tagStack` holds just
    /// the inline tags whose styles apply to text.
    private struct Builder {
        let baseFont: UIFont?
        let spacerFontSize: CGFloat
        let result = NSMutableAttributedString()
        var tagStack: [Tag] = []
        var paragraphStart: Int?
        var lists: [ListContext] = []
        var openItems: [OpenListItem] = []
        // Keep the tags from the first space in a collapsed run. A tag may close
        // before the space is emitted, or a different tag may open after it.
        var pendingSpaceTags: [Tag]?

        /// The last UTF-16 unit of the output. `result.string` would copy the whole
        /// output on every read, making parsing quadratic in the input size.
        private var lastUnit: unichar? {
            result.length > 0 ? result.mutableString.character(at: result.length - 1) : nil
        }

        mutating func handle(_ tag: Tag) {
            if tag.isClosing {
                close(tag)
            } else {
                open(tag)
            }
        }

        private mutating func open(_ tag: Tag) {
            switch tag.name {
            case "br":
                pendingSpaceTags = nil
                result.append(NSAttributedString(string: "\n"))
            case "p":
                pendingSpaceTags = nil
                // If a previous <p> is still open (no explicit </p>), finalize it
                // so its range is preserved instead of overwritten.
                finalizeParagraph()
                insertBlockSeparatorIfNeeded()
                // Mark the innermost open <li> as block-bearing so its closing
                // propagates the flag to ListContext.lastClosedHadBlock.
                if !openItems.isEmpty {
                    openItems[openItems.count - 1].containedBlock = true
                }
                paragraphStart = result.length
            case "ul", "ol":
                pendingSpaceTags = nil
                insertBlockSeparatorIfNeeded()
                lists.append(ListContext(isOrdered: tag.name == "ol"))
            case "li":
                // An `<li>` outside a list renders as plain text.
                guard !lists.isEmpty else { return }
                pendingSpaceTags = nil
                openListItem()
            default:
                tagStack.append(tag)
            }
        }

        private mutating func close(_ tag: Tag) {
            switch tag.name {
            case "p":
                pendingSpaceTags = nil
                finalizeParagraph()
            case "li":
                pendingSpaceTags = nil
                if !lists.isEmpty, !openItems.isEmpty {
                    finalizeListItem()
                }
            case "ul", "ol":
                pendingSpaceTags = nil
                guard !lists.isEmpty else { return }
                // `</li>` is optional, so closing a list also ends its open items.
                while let item = openItems.last, item.depth >= lists.count - 1 {
                    finalizeListItem()
                }
                lists.removeLast()
            default:
                if let index = tagStack.lastIndex(where: { $0.name == tag.name }) {
                    if index != tagStack.count - 1 {
                        let stillOpen = tagStack[(index + 1)...]
                            .map { loggableTagName($0.name) }
                            .joined(separator: ", ")
                        RoktUXLogger.shared.warning(
                            "</\(loggableTagName(tag.name))> closed while [\(stillOpen)] were still open "
                                + "inside it; the markup is misnested and may render unexpectedly."
                        )
                    }
                    tagStack.remove(at: index)
                } else {
                    RoktUXLogger.shared.warning(
                        "</\(loggableTagName(tag.name))> closed but no matching open tag was found; "
                            + "the markup has a stray closing tag and this one is ignored."
                    )
                }
            }
        }

        // MARK: Blocks

        private mutating func openListItem() {
            let depth = lists.count - 1
            // HTML5 allows omitting </li>, so a new sibling ends the previous one.
            if openItems.last?.depth == depth {
                finalizeListItem()
            }
            ensureTrailingNewline()
            // CSS analogue: bare `<li>` has `margin: 0` (no gap), but a `<p>`
            // child contributes its own margin. We emit the spacer only when
            // the prior sibling at this depth contained a block child.
            if lists[depth].counter > 1, lists[depth].lastClosedHadBlock {
                appendBlockSpacer()
            }
            // The marker inherits the active inline styles so it matches
            // surrounding font/color/etc. (e.g. <font color=...><ul>...).
            result.append(NSAttributedString(string: lists[depth].marker, attributes: attributes(for: tagStack)))
            openItems.append(OpenListItem(contentStart: result.length, depth: depth))
        }

        private mutating func finalizeListItem() {
            let item = openItems.removeLast()
            ensureTrailingNewline()
            if item.depth < lists.count {
                lists[item.depth].counter += 1
                lists[item.depth].lastClosedHadBlock = item.containedBlock
            }
        }

        private mutating func finalizeParagraph() {
            guard let start = paragraphStart else { return }
            paragraphStart = nil
            ensureTrailingNewline()
            let range = NSRange(location: start, length: result.length - start)
            if range.length > 0 {
                result.addAttribute(.paragraphStyle, value: paragraphStyleForP, range: range)
            }
        }

        /// Ensures a visible gap precedes a block-level element opening (`<p>`,
        /// `<ul>`, `<ol>`) when there's already content above it. No-op when:
        /// - the document is empty (block is the very first content);
        /// - we're inside an `<li>` whose marker prefix was just emitted (the
        ///   block flows into the marker line; common WYSIWYG pattern).
        private func insertBlockSeparatorIfNeeded() {
            if openItems.last?.contentStart == result.length { return }
            ensureTrailingNewline()
            guard result.length > 1 else { return }
            appendBlockSpacer()
        }

        private func ensureTrailingNewline() {
            // Drop the separator left by an empty list item before breaking the line.
            while lastUnit == spaceUnit {
                result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
            }
            if let last = lastUnit, last != newlineUnit {
                result.append(NSAttributedString(string: "\n"))
            }
        }

        /// Appends a small-font NBSP + newline so SwiftUI Text renders a visible
        /// gap between block-level elements (`<p>`, `<li>`). Used because
        /// `NSParagraphStyle.paragraphSpacing` is ignored by `Text(AttributedString)`.
        private func appendBlockSpacer() {
            result.append(NSAttributedString(
                string: paragraphSpacerCharacter + "\n",
                attributes: [.font: UIFont.systemFont(ofSize: spacerFontSize)]
            ))
        }

        // MARK: Inline text

        /// Appends `text` with HTML whitespace collapsed to single spaces. A
        /// space is held back until visible text follows it, so runs never
        /// start or end with collapsed whitespace.
        mutating func appendText(_ text: String) {
            let endsWithVisibleText = lastUnit.map { $0 != spaceUnit && $0 != newlineUnit } ?? false
            var run = ""

            for character in text {
                if isCollapsibleWhitespace(character) {
                    if pendingSpaceTags == nil, endsWithVisibleText || !run.isEmpty {
                        pendingSpaceTags = tagStack
                    }
                    continue
                }
                if let spaceTags = pendingSpaceTags {
                    pendingSpaceTags = nil
                    if run.isEmpty {
                        // The space came from an earlier text node and keeps that node's style.
                        result.append(NSAttributedString(string: " ", attributes: attributes(for: spaceTags)))
                    } else {
                        run.append(" ")
                    }
                }
                run.append(character)
            }

            if !run.isEmpty {
                result.append(NSAttributedString(string: run, attributes: attributes(for: tagStack)))
            }
        }

        private func attributes(for tags: [Tag]) -> [NSAttributedString.Key: Any] {
            var isBold = false
            var isItalic = false
            var attributes: [NSAttributedString.Key: Any] = [:]

            for tag in tags {
                switch tag.name {
                case "b", "strong": isBold = true
                case "i", "em": isItalic = true
                case "u": attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                case "s", "strike": attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                case "a":
                    if let url = tag.attributes["href"].flatMap(URL.init(string:)) {
                        attributes[.link] = url
                    }
                case "font":
                    if let color = tag.attributes["color"] {
                        attributes[.foregroundColor] = UIColor(hexString: color)
                    }
                default: break
                }
            }

            var font = baseFont ?? .systemFont(ofSize: UIFont.systemFontSize)
            if isBold, let bold = font.including(symbolicTraits: .traitBold) { font = bold }
            if isItalic, let italic = font.including(symbolicTraits: .traitItalic) { font = italic }
            attributes[.font] = font
            return attributes
        }
    }

    private static func isCollapsibleWhitespace(_ character: Character) -> Bool {
        switch character {
        case " ", "\n", "\t", "\r", "\r\n", "\u{000C}":
            return true
        default:
            return false
        }
    }

    // MARK: - Tag scanning

    /// Scans the tag at the start of `input`, returning it and the text after
    /// its `>`. Returns `nil` when `input` does not start with a complete tag,
    /// so the caller can render the `<` as text.
    private static func scanTag(_ input: Substring) -> (Tag, Substring)? {
        var rest = input.dropFirst()
        let isClosing = rest.first == "/"
        if isClosing { rest = rest.dropFirst() }

        guard let first = rest.first, first.isASCII, first.isLetter else { return nil }
        let name = rest.prefix { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
        rest = rest[name.endIndex...]

        var attributes: [String: String] = [:]
        while !isClosing {
            rest = rest.drop(while: \.isWhitespace)
            guard let next = rest.first, next != ">", next != "/" else { break }

            let attributeName = rest.prefix { !"=>/".contains($0) && !$0.isWhitespace }
            guard !attributeName.isEmpty else {
                rest = rest.dropFirst()
                continue
            }
            rest = rest[attributeName.endIndex...].drop(while: \.isWhitespace)
            guard rest.first == "=" else { continue }
            rest = rest.dropFirst().drop(while: \.isWhitespace)

            let value: Substring
            if let quote = rest.first, quote == "\"" || quote == "'" {
                value = rest.dropFirst().prefix { $0 != quote }
                rest = rest[value.endIndex...].dropFirst()
            } else {
                value = rest.prefix { $0 != ">" && !$0.isWhitespace }
                rest = rest[value.endIndex...]
            }
            attributes[attributeName.lowercased()] = decodeHTMLEntities(value)
        }

        rest = rest.drop(while: \.isWhitespace)
        if rest.first == "/" { rest = rest.dropFirst() }
        guard rest.first == ">" else { return nil }

        return (Tag(name: name.lowercased(), isClosing: isClosing, attributes: attributes), rest.dropFirst())
    }

    // MARK: - HTML entity decoding

    private static func decodeHTMLEntities(_ text: Substring) -> String {
        var result = ""
        var rest = text

        while let ampersand = rest.firstIndex(of: "&") {
            result += rest[..<ampersand]
            rest = rest[rest.index(after: ampersand)...]
            // Names are at most 10 characters. An unresolved `&` is kept as text
            // and scanning resumes right after it, so it cannot hide a later entity.
            if let semicolon = rest.prefix(11).firstIndex(of: ";"),
               let decoded = resolveEntity(rest[..<semicolon]) {
                result.append(decoded)
                rest = rest[rest.index(after: semicolon)...]
            } else {
                result.append("&")
            }
        }

        return result + rest
    }

    private static func resolveEntity(_ name: Substring) -> Character? {
        if let named = namedEntities[String(name)] { return named }
        guard name.first == "#" else { return nil }

        let number = name.dropFirst()
        let codePoint = number.first == "x" || number.first == "X"
            ? UInt32(number.dropFirst(), radix: 16)
            : UInt32(number)
        return codePoint.flatMap { Unicode.Scalar($0) }.map(Character.init)
    }

    // HTML 4 Latin-1 plus common punctuation. Greek and math symbol names are
    // omitted; add them here if authored copy needs them.
    private static let namedEntities: [String: Character] = {
        var entities: [String: Character] = [
            "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'",
            "OElig": "Œ", "oelig": "œ", "Scaron": "Š", "scaron": "š", "Yuml": "Ÿ", "fnof": "ƒ",
            "circ": "ˆ", "tilde": "˜", "ensp": "\u{2002}", "emsp": "\u{2003}", "thinsp": "\u{2009}",
            "zwnj": "\u{200C}", "zwj": "\u{200D}", "lrm": "\u{200E}", "rlm": "\u{200F}",
            "ndash": "–", "mdash": "—", "lsquo": "‘", "rsquo": "’", "sbquo": "‚",
            "ldquo": "“", "rdquo": "”", "bdquo": "„", "dagger": "†", "Dagger": "‡",
            "bull": "•", "hellip": "…", "permil": "‰", "prime": "′", "Prime": "″",
            "lsaquo": "‹", "rsaquo": "›", "euro": "€", "trade": "™", "minus": "−",
            "larr": "←", "rarr": "→"
        ]
        // Names for U+00A0 through U+00FF, in code point order.
        let latin1 = """
            nbsp iexcl cent pound curren yen brvbar sect uml copy ordf laquo not shy reg macr
            deg plusmn sup2 sup3 acute micro para middot cedil sup1 ordm raquo frac14 frac12 frac34 iquest
            Agrave Aacute Acirc Atilde Auml Aring AElig Ccedil Egrave Eacute Ecirc Euml Igrave Iacute Icirc Iuml
            ETH Ntilde Ograve Oacute Ocirc Otilde Ouml times Oslash Ugrave Uacute Ucirc Uuml Yacute THORN szlig
            agrave aacute acirc atilde auml aring aelig ccedil egrave eacute ecirc euml igrave iacute icirc iuml
            eth ntilde ograve oacute ocirc otilde ouml divide oslash ugrave uacute ucirc uuml yacute thorn yuml
            """
        for (offset, name) in latin1.split(whereSeparator: \.isWhitespace).enumerated() {
            entities[String(name)] = Character(Unicode.Scalar(UInt8(0xA0 + offset)))
        }
        return entities
    }()
}
