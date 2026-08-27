import DcuiSchema
import SwiftUI

/// Uses the same typography and adaptive colors as BasicTextComponent.
enum InlineTextAttributes {
    static func make(_ value: String, style: BasicTextStyle?, colorScheme: ColorScheme,
                     contentSize: UIContentSizeCategory) -> NSAttributedString {
        let textStyle = style?.text
        let traits = UITraitCollection(preferredContentSizeCategory: contentSize)
        var font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
        var baseline: CGFloat = 0
        traits.performAsCurrent {
            font = textStyle?.styledUIFont ?? font
            baseline = textStyle?.baselineOffset ?? 0
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
