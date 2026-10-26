import XCTest
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestRoktUXPresentationResolver: XCTestCase {
    func testStableTopViewControllerSkipsUnusablePresentedController() {
        let root = StubPresentedViewController()
        let stalePresented = StubPresentedViewController()
        root.stubPresentedViewController = stalePresented

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { $0 === root }
        )

        XCTAssertTrue(presenter === root)
    }

    func testStableTopViewControllerReturnsDeepestUsablePresentedController() {
        let root = StubPresentedViewController()
        let firstPresented = StubPresentedViewController()
        let secondPresented = StubPresentedViewController()
        root.stubPresentedViewController = firstPresented
        firstPresented.stubPresentedViewController = secondPresented

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { _ in true }
        )

        XCTAssertTrue(presenter === secondPresented)
    }

    func testStableTopViewControllerReturnsNilWhenRootIsUnusable() {
        let root = StubPresentedViewController()

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { _ in false }
        )

        XCTAssertNil(presenter)
    }

    /// When the key window's root is detached (e.g. covered by a `.fullScreen` modal), overlay
    /// presentation must still resolve the on-screen presented controller.
    func testStableTopViewControllerWalksModalChainWhenStartingControllerUnusable() {
        let root = StubPresentedViewController()
        let fullScreenModal = StubPresentedViewController()
        let modalContent = StubPresentedViewController()
        root.stubPresentedViewController = fullScreenModal
        fullScreenModal.stubPresentedViewController = modalContent

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { $0 !== root }
        )

        XCTAssertTrue(presenter === modalContent)
    }

    func testStableTopViewControllerReturnsNilWhenRootUnusableAndFirstPresentedUnusable() {
        let root = StubPresentedViewController()
        let stalePresented = StubPresentedViewController()
        root.stubPresentedViewController = stalePresented

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { $0 !== root && $0 !== stalePresented }
        )

        XCTAssertNil(presenter)
    }

    /// Modal presented from a nested nav screen (not from key-window root): must still resolve.
    func testStableTopResolvesModalPresentedFromNestedNavigation() {
        let tab = StubTabBarController()
        let nav = StubNavigationController()
        let leaf = StubPresentedViewController()
        let checkoutModal = StubPresentedViewController()
        tab.stubSelectedViewController = nav
        nav.stubVisibleViewController = leaf
        leaf.stubPresentedViewController = checkoutModal

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: tab,
            isPresenterUsable: { _ in true }
        )

        XCTAssertTrue(presenter === checkoutModal)
    }

    /// Checkout is often a `UINavigationController` whose view is not in a window for a frame while
    /// the visible child (e.g. SDK host VC) is already loading — we must still resolve the child.
    func testStableTopTraversesPresentedNavigationShellBeforeWindowAttached() {
        let landing = StubPresentedViewController()
        let checkoutNav = StubNavigationController()
        let sample = StubPresentedViewController()
        landing.stubPresentedViewController = checkoutNav
        checkoutNav.stubVisibleViewController = sample

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: landing,
            isPresenterUsable: { $0 === sample }
        )

        XCTAssertTrue(presenter === sample)
    }

    /// Two stacked `.fullScreen` modals detach both the root and the first modal; the second modal is
    /// the only controller on screen and must be resolved.
    func testStableTopWalksPastDetachedControllerInsideModalStack() {
        let root = StubPresentedViewController()
        let coveredModal = StubPresentedViewController()
        let topModal = StubPresentedViewController()
        root.stubPresentedViewController = coveredModal
        coveredModal.stubPresentedViewController = topModal

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { $0 === topModal }
        )

        XCTAssertTrue(presenter === topModal)
    }

    /// A sheet covered by a `.fullScreen` modal is detached while the root stays on screen; resolving the
    /// root would fail because it is already presenting.
    func testStableTopWalksPastCoveredSheetToTopModal() {
        let root = StubPresentedViewController()
        let coveredSheet = StubPresentedViewController()
        let topModal = StubPresentedViewController()
        root.stubPresentedViewController = coveredSheet
        coveredSheet.stubPresentedViewController = topModal

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { $0 !== coveredSheet }
        )

        XCTAssertTrue(presenter === topModal)
    }

    func testStableTopStopsAtDismissingControllerInModalStack() {
        let root = StubPresentedViewController()
        let dismissing = StubPresentedViewController()
        let leaving = StubPresentedViewController()
        root.stubPresentedViewController = dismissing
        dismissing.stubPresentedViewController = leaving
        dismissing.stubIsBeingDismissed = true

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { !$0.isBeingDismissed }
        )

        XCTAssertTrue(presenter === root)
    }

    func testStableTopWalksPastSeveralDetachedControllers() {
        let chain = (0..<6).map { _ in StubPresentedViewController() }
        for (presenter, presented) in zip(chain, chain.dropFirst()) {
            presenter.stubPresentedViewController = presented
        }

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: chain.first,
            isPresenterUsable: { $0 === chain.last }
        )

        XCTAssertTrue(presenter === chain.last)
    }

    func testStableTopReturnsNilWhileDetachedModalStackIsDismissing() {
        let root = StubPresentedViewController()
        let covered = StubPresentedViewController()
        let dismissing = StubPresentedViewController()
        let leaving = StubPresentedViewController()
        root.stubPresentedViewController = covered
        covered.stubPresentedViewController = dismissing
        dismissing.stubPresentedViewController = leaving
        dismissing.stubIsBeingDismissed = true

        let presenter = RoktUXPresentationResolver.stableTopViewController(
            startingAt: root,
            isPresenterUsable: { $0 === leaving }
        )

        XCTAssertNil(presenter)
    }

    func testStableTopDoesNotLoadDetachedViewsToFindPresenter() {
        let root = StubPresentedViewController()
        let covered = StubPresentedViewController()
        let top = StubPresentedViewController()
        root.stubPresentedViewController = covered
        covered.stubPresentedViewController = top

        XCTAssertNil(RoktUXPresentationResolver.stableTopViewController(startingAt: root, logFailures: false))
        XCTAssertFalse(root.isViewLoaded)
        XCTAssertFalse(covered.isViewLoaded)
        XCTAssertFalse(top.isViewLoaded)
    }

    func testStableTopReturnsNilWithoutStartingController() {
        XCTAssertNil(RoktUXPresentationResolver.stableTopViewController(startingAt: nil, logFailures: false))
    }

    func testStableTopResolvesNewModalAfterPreviousStackIsRemoved() {
        let root = StubPresentedViewController()
        let covered = StubPresentedViewController()
        let oldTop = StubPresentedViewController()
        root.stubPresentedViewController = covered
        covered.stubPresentedViewController = oldTop
        let usable: (UIViewController) -> Bool = { $0 !== root && $0 !== covered }
        XCTAssertTrue(RoktUXPresentationResolver.stableTopViewController(startingAt: root, isPresenterUsable: usable) === oldTop)

        let newTop = StubPresentedViewController()
        root.stubPresentedViewController = newTop

        XCTAssertTrue(RoktUXPresentationResolver.stableTopViewController(startingAt: root, isPresenterUsable: usable) === newTop)
    }
}

private final class StubTabBarController: UITabBarController {
    var stubSelectedViewController: UIViewController?

    override var selectedViewController: UIViewController? {
        get { stubSelectedViewController ?? super.selectedViewController }
        set { super.selectedViewController = newValue }
    }
}

private final class StubNavigationController: UINavigationController {
    var stubVisibleViewController: UIViewController?

    override var visibleViewController: UIViewController? {
        stubVisibleViewController ?? super.visibleViewController
    }
}

private final class StubPresentedViewController: UIViewController {
    var stubPresentedViewController: UIViewController?
    var stubIsBeingDismissed = false

    override var presentedViewController: UIViewController? {
        stubPresentedViewController
    }

    override var isBeingDismissed: Bool {
        stubIsBeingDismissed
    }
}
