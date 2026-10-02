import SwiftUI
import DcuiSchema
import CryptoKit

@available(iOS 15, *)
internal extension StringProtocol {
    func htmlToAttributedString(
        textColorHex: String?,
        uiFont: UIFont?,
        textTransform: TextTransform? = nil,
        linkStyles: InlineTextStylingProperties?,
        colorScheme: ColorScheme,
        blockSpacerHeight: CGFloat? = nil
    ) -> NSAttributedString {
        var convertedText = String(self)

        if let textColorHex {
            convertedText = "<font color=\(textColorHex)>" + self + "</font>"
        }

        let parsed = LightweightHTMLParser.parse(
            html: convertedText,
            baseFont: uiFont,
            blockSpacerHeight: blockSpacerHeight
        )

        let transformed = transformAttributedText(
            parsed,
            using: textTransform,
            linkTransform: linkStyles?.textTransform
        )
        return updateLinkStyles(linkStyles, attrStr: transformed, colorScheme: colorScheme)
    }

    /// Transforms each attribute run on its own, so every style stays on the text it
    /// covered even when case conversion changes the length (e.g. "ß" → "SS"). As in
    /// CSS, a link's own `linkTransform` replaces the inherited `transform`.
    private func transformAttributedText(
        _ attrStr: NSAttributedString,
        using transform: TextTransform?,
        linkTransform: TextTransform?
    ) -> NSMutableAttributedString {
        guard transform != nil || linkTransform != nil else {
            return NSMutableAttributedString(attributedString: attrStr)
        }

        let result = NSMutableAttributedString()
        let original = attrStr.string as NSString
        // Carried across runs, links included, so a word split by inline tags or
        // links is capitalized once.
        var inWord = false
        attrStr.enumerateAttributes(in: NSRange(location: 0, length: attrStr.length), options: []) { attributes, range, _ in
            let runTransform = attributes[.link] != nil ? linkTransform ?? transform : transform
            let run = BasicTextViewModel.transform(original.substring(with: range), using: runTransform, inWord: &inWord)
            result.append(NSAttributedString(string: run, attributes: attributes))
        }
        return result
    }

    private func updateLinkStyles(_ linkStyles: InlineTextStylingProperties?,
                                  attrStr: NSMutableAttributedString,
                                  colorScheme: ColorScheme) -> NSAttributedString {
        let attrStrCopy = attrStr

        guard let linkStyles else { return attrStrCopy }

        // Link text was already transformed, so styling never changes its length.
        let attrRange = NSRange(0..<attrStrCopy.length)
        attrStrCopy.enumerateAttribute(.link, in: attrRange) { strValue, range, _ in
            guard strValue != nil else { return }

            setLinkColor(textColorHex: linkStyles.textColor?.getAdaptiveColor(colorScheme),
                         originalStr: attrStrCopy,
                         rangeToChange: range)
            setLinkTextDecoration(decoration: linkStyles.textDecoration, originalStr: attrStrCopy, rangeToChange: range)
            setLinkLetterSpacing(spacing: linkStyles.letterSpacing, originalStr: attrStrCopy, rangeToChange: range)

            setLinkFontProperties(
                fontFamily: linkStyles.fontFamily,
                fontWeight: linkStyles.fontWeight,
                fontSize: linkStyles.fontSize,
                fontStyle: linkStyles.fontStyle,
                fontBaselineAlignment: linkStyles.baselineTextAlign,
                originalStr: attrStrCopy,
                rangeToChange: range
            )
        }

        return attrStrCopy
    }

    private func setLinkColor(textColorHex: String?, originalStr: NSMutableAttributedString, rangeToChange: NSRange) {
        guard let textColorHex else { return }

        originalStr.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: UIColor(hexString: textColorHex),
            range: rangeToChange
        )
    }

    private func setLinkTextDecoration(
        decoration: TextDecoration?,
        originalStr: NSMutableAttributedString,
        rangeToChange: NSRange
    ) {
        guard let decoration else { return }

        // remove default underline
        originalStr.removeAttribute(NSAttributedString.Key.underlineStyle, range: rangeToChange)

        switch decoration {
        case .underline:
            originalStr.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: rangeToChange)
        case .strikeThrough:
            originalStr.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: rangeToChange)
        case .none:
            originalStr.addAttribute(NSAttributedString.Key.underlineStyle, value: 0, range: rangeToChange)
            originalStr.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: rangeToChange)
        }
    }

    private func setLinkLetterSpacing(spacing: Float?, originalStr: NSMutableAttributedString, rangeToChange: NSRange) {
        guard let spacing else { return }

        originalStr.addAttribute(NSAttributedString.Key.kern, value: CGFloat(spacing), range: rangeToChange)
    }

    private func setLinkFontProperties(
        fontFamily: String?,
        fontWeight: FontWeight?,
        fontSize: Float?,
        fontStyle: FontStyle?,
        fontBaselineAlignment: FontBaselineAlignment?,
        originalStr: NSMutableAttributedString,
        rangeToChange: NSRange
    ) {
        originalStr.enumerateAttribute(.font, in: rangeToChange) { fontAtRange, fontRange, _ in
            guard let fRange = fontAtRange as? UIFont else { return }

            var updatedFont = fRange

            if let fontFamily, let customFont = UIFont(name: fontFamily, size: fRange.pointSize) {
                updatedFont = customFont
            }

            guard let fDesc = updatedFont.fontDescriptor.withSymbolicTraits([]) else { return }

            if let fontSize {
                updatedFont = UIFont(descriptor: fDesc, size: fontSize.getAsScaledFontSize())
            }

            if let fontWeight {
                updatedFont = updatedFont.withWeight(fontWeight.asUIFontWeight)
            }

            if let fontStyle {
                var traits: UIFontDescriptor.SymbolicTraits = []

                switch fontStyle {
                case .italic:
                    traits = traits.union(.traitItalic)
                case .normal:
                    traits = traits.union(.traitBold)
                }

                // have to check this again in case new descriptors like fontWeight were added
                guard let fontWithTraitsDescriptor = updatedFont.fontDescriptor.withSymbolicTraits(traits)
                else { return }

                updatedFont = UIFont(descriptor: fontWithTraitsDescriptor, size: updatedFont.pointSize)
            }

            // has to be applied last
            if let fontBaselineAlignment {
                var baselineOffset = CGFloat(0)
                switch fontBaselineAlignment {
                case .sub:
                    baselineOffset = updatedFont.ascender * -0.5
                case .super:
                    baselineOffset = updatedFont.ascender * 0.5
                default:
                    break
                }

                originalStr.addAttribute(.baselineOffset, value: baselineOffset, range: fontRange)
            }

            originalStr.addAttribute(.font, value: updatedFont, range: fontRange)
        }
    }
}
