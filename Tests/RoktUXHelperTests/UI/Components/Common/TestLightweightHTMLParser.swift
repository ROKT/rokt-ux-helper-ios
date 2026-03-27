import XCTest
import SwiftUI
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestLightweightHTMLParser: XCTestCase {

    private let baseFont = UIFont.systemFont(ofSize: 16)

    // MARK: - Plain text (no tags)

    func test_plain_text() {
        let result = LightweightHTMLParser.parse(html: "Hello World", baseFont: baseFont)
        XCTAssertEqual(result.string, "Hello World")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font, baseFont)
    }

    func test_empty_string() {
        let result = LightweightHTMLParser.parse(html: "", baseFont: baseFont)
        XCTAssertEqual(result.string, "")
    }

    // MARK: - Bold

    func test_bold_b_tag() {
        let result = LightweightHTMLParser.parse(html: "<b>Bold</b>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Bold")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
    }

    func test_bold_strong_tag() {
        let result = LightweightHTMLParser.parse(html: "<strong>Bold</strong>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Bold")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
    }

    // MARK: - Italic

    func test_italic_i_tag() {
        let result = LightweightHTMLParser.parse(html: "<i>Italic</i>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Italic")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)
    }

    func test_italic_em_tag() {
        let result = LightweightHTMLParser.parse(html: "<em>Italic</em>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Italic")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)
    }

    // MARK: - Underline

    func test_underline() {
        let result = LightweightHTMLParser.parse(html: "<u>Underlined</u>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Underlined")

        let underline = result.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int
        XCTAssertEqual(underline, NSUnderlineStyle.single.rawValue)
    }

    // MARK: - Strikethrough

    func test_strikethrough_s_tag() {
        let result = LightweightHTMLParser.parse(html: "<s>Struck</s>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Struck")

        let strike = result.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
        XCTAssertEqual(strike, NSUnderlineStyle.single.rawValue)
    }

    func test_strikethrough_strike_tag() {
        let result = LightweightHTMLParser.parse(html: "<strike>Struck</strike>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Struck")

        let strike = result.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
        XCTAssertEqual(strike, NSUnderlineStyle.single.rawValue)
    }

    // MARK: - Links

    func test_link_with_href() {
        let result = LightweightHTMLParser.parse(
            html: "<a href=\"https://rokt.com\">Rokt</a>",
            baseFont: baseFont
        )
        XCTAssertEqual(result.string, "Rokt")

        let link = result.attribute(.link, at: 0, effectiveRange: nil) as? URL
        XCTAssertEqual(link, URL(string: "https://rokt.com"))
    }

    func test_link_with_target_attribute() {
        let result = LightweightHTMLParser.parse(
            html: "<a href=\"https://rokt.com/privacy\" target=\"_blank\">Privacy</a>",
            baseFont: baseFont
        )
        XCTAssertEqual(result.string, "Privacy")

        let link = result.attribute(.link, at: 0, effectiveRange: nil) as? URL
        XCTAssertEqual(link, URL(string: "https://rokt.com/privacy"))
    }

    // MARK: - Font color

    func test_font_color_unquoted() {
        let result = LightweightHTMLParser.parse(
            html: "<font color=#FF0000>Red</font>",
            baseFont: baseFont
        )
        XCTAssertEqual(result.string, "Red")

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertNotNil(color)
    }

    func test_font_color_quoted() {
        let result = LightweightHTMLParser.parse(
            html: "<font color=\"#00FF00\">Green</font>",
            baseFont: baseFont
        )
        XCTAssertEqual(result.string, "Green")

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertNotNil(color)
    }

    func test_font_color_does_not_bleed_outside_tag() {
        let result = LightweightHTMLParser.parse(
            html: "Before <font color=#FF0000>Red</font> After",
            baseFont: baseFont
        )
        XCTAssertEqual(result.string, "Before Red After")

        let colorInside = result.attribute(.foregroundColor, at: 7, effectiveRange: nil) as? UIColor
        XCTAssertNotNil(colorInside)

        let colorOutside = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertNil(colorOutside)
    }

    // MARK: - Line break

    func test_br_tag() {
        let result = LightweightHTMLParser.parse(html: "Line1<br>Line2", baseFont: baseFont)
        XCTAssertEqual(result.string, "Line1\nLine2")
    }

    func test_self_closing_br_tag() {
        let result = LightweightHTMLParser.parse(html: "Line1<br/>Line2", baseFont: baseFont)
        XCTAssertEqual(result.string, "Line1\nLine2")
    }

    // MARK: - Nested tags (DCUI fixture)

    func test_dcui_fixture_strong_em_u_s() {
        let html = "<strong><em><u>ORDER</u> <s>Number</s>: Uk171359906</em></strong>"
        let result = LightweightHTMLParser.parse(html: html, baseFont: baseFont)

        XCTAssertEqual(result.string, "ORDER Number: Uk171359906")

        let fontAtZero = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(fontAtZero?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
        XCTAssertEqual(fontAtZero?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)

        let underlineRange = NSRange(location: 0, length: 5)
        let underlineAttr = result.attributedSubstring(from: underlineRange)
        underlineAttr.enumerateAttributes(in: NSRange(location: 0, length: 5), options: []) { dict, _, _ in
            XCTAssertTrue(dict.keys.contains(.underlineStyle))
        }

        let strikeRange = NSRange(location: 6, length: 6)
        let strikeAttr = result.attributedSubstring(from: strikeRange)
        strikeAttr.enumerateAttributes(in: NSRange(location: 0, length: 6), options: []) { dict, _, _ in
            XCTAssertTrue(dict.keys.contains(.strikethroughStyle))
        }
    }

    func test_dcui_fixture_with_font_color_wrapper() {
        let html = "<font color=#AABBCC><strong><em><u>ORDER</u> <s>Number</s>: Uk171359906</em></strong></font>"
        let result = LightweightHTMLParser.parse(html: html, baseFont: baseFont)

        XCTAssertEqual(result.string, "ORDER Number: Uk171359906")

        let foregroundColor = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertNotNil(foregroundColor)
        XCTAssertEqual(foregroundColor?.isEqualIgnoringSpaceContext(UIColor(hexString: "#AABBCC")), true)
    }

    // MARK: - Bold + Italic combined

    func test_bold_italic_combined() {
        let result = LightweightHTMLParser.parse(html: "<b><i>BoldItalic</i></b>", baseFont: baseFont)
        XCTAssertEqual(result.string, "BoldItalic")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)
    }

    // MARK: - Mixed styled and unstyled text

    func test_partial_bold() {
        let result = LightweightHTMLParser.parse(html: "Get <b>20% off</b> today", baseFont: baseFont)
        XCTAssertEqual(result.string, "Get 20% off today")

        let fontPlain = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(fontPlain?.fontDescriptor.symbolicTraits.contains(.traitBold), false)

        let fontBold = result.attribute(.font, at: 4, effectiveRange: nil) as? UIFont
        XCTAssertEqual(fontBold?.fontDescriptor.symbolicTraits.contains(.traitBold), true)

        let fontAfter = result.attribute(.font, at: 12, effectiveRange: nil) as? UIFont
        XCTAssertEqual(fontAfter?.fontDescriptor.symbolicTraits.contains(.traitBold), false)
    }

    // MARK: - Nil base font (falls back to system font)

    func test_nil_base_font_still_applies_bold() {
        let result = LightweightHTMLParser.parse(html: "<b>Bold</b>", baseFont: nil)
        XCTAssertEqual(result.string, "Bold")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
    }

    func test_nil_base_font_still_applies_italic() {
        let result = LightweightHTMLParser.parse(html: "<i>Italic</i>", baseFont: nil)
        XCTAssertEqual(result.string, "Italic")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)
    }

    func test_nil_base_font_uses_system_font_size() {
        let result = LightweightHTMLParser.parse(html: "Plain", baseFont: nil)
        XCTAssertEqual(result.string, "Plain")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertEqual(font?.pointSize, UIFont.systemFontSize)
    }

    // MARK: - HTML entities

    func test_html_entities_amp_lt_gt() {
        let result = LightweightHTMLParser.parse(html: "A &amp; B &lt; C &gt; D", baseFont: baseFont)
        XCTAssertEqual(result.string, "A & B < C > D")
    }

    func test_html_entities_quot_apos() {
        let result = LightweightHTMLParser.parse(html: "&quot;hello&quot; &apos;world&apos;", baseFont: baseFont)
        XCTAssertEqual(result.string, "\"hello\" 'world'")
    }

    func test_html_entity_nbsp() {
        let result = LightweightHTMLParser.parse(html: "no&nbsp;break", baseFont: baseFont)
        XCTAssertEqual(result.string, "no\u{00A0}break")
    }

    func test_numeric_decimal_entity() {
        let result = LightweightHTMLParser.parse(html: "&#65;&#66;&#67;", baseFont: baseFont)
        XCTAssertEqual(result.string, "ABC")
    }

    func test_numeric_hex_entity() {
        let result = LightweightHTMLParser.parse(html: "&#x41;&#x42;&#x43;", baseFont: baseFont)
        XCTAssertEqual(result.string, "ABC")
    }

    func test_unknown_entity_preserved() {
        let result = LightweightHTMLParser.parse(html: "&unknown;", baseFont: baseFont)
        XCTAssertEqual(result.string, "&unknown;")
    }

    // MARK: - Case insensitivity

    func test_uppercase_tags() {
        let result = LightweightHTMLParser.parse(html: "<B>Bold</B>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Bold")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
    }

    func test_mixed_case_tags() {
        let result = LightweightHTMLParser.parse(html: "<Strong>Bold</Strong>", baseFont: baseFont)
        XCTAssertEqual(result.string, "Bold")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
    }

    // MARK: - Malformed HTML resilience

    func test_unclosed_tag_still_renders_text() {
        let result = LightweightHTMLParser.parse(html: "<b>Bold text", baseFont: baseFont)
        XCTAssertEqual(result.string, "Bold text")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
    }

    func test_stray_less_than() {
        let result = LightweightHTMLParser.parse(html: "A < B", baseFont: baseFont)
        XCTAssertTrue(result.string.contains("A"))
        XCTAssertTrue(result.string.contains("B"))
    }

    func test_empty_tag() {
        let result = LightweightHTMLParser.parse(html: "Before<>After", baseFont: baseFont)
        XCTAssertTrue(result.string.contains("Before"))
        XCTAssertTrue(result.string.contains("After"))
    }

    // MARK: - Integration with htmlToAttributedString extension

    func test_htmlToAttributedString_uses_parser() {
        let result = "Get <b>20% off</b>".htmlToAttributedString(
            textColorHex: "#FF0000",
            uiFont: baseFont,
            linkStyles: nil,
            colorScheme: .light
        )
        XCTAssertEqual(result.string, "Get 20% off")

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertNotNil(color)
    }

    func test_htmlToAttributedString_without_color() {
        let result = "<em>Italic</em> text".htmlToAttributedString(
            textColorHex: nil,
            uiFont: baseFont,
            linkStyles: nil,
            colorScheme: .light
        )
        XCTAssertEqual(result.string, "Italic text")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)
    }
}
