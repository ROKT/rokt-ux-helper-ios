import SwiftUI
import UIKit

@available(iOS 15, *)
struct CatalogCarouselScrollHost<Content: View>: UIViewControllerRepresentable {
    let model: CatalogCarouselCollectionViewModel
    let geometry: CatalogCarouselGeometry
    let isEnabled: Bool
    let content: Content

    func makeUIViewController(context: Context) -> CatalogCarouselViewController {
        CatalogCarouselViewController(model: model)
    }

    func updateUIViewController(_ controller: CatalogCarouselViewController, context: Context) {
        var environment = context.environment
        environment.isEnabled = environment.isEnabled && isEnabled
        controller.update(content: AnyView(content.environment(\.self, environment)),
                          geometry: geometry,
                          isRightToLeft: context.environment.layoutDirection == .rightToLeft,
                          isEnabled: environment.isEnabled)
    }

    static func dismantleUIViewController(_ controller: CatalogCarouselViewController, coordinator: Void) {
        controller.tearDown()
    }
}

@available(iOS 15, *)
final class CatalogCarouselViewController: UIViewController, UIScrollViewDelegate {
    let scrollView = CatalogCarouselScrollView()
    private(set) var hostingController: ResizableHostingController<AnyView>?
    private let model: CatalogCarouselCollectionViewModel
    private var widthConstraint: NSLayoutConstraint?
    private var geometry: CatalogCarouselGeometry?
    private var isRightToLeft = false
    private var needsAlignment = false
    private var isAligning = false
    private var isTornDown = false

    init(model: CatalogCarouselCollectionViewModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.isDirectionalLockEnabled = true
        scrollView.alwaysBounceVertical = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.decelerationRate = .fast
        scrollView.semanticContentAttribute = .forceLeftToRight
        scrollView.accessibilityScrollHandler = { [weak self] in self?.performAccessibilityScroll($0) ?? false }
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let host = ResizableHostingController(rootView: AnyView(EmptyView()))
        hostingController = host
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(host.view)
        let width = host.view.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint = width
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            host.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            width
        ])
        host.didMove(toParent: self)
    }

    func update(content: AnyView, geometry: CatalogCarouselGeometry, isRightToLeft: Bool, isEnabled: Bool) {
        guard !isTornDown else { return }
        loadViewIfNeeded()
        if self.geometry != geometry || self.isRightToLeft != isRightToLeft {
            self.geometry = geometry
            self.isRightToLeft = isRightToLeft
            model.layoutChanged(geometry: geometry)
            needsAlignment = true
        }
        hostingController?.rootView = content
        widthConstraint?.constant = max(geometry.viewportWidth, geometry.contentWidth)
        scrollView.isUserInteractionEnabled = isEnabled
        scrollView.isScrollEnabled = isEnabled && geometry.maximumOffset > 0
        if !isEnabled { model.endInteraction() }
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard needsAlignment, let geometry, !isTornDown else { return }
        needsAlignment = false
        isAligning = true
        let offset = geometry.snappedOffset(proposedOffset: geometry.offset(for: model.currentItemIndex))
        scrollView.setContentOffset(CGPoint(x: physicalOffset(offset, geometry: geometry), y: 0), animated: false)
        isAligning = false
        DispatchQueue.main.async { [weak self] in
            guard let self, !isTornDown, self.geometry == geometry else { return }
            model.scrolled(offset: logicalOffset(geometry: geometry), geometry: geometry)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isTornDown { model.mounted() }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let geometry, !isTornDown else { return }
        model.beginInteraction(offset: logicalOffset(geometry: geometry), geometry: geometry)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let geometry, !needsAlignment, !isAligning, !isTornDown else { return }
        model.scrolled(offset: logicalOffset(geometry: geometry), geometry: geometry)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let geometry else { return }
        let proposed = isRightToLeft ? geometry.maximumOffset - targetContentOffset.pointee.x : targetContentOffset.pointee.x
        let target = geometry.snappedOffset(proposedOffset: proposed)
        targetContentOffset.pointee = CGPoint(x: physicalOffset(target, geometry: geometry), y: 0)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { model.endInteraction() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        model.endInteraction()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        model.endInteraction()
    }

    func tearDown() {
        isTornDown = true
        model.endInteraction()
        scrollView.delegate = nil
        scrollView.accessibilityScrollHandler = nil
        widthConstraint?.isActive = false
        widthConstraint = nil
        hostingController?.rootView = AnyView(EmptyView())
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }

    private func logicalOffset(geometry: CatalogCarouselGeometry) -> CGFloat {
        isRightToLeft ? geometry.maximumOffset - scrollView.contentOffset.x : scrollView.contentOffset.x
    }

    private func physicalOffset(_ logicalOffset: CGFloat, geometry: CatalogCarouselGeometry) -> CGFloat {
        isRightToLeft ? geometry.maximumOffset - logicalOffset : logicalOffset
    }

    private func performAccessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        guard let geometry, scrollView.isScrollEnabled else { return false }
        let forward: Bool
        switch direction {
        case .left: forward = !isRightToLeft
        case .right: forward = isRightToLeft
        case .next: forward = true
        case .previous: forward = false
        default: return false
        }
        let target = geometry.adjacentOffset(from: logicalOffset(geometry: geometry), forward: forward)
        guard abs(target - logicalOffset(geometry: geometry)) > 0.5 else { return false }
        model.beginInteraction(offset: logicalOffset(geometry: geometry), geometry: geometry)
        let animated = !UIAccessibility.isReduceMotionEnabled
        scrollView.setContentOffset(CGPoint(x: physicalOffset(target, geometry: geometry), y: 0), animated: animated)
        if !animated { model.endInteraction() }
        let announcement = String(format: kPageAnnouncement, geometry.leadingIndex(at: target) + 1, model.cards.count)
        UIAccessibility.post(notification: .pageScrolled, argument: announcement)
        return true
    }
}

@available(iOS 15, *)
final class CatalogCarouselScrollView: UIScrollView {
    var accessibilityScrollHandler: ((UIAccessibilityScrollDirection) -> Bool)?

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
            let velocity = panGestureRecognizer.velocity(in: self)
            guard CatalogCarouselGeometry.isHorizontalDrag(velocity: velocity) else { return false }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        accessibilityScrollHandler?(direction) == true || super.accessibilityScroll(direction)
    }
}
