import UIKit
import DcuiSchema

// Presents a bottom sheet flush to its container's left, right and bottom edges.
//
// Used only when the layout sets `bottomSheetPresentation` to `fullBleed`. Everything here is
// behaviour UISheetPresentationController would otherwise provide: from iOS 26 UIKit insets a
// .pageSheet from every screen edge, and that inset is not configurable — it is 4pt on 26.0 and
// 8pt on 26.2 — so honouring the setting means not using UISheetPresentationController at all.
@available(iOS 15, *)
final class RoktBottomSheetPresentationController: UIPresentationController {

    // Fraction of the sheet's own height a drag must cover before release dismisses it.
    private static let dismissTranslationFraction: CGFloat = 0.5
    // Downward velocity (points/second) that dismisses regardless of distance covered.
    private static let dismissVelocity: CGFloat = 1000
    // Matches the dimming UIKit applies behind a .pageSheet closely enough that switching
    // presentation changes the sheet's insets and nothing else.
    private static let backdropAlpha: CGFloat = 0.4

    private let backdrop = RoktBottomSheetPresentationController.makeBackdrop()
    private let cornerRadius: CGFloat
    private let allowBackdropToClose: Bool
    private var panGesture: UIPanGestureRecognizer?
    private var dragStartHeight: CGFloat?

    /// Resolves the sheet's height from the largest height available to it, mirroring the
    /// `maximumDetentValue` a UIKit custom detent resolver is handed.
    private var heightResolver: (CGFloat) -> CGFloat
    /// The resolver the sheet was created with, i.e. its unexpanded height.
    private let collapsedResolver: (CGFloat) -> CGFloat

    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         heightResolver: @escaping (CGFloat) -> CGFloat,
         cornerRadius: CGFloat,
         allowBackdropToClose: Bool) {
        self.heightResolver = heightResolver
        self.collapsedResolver = heightResolver
        self.cornerRadius = cornerRadius
        self.allowBackdropToClose = allowBackdropToClose
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
    }

    // MARK: Geometry

    /// Largest height a sheet may occupy. Leaves the container's top safe area uncovered, which
    /// is where UIKit's .large() detent stops; "full bleed" is about the other three edges.
    static func maximumSheetHeight(containerHeight: CGFloat, topSafeArea: CGFloat) -> CGFloat {
        max(containerHeight - topSafeArea, 0)
    }

    /// Whether a layout gets SDK-owned presentation. Regular width is UIKit's centred,
    /// width-limited card; pinning to the full container width there would stretch the sheet
    /// across an iPad, so the platform presentation stays. Matched positively so an unspecified
    /// size class also falls back to the platform sheet.
    static func shouldPresentFullBleed(presentation: BottomSheetPresentation?,
                                       horizontalSizeClass: UIUserInterfaceSizeClass) -> Bool {
        presentation == .fullBleed && horizontalSizeClass == .compact
    }

    /// The resolver for an expanded state. Both states stay resolvers rather than resolved
    /// points, so a container change re-resolves them instead of stranding the sheet at a height
    /// computed for the previous container.
    static func resolver(expanded: Bool,
                         collapsed: @escaping (CGFloat) -> CGFloat) -> (CGFloat) -> CGFloat {
        expanded ? { $0 } : collapsed
    }

    /// Maps the layout's height styling onto a resolver over the available height, mirroring the
    /// rules the custom-detent path applies. No height, or wrap-content, starts at half the
    /// available height for the same reason the detent path starts at `.medium`: to give the
    /// content room to measure in. On the dynamic path the content then reports its own height
    /// and replaces this. Below iOS 16 that path is unavailable and the sheet stays at half —
    /// which is what the legacy path did there too, pinning every sheet to `.medium()`.
    static func heightResolver(for height: DimensionHeightValue?) -> (CGFloat) -> CGFloat {
        switch height {
        case .fixed(let value):
            return { _ in CGFloat(value) }
        case .percentage(let value):
            return { maximum in maximum * CGFloat(value/100) }
        case .fit(let type):
            return type == .fitHeight ? { maximum in maximum } : { maximum in maximum/2 }
        case .none:
            return { maximum in maximum/2 }
        }
    }

    /// Where the sheet sits: full container width, pinned to the bottom, at the requested height
    /// clamped to what's available. Kept free of UIKit state so the geometry is directly testable.
    static func sheetFrame(containerSize: CGSize,
                           topSafeArea: CGFloat,
                           requestedHeight: CGFloat) -> CGRect {
        let maximum = maximumSheetHeight(containerHeight: containerSize.height,
                                         topSafeArea: topSafeArea)
        let height = min(max(requestedHeight, 1), maximum)
        return CGRect(x: 0,
                      y: containerSize.height - height,
                      width: containerSize.width,
                      height: height)
    }

    var maximumSheetHeight: CGFloat {
        guard let containerView else { return 0 }
        return Self.maximumSheetHeight(containerHeight: containerView.bounds.height,
                                       topSafeArea: containerView.safeAreaInsets.top)
    }

    /// The height the sheet occupies when not expanded. Held separately so the expanded-state
    /// path can return to it after the layout collapses the sheet again.
    var collapsedHeight: CGFloat {
        min(max(collapsedResolver(maximumSheetHeight), 1), maximumSheetHeight)
    }

    /// The height the sheet currently wants, clamped to what the container can give it.
    var resolvedSheetHeight: CGFloat {
        min(max(heightResolver(maximumSheetHeight), 1), maximumSheetHeight)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }
        return Self.sheetFrame(containerSize: containerView.bounds.size,
                               topSafeArea: containerView.safeAreaInsets.top,
                               requestedHeight: heightResolver(maximumSheetHeight))
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        backdrop.frame = containerView?.bounds ?? .zero
        // Skip while a drag is in flight, so relayout doesn't fight the gesture.
        guard dragStartHeight == nil else { return }
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    /// Resizes the sheet in place. Drives both the wrap-content path (content reports its height)
    /// and the expanded-state path (the layout toggles between two heights).
    func setSheetHeight(_ height: CGFloat, animated: Bool, completion: (() -> Void)? = nil) {
        setSheetHeight({ _ in height }, animated: animated, completion: completion)
    }

    /// Switches between the layout's own height and the full available height.
    func setExpanded(_ expanded: Bool, animated: Bool) {
        setSheetHeight(Self.resolver(expanded: expanded, collapsed: collapsedResolver),
                       animated: animated)
    }

    func setSheetHeight(_ resolver: @escaping (CGFloat) -> CGFloat,
                        animated: Bool,
                        completion: (() -> Void)? = nil) {
        heightResolver = resolver
        guard animated else {
            presentedView?.frame = frameOfPresentedViewInContainerView
            completion?()
            return
        }
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState],
                       animations: { self.presentedView?.frame = self.frameOfPresentedViewInContainerView },
                       completion: { _ in completion?() })
    }

    // MARK: Appearance

    /// The backdrop at rest, i.e. fully faded in. Presentation starts it at zero alpha and
    /// animates to this.
    static func makeBackdrop() -> UIView {
        let backdrop = UIView()
        backdrop.backgroundColor = UIColor.black.withAlphaComponent(backdropAlpha)
        // The backdrop is decoration; leaving it in the a11y tree would put an unlabelled
        // element ahead of the sheet's content.
        backdrop.isAccessibilityElement = false
        backdrop.accessibilityElementsHidden = true
        return backdrop
    }

    /// Rounds the sheet's top corners — UISheetPresentationController does this for free.
    static func applySheetAppearance(to view: UIView, cornerRadius: CGFloat) {
        view.layer.cornerRadius = cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
    }

    // MARK: Presentation

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView else { return }

        backdrop.frame = containerView.bounds
        backdrop.alpha = 0
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if allowBackdropToClose {
            backdrop.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                 action: #selector(backdropTapped)))
        }
        containerView.insertSubview(backdrop, at: 0)
        // Hides the *siblings* of the view it is set on. The presenting app's view is a sibling
        // of the container, not of the sheet, so setting it on the sheet would only hide the
        // backdrop and leave VoiceOver able to reach the app behind the dimming.
        containerView.accessibilityViewIsModal = true

        if let presentedView {
            Self.applySheetAppearance(to: presentedView, cornerRadius: cornerRadius)

            if allowBackdropToClose {
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
                pan.delegate = self
                presentedView.addGestureRecognizer(pan)
                panGesture = pan
            }
        }

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.backdrop.alpha = 1
        })
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.backdrop.alpha = 0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            backdrop.removeFromSuperview()
        }
    }

    // MARK: Dismissal

    @objc private func backdropTapped() {
        dismiss()
    }

    private func dismiss() {
        presentedViewController.dismiss(animated: true)
    }

    /// The two-finger Z-scrub. UISheetPresentationController provides it; taking over presentation
    /// means providing it here, or a VoiceOver user has no way out of a dismissible sheet.
    func performAccessibilityEscape() -> Bool {
        guard allowBackdropToClose else { return false }
        dismiss()
        return true
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let presentedView, let containerView else { return }
        let translation = gesture.translation(in: containerView).y

        switch gesture.state {
        case .began:
            dragStartHeight = presentedView.frame.height
        case .changed:
            guard let start = dragStartHeight else { return }
            // Upward drags resist rather than grow the sheet: the sheet has one height, and
            // letting a drag enlarge it would contradict the height the layout asked for.
            let offset = translation > 0 ? translation : translation/4
            presentedView.frame = Self.sheetFrame(containerSize: containerView.bounds.size,
                                                  topSafeArea: containerView.safeAreaInsets.top,
                                                  requestedHeight: start - offset)
        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: containerView).y
            let start = dragStartHeight ?? resolvedSheetHeight
            dragStartHeight = nil
            let passedThreshold = translation > start * Self.dismissTranslationFraction
            if gesture.state == .ended && (passedThreshold || velocity > Self.dismissVelocity) {
                dismiss()
            } else {
                // Snap back to whatever height the layout currently asks for.
                setSheetHeight(heightResolver, animated: true)
            }
        default:
            break
        }
    }
}

@available(iOS 15, *)
extension RoktBottomSheetPresentationController: UIGestureRecognizerDelegate {
    // The dynamic bottom sheet hosts its content in a SwiftUI ScrollView. Without this the sheet
    // pan and the scroll pan compete, and the sheet drags away while the user is trying to
    // scroll. Recognising simultaneously lets `gestureRecognizerShouldBegin` arbitrate instead.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let containerView else { return true }
        // Only drag the sheet downwards, and only when no scroll view underneath still has
        // content to give back.
        guard pan.velocity(in: containerView).y > 0 else { return false }
        guard let scrollView = scrollViewUnderTouch(of: pan) else { return true }
        return scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top
    }

    private func scrollViewUnderTouch(of pan: UIPanGestureRecognizer) -> UIScrollView? {
        guard let presentedView else { return nil }
        let point = pan.location(in: presentedView)
        var view = presentedView.hitTest(point, with: nil)
        while let candidate = view {
            if let scrollView = candidate as? UIScrollView, scrollView.isScrollEnabled {
                return scrollView
            }
            view = candidate.superview
        }
        return nil
    }
}

/// Supplies the presentation controller and the slide-up/slide-down animations that
/// `.pageSheet` would otherwise provide.
@available(iOS 15, *)
final class RoktBottomSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private let heightResolver: (CGFloat) -> CGFloat
    private let cornerRadius: CGFloat
    private let allowBackdropToClose: Bool

    private(set) weak var presentationController: RoktBottomSheetPresentationController?

    init(heightResolver: @escaping (CGFloat) -> CGFloat,
         cornerRadius: CGFloat,
         allowBackdropToClose: Bool) {
        self.heightResolver = heightResolver
        self.cornerRadius = cornerRadius
        self.allowBackdropToClose = allowBackdropToClose
    }

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let controller = RoktBottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            heightResolver: heightResolver,
            cornerRadius: cornerRadius,
            allowBackdropToClose: allowBackdropToClose
        )
        presentationController = controller
        return controller
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        RoktBottomSheetSlideAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        RoktBottomSheetSlideAnimator(isPresenting: false)
    }
}

@available(iOS 15, *)
final class RoktBottomSheetSlideAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(using context: UIViewControllerContextTransitioning?) -> TimeInterval {
        isPresenting ? 0.35 : 0.25
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        if isPresenting {
            guard let toViewController = context.viewController(forKey: .to),
                  let toView = context.view(forKey: .to) else {
                return context.completeTransition(false)
            }
            let finalFrame = context.finalFrame(for: toViewController)
            toView.frame = finalFrame.offsetBy(dx: 0, dy: finalFrame.height)
            context.containerView.addSubview(toView)
            UIView.animate(withDuration: transitionDuration(using: context),
                           delay: 0,
                           options: [.curveEaseOut],
                           animations: { toView.frame = finalFrame },
                           completion: { _ in
                               context.completeTransition(!context.transitionWasCancelled)
                           })
        } else {
            guard let fromView = context.view(forKey: .from) else {
                return context.completeTransition(false)
            }
            UIView.animate(withDuration: transitionDuration(using: context),
                           delay: 0,
                           options: [.curveEaseIn],
                           animations: {
                               fromView.frame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
                           },
                           completion: { _ in
                               context.completeTransition(!context.transitionWasCancelled)
                           })
        }
    }
}
