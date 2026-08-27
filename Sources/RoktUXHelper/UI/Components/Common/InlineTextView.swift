import UIKit

struct InlineTextAction {
    let traits: UIAccessibilityTraits
    let activate: () -> Void
}

struct InlineTextRun {
    let id: UUID
    let range: NSRange
    let label: String
    let action: InlineTextAction?
}

struct InlineTextContent {
    let text: NSAttributedString
    let runs: [InlineTextRun]
    var decorations: [InlineTextDecoration] = []
    var transitionStates: [Bool] = []
    var transitionDuration: TimeInterval = 0
}

/// One TextKit layout keeps every span, including action labels, in the same text flow.
final class InlineTextView: UITextView, UIGestureRecognizerDelegate {
    private(set) var runs: [InlineTextRun] = []
    var onInteractionStateChange: ((UUID, StyleState) -> Void)?
    var actionsEnabled = true {
        didSet {
            guard oldValue != actionsEnabled else { return }
            if !actionsEnabled {
                setPressedRun(nil)
                if let hoveredRunID { onInteractionStateChange?(hoveredRunID, .disabled) }
                hoveredRunID = nil
            }
            updateAccessibility()
        }
    }
    private var elements: [UUID: InlineAccessibilityElement] = [:]
    private var pressedRunID: UUID?
    private var hoveredRunID: UUID?
    private var previousTransitionStates: [Bool]?
    private var previousWidth: CGFloat = 0
    private let minimumTargetSize: CGFloat = 44

    override init(frame: CGRect = .zero, textContainer: NSTextContainer? = nil) {
        let container = NSTextContainer(size: .zero)
        let manager = InlineTextLayoutManager()
        let storage = NSTextStorage()
        storage.addLayoutManager(manager)
        manager.addTextContainer(container)
        super.init(frame: frame, textContainer: container)
        isEditable = false
        isSelectable = false
        isScrollEnabled = false
        backgroundColor = .clear
        textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        self.textContainer.lineBreakMode = .byWordWrapping
        isAccessibilityElement = false
        accessibilityContainerType = .semanticGroup
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        addGestureRecognizer(tap)
        addGestureRecognizer(UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:))))
    }

    required init?(coder: NSCoder) { return nil }

    func setContent(_ content: InlineTextContent, accessibilityLabel: String?) {
        runs = content.runs
        let textChanged = attributedText?.isEqual(to: content.text) != true
        let manager = layoutManager as? InlineTextLayoutManager
        let decorationsChanged = manager?.decorations != content.decorations
        let changedTransition = previousTransitionStates.map { $0 != content.transitionStates } ?? false
        previousTransitionStates = content.transitionStates
        let update = {
            if textChanged { self.attributedText = content.text }
            if decorationsChanged {
                manager?.decorations = content.decorations
                self.setNeedsDisplay()
            }
        }
        if changedTransition, textChanged || decorationsChanged, content.transitionDuration > 0,
           !UIAccessibility.isReduceMotionEnabled {
            UIView.transition(with: self, duration: content.transitionDuration,
                              options: [.transitionCrossDissolve, .beginFromCurrentState, .allowAnimatedContent],
                              animations: update)
        } else {
            update()
        }
        self.accessibilityLabel = accessibilityLabel
        let previousInsets = textContainerInset
        updateActionInsets()
        if textChanged || previousInsets != textContainerInset { invalidateIntrinsicContentSize() }
        updateAccessibility()
    }

    func measuredHeight(for width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0, let attributedText, attributedText.length > 0 else { return 0 }
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        if textContainer.size != size { textContainer.size = size }
        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = max(layoutManager.usedRect(for: textContainer).maxY,
                             layoutManager.extraLineFragmentRect.maxY)
        return ceil(usedHeight + textContainerInset.top + textContainerInset.bottom)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: measuredHeight(for: bounds.width))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if previousWidth != bounds.width {
            previousWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
        updateAccessibility()
    }

    /// Rectangles are per line fragment; a wrapped action never claims the whole paragraph.
    func rects(for range: NSRange) -> [CGRect] {
        guard range.length > 0, NSMaxRange(range) <= textStorage.length else { return [] }
        layoutManager.ensureLayout(for: textContainer)
        let glyphs = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rects: [CGRect] = []
        layoutManager.enumerateEnclosingRects(forGlyphRange: glyphs,
                                              withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
                                              in: textContainer) { rect, _ in
            rects.append(rect.offsetBy(dx: self.textContainerInset.left, dy: self.textContainerInset.top))
        }
        return rects
    }

    func actionRun(at point: CGPoint) -> InlineTextRun? {
        guard actionsEnabled, bounds.contains(point) else { return nil }
        let actions = runs.filter { $0.action != nil }
        // Exact copy hits are inert; enlarged targets must not steal adjacent text or another action.
        if let exact = runs.first(where: { run in rects(for: run.range).contains { $0.contains(point) } }) {
            return exact.action == nil ? nil : exact
        }
        return actions.compactMap { run -> (InlineTextRun, CGFloat)? in
            let distances = rects(for: run.range).compactMap { rect -> CGFloat? in
                guard targetRect(for: rect).contains(point) else { return nil }
                let dx = max(max(rect.minX - point.x, 0), point.x - rect.maxX)
                let dy = max(max(rect.minY - point.y, 0), point.y - rect.maxY)
                return dx * dx + dy * dy
            }
            return distances.min().map { (run, $0) }
        }.min(by: { $0.1 < $1.1 })?.0
    }

    @discardableResult
    func activateRun(id: UUID) -> Bool {
        guard actionsEnabled, let action = runs.first(where: { $0.id == id })?.action else { return false }
        action.activate()
        return true
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        actionRun(at: gestureRecognizer.location(in: self)) != nil
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended, let run = actionRun(at: recognizer.location(in: self)) else { return }
        activateRun(id: run.id)
    }

    @objc private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
        let next = recognizer.state == .began || recognizer.state == .changed
            ? actionRun(at: recognizer.location(in: self))?.id : nil
        guard next != hoveredRunID else { return }
        if let previous = hoveredRunID, previous != pressedRunID {
            onInteractionStateChange?(previous, actionsEnabled ? .default : .disabled)
        }
        hoveredRunID = next
        if let next, next != pressedRunID { onInteractionStateChange?(next, .hovered) }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setPressedRun(touches.first.flatMap { actionRun(at: $0.location(in: self))?.id })
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setPressedRun(nil)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setPressedRun(nil)
    }

    private func setPressedRun(_ id: UUID?) {
        guard id != pressedRunID else { return }
        if let previous = pressedRunID {
            let nextState: StyleState = previous == hoveredRunID ? .hovered : .default
            onInteractionStateChange?(previous, actionsEnabled ? nextState : .disabled)
        }
        pressedRunID = id
        if let id { onInteractionStateChange?(id, .pressed) }
    }

    private func targetRect(for rect: CGRect) -> CGRect {
        var target = rect.insetBy(dx: -max(0, (minimumTargetSize - rect.width)/2),
                                  dy: -max(0, (minimumTargetSize - rect.height)/2))
        target.origin.x = max(0, min(target.minX, bounds.width - target.width))
        target.origin.y = max(0, min(target.minY, bounds.height - target.height))
        return target.intersection(bounds)
    }

    private func updateActionInsets() {
        var padding: CGFloat = 0
        for run in runs where run.action != nil {
            attributedText?.enumerateAttributes(in: run.range) { attributes, _, _ in
                guard let font = attributes[.font] as? UIFont else { return }
                let insets = (attributes[.inlineVerticalInsets] as? NSValue)?.uiEdgeInsetsValue ?? .zero
                let height = font.lineHeight + insets.top + insets.bottom
                padding = max(padding, (self.minimumTargetSize - height)/2)
            }
        }
        // Reserve room for a 44-point target on the first and last lines without moving the label below the copy.
        let insets = UIEdgeInsets(top: ceil(padding), left: 0, bottom: ceil(padding), right: 0)
        if textContainerInset != insets { textContainerInset = insets }
    }

    private func updateAccessibility() {
        var current: [UUID: InlineAccessibilityElement] = [:]
        accessibilityElements = runs.map { run in
            let element = elements[run.id] ?? InlineAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = run.label
            element.accessibilityTraits = run.action?.traits ?? .staticText
            if run.action != nil, !actionsEnabled { element.accessibilityTraits.insert(.notEnabled) }
            element.activation = run.action.map { _ in { [weak self] in self?.activateRun(id: run.id) ?? false } }
            let frame = rects(for: run.range).reduce(CGRect.null) { $0.union($1) }
            element.accessibilityFrameInContainerSpace = frame.isNull ? .zero : frame
            current[run.id] = element
            return element
        }
        elements = current
    }
}

private final class InlineAccessibilityElement: UIAccessibilityElement {
    var activation: (() -> Bool)?
    override func accessibilityActivate() -> Bool { activation?() ?? false }
}
