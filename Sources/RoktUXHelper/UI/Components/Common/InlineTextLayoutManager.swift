import UIKit

/// Draws decorations per wrapped fragment and reserves vertical spacing in TextKit's line metrics.
final class InlineTextLayoutManager: NSLayoutManager, NSLayoutManagerDelegate {
    var decorations: [InlineTextDecoration] = []

    override init() {
        super.init()
        delegate = self
    }

    required init?(coder: NSCoder) { return nil }

    func layoutManager(_ layoutManager: NSLayoutManager,
                       shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>,
                       lineFragmentUsedRect: UnsafeMutablePointer<CGRect>,
                       baselineOffset: UnsafeMutablePointer<CGFloat>,
                       in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        let characters = characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        var top: CGFloat = 0
        var bottom: CGFloat = 0
        textStorage?.enumerateAttribute(.inlineVerticalInsets, in: characters) { value, _, _ in
            guard let insets = (value as? NSValue)?.uiEdgeInsetsValue else { return }
            top = max(top, insets.top)
            bottom = max(bottom, insets.bottom)
        }
        guard top + bottom > 0 else { return false }
        lineFragmentRect.pointee.size.height += top + bottom
        lineFragmentUsedRect.pointee.size.height += top + bottom
        baselineOffset.pointee += top
        return true
    }

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let context = UIGraphicsGetCurrentContext(), let container = textContainers.first else { return }
        for decoration in decorations {
            let glyphs = glyphRange(forCharacterRange: decoration.range, actualCharacterRange: nil)
            let visible = NSIntersectionRange(glyphsToShow, glyphs)
            guard visible.length > 0 else { continue }
            enumerateEnclosingRects(forGlyphRange: glyphs,
                                    withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
                                    in: container) { rect, _ in
                context.saveGState()
                context.setAlpha(decoration.opacity)
                let frame = rect.offsetBy(dx: origin.x, dy: origin.y).inset(by: decoration.verticalMargin)
                self.draw(decoration, in: frame, context: context)
                context.restoreGState()
            }
        }
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    }

    private func draw(_ style: InlineTextDecoration, in rect: CGRect, context: CGContext) {
        guard rect.width > 0, rect.height > 0 else { return }
        let path = UIBezierPath(roundedRect: rect, cornerRadius: style.cornerRadius)
        path.addClip()
        style.backgroundColor?.setFill()
        if style.backgroundColor != nil { path.fill() }
        guard let borderColor = style.borderColor else { return }
        borderColor.setStroke()
        borderColor.setFill()
        let widths = style.borderWidth
        if widths.isMultiDimension(), !style.dashed {
            context.fill(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: max(0, widths.top)))
            context.fill(CGRect(x: rect.minX, y: rect.maxY - widths.bottom, width: rect.width, height: max(0, widths.bottom)))
            context.fill(CGRect(x: rect.minX, y: rect.minY, width: max(0, widths.left), height: rect.height))
            context.fill(CGRect(x: rect.maxX - widths.right, y: rect.minY, width: max(0, widths.right), height: rect.height))
        }
        let width = min(max(0, widths.defaultWidth()), min(rect.width, rect.height))
        let stroke = UIBezierPath(roundedRect: rect.insetBy(dx: width/2, dy: width/2),
                                  cornerRadius: max(0, style.cornerRadius - width/2))
        stroke.lineWidth = width
        if style.dashed { stroke.setLineDash([10], count: 1, phase: 0) }
        if width > 0 { stroke.stroke() }
    }
}
