import DcuiSchema
import SwiftUI

/// Shares BasicText's font and color helpers; inline typography excludes line-level controls.
enum InlineTextAttributes {
    static func make(_ value: String, style: BasicTextStyle?, colorScheme: ColorScheme,
                     contentSize: UIContentSizeCategory) -> NSAttributedString {
        let textStyle = style?.text
        let traits = UITraitCollection(preferredContentSizeCategory: contentSize)
        var font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
        var baseline: CGFloat = 0
        if let textStyle, let styledFont = textStyle.styledUIFont {
            let size = (textStyle.fontSize ?? 17).getAsScaledFontSize(contentSize: contentSize)
            font = styledFont.withSize(size)
            baseline = textStyle.baselineOffset * size/styledFont.pointSize
        }
        let appearance = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let color = textStyle?.textColor.map { UIColor(hexString: $0.getAdaptiveColor(colorScheme)) }
            ?? UIColor.label.resolvedColor(with: appearance)
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .baselineOffset: baseline,
            .kern: CGFloat(textStyle?.letterSpacing ?? 0)
        ]
        if textStyle?.textDecoration == .underline { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
        if textStyle?.textDecoration == .strikeThrough { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
        return NSAttributedString(string: value, attributes: attributes)
    }
}
