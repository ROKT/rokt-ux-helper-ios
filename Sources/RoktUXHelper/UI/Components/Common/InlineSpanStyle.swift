import DcuiSchema
import SwiftUI

/// Native range decorations. Other container effects belong in the schema adapter's supported-style checks.
struct InlineSpanStyle: Decodable {
    var spacing: SpacingStylingProperties?
    var backgroundColor: ThemeColor?
    var border: BorderStylingProperties?
    var opacity: Float?

    init(spacing: SpacingStylingProperties? = nil, backgroundColor: ThemeColor? = nil,
         border: BorderStylingProperties? = nil, opacity: Float? = nil) {
        self.spacing = spacing
        self.backgroundColor = backgroundColor
        self.border = border
        self.opacity = opacity
    }
}

struct InlineTextDecoration: Equatable {
    var range: NSRange
    let backgroundColor: UIColor?
    let borderColor: UIColor?
    let borderWidth: FrameAlignmentProperty
    let cornerRadius: CGFloat
    let verticalMargin: UIEdgeInsets
    let dashed: Bool
    var opacity: CGFloat
}

extension NSAttributedString.Key {
    static let inlineVerticalInsets = NSAttributedString.Key("RoktInlineVerticalInsets")
}

final class InlineSpanBuilder {
    let text = NSMutableAttributedString(string: "")
    var decorations: [InlineTextDecoration] = []

    func append(style: InlineSpanStyle, colorScheme: ColorScheme,
                content: () -> Void) -> NSRange {
        let padding = FrameAlignmentProperty.getFrameAlignment(style.spacing?.padding)
        let margin = FrameAlignmentProperty.getFrameAlignment(style.spacing?.margin)
        appendSpace(margin.left, to: text, joinsText: false)
        let start = text.length
        let decorationStart = decorations.count
        appendSpace(padding.left, to: text, joinsText: true)
        content()
        appendSpace(padding.right, to: text, joinsText: true)
        let range = NSRange(location: start, length: text.length - start)
        appendSpace(margin.right, to: text, joinsText: false)
        guard range.length > 0 else { return range }

        let opacity = CGFloat(style.opacity ?? 1)
        let alpha = opacity.isFinite ? max(0, min(1, opacity)) : 1
        text.enumerateAttribute(.foregroundColor, in: range) { value, span, _ in
            if let color = value as? UIColor {
                text.addAttribute(.foregroundColor, value: color.withAlphaComponent(color.cgColor.alpha * alpha), range: span)
            }
        }
        text.enumerateAttribute(.inlineVerticalInsets, in: range) { value, span, _ in
            let previous = (value as? NSValue)?.uiEdgeInsetsValue ?? .zero
            let insets = UIEdgeInsets(top: previous.top + safeSpace(padding.top) + safeSpace(margin.top), left: 0,
                                      bottom: previous.bottom + safeSpace(padding.bottom) + safeSpace(margin.bottom), right: 0)
            text.addAttribute(.inlineVerticalInsets, value: NSValue(uiEdgeInsets: insets), range: span)
        }
        for index in decorationStart..<decorations.count { decorations[index].opacity *= alpha }
        let widths = FrameAlignmentProperty.getFrameAlignment(style.border?.borderWidth)
        let decoration = InlineTextDecoration(
            range: range,
            backgroundColor: style.backgroundColor.map { UIColor(hexString: $0.getAdaptiveColor(colorScheme)) },
            borderColor: style.border?.borderColor.map { UIColor(hexString: $0.getAdaptiveColor(colorScheme)) },
            borderWidth: FrameAlignmentProperty(top: safeSpace(widths.top), right: safeSpace(widths.right),
                                                bottom: safeSpace(widths.bottom), left: safeSpace(widths.left)),
            cornerRadius: safeSpace(CGFloat(style.border?.borderRadius ?? 0)),
            verticalMargin: UIEdgeInsets(top: safeSpace(margin.top), left: 0,
                                         bottom: safeSpace(margin.bottom), right: 0),
            dashed: style.border?.borderStyle == .dashed,
            opacity: alpha
        )
        decorations.insert(decoration, at: decorationStart)
        return range
    }

    private func safeSpace(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }

    private func appendSpace(_ width: CGFloat, to text: NSMutableAttributedString, joinsText: Bool) {
        guard safeSpace(width) > 0 else { return }
        let attachment = InlineSpacingAttachment()
        attachment.image = UIImage()
        attachment.bounds = CGRect(x: 0, y: 0, width: safeSpace(width), height: 0)
        if joinsText { text.append(NSAttributedString(string: "\u{2060}")) }
        text.append(NSAttributedString(attachment: attachment))
        if joinsText { text.append(NSAttributedString(string: "\u{2060}")) }
    }
}

private final class InlineSpacingAttachment: NSTextAttachment {
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? InlineSpacingAttachment else { return false }
        return bounds == other.bounds
    }

    override var hash: Int { bounds.width.hashValue }
}
