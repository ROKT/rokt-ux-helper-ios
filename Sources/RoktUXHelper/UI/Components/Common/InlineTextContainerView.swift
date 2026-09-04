import UIKit

final class InlineTextContainerView: UIView {
    let textView = InlineTextView()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isAccessibilityElement = false
        accessibilityContainerType = .semanticGroup
        // UITextView supplies its own text accessibility children; expose the inline runs on a plain container.
        textView.accessibilityElementsHidden = true
        addSubview(textView)
        textView.accessibilityContainerView = self
    }

    required init?(coder: NSCoder) { return nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.frame = bounds
        textView.layoutIfNeeded()
    }
}
