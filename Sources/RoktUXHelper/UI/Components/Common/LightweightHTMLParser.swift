//
//  LightweightHTMLParser.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import UIKit

/// Synchronous HTML-to-NSAttributedString parser that avoids WebKit entirely.
///
/// Supports the DCUI rich text tag surface:
///   `<b>`, `<strong>`, `<i>`, `<em>`, `<u>`, `<s>`, `<strike>`,
///   `<a href="…" target="…">`, `<font color="…">`, `<br>`, `<br/>`
///
/// Also decodes common HTML entities (`&amp;`, `&lt;`, `&gt;`, `&quot;`,
/// `&apos;`, `&nbsp;`, `&#NNN;`, `&#xHHH;`).
@available(iOS 15, *)
enum LightweightHTMLParser {

    // MARK: - Public API

    static func parse(html: String, baseFont: UIFont?) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        var index = html.startIndex
        var tagStack: [Tag] = []

        while index < html.endIndex {
            if html[index] == "<" {
                if let (tag, nextIndex) = scanTag(in: html, from: index) {
                    index = nextIndex
                    handleTag(tag, stack: &tagStack, result: result)
                } else {
                    let attrs = buildAttributes(from: tagStack, baseFont: baseFont)
                    result.append(NSAttributedString(string: "<", attributes: attrs))
                    index = html.index(after: index)
                }
            } else {
                let (text, nextIndex) = scanText(in: html, from: index)
                index = nextIndex
                let decoded = decodeHTMLEntities(text)
                if !decoded.isEmpty {
                    let attrs = buildAttributes(from: tagStack, baseFont: baseFont)
                    result.append(NSAttributedString(string: decoded, attributes: attrs))
                }
            }
        }

        return result
    }

    // MARK: - Tag model

    struct Tag {
        let name: String
        let isClosing: Bool
        let isSelfClosing: Bool
        let attributes: [String: String]
    }

    // MARK: - Tag dispatch

    private static func handleTag(
        _ tag: Tag,
        stack: inout [Tag],
        result: NSMutableAttributedString
    ) {
        if tag.isClosing {
            if let idx = stack.lastIndex(where: { $0.name == tag.name }) {
                stack.remove(at: idx)
            }
        } else if tag.isSelfClosing || tag.name == "br" {
            result.append(NSAttributedString(string: "\n"))
        } else {
            stack.append(tag)
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

        let nameStart = idx
        while idx < html.endIndex, html[idx].isLetter || html[idx].isNumber {
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
                    attributes[attrName.lowercased()] = value
                }
            }
        } else {
            idx = skipWhitespace(in: html, from: idx)
        }

        var isSelfClosing = false
        if idx < html.endIndex, html[idx] == "/" {
            isSelfClosing = true
            idx = html.index(after: idx)
        }
        if idx < html.endIndex, html[idx] == ">" {
            idx = html.index(after: idx)
        }

        return (
            Tag(name: name, isClosing: isClosing, isSelfClosing: isSelfClosing, attributes: attributes),
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
        while idx < html.endIndex, html[idx] != ">", html[idx] != "/", !html[idx].isWhitespace {
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
}
