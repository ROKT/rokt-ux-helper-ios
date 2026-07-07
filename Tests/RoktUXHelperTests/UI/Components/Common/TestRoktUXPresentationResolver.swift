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

    override var presentedViewController: UIViewController? {
        stubPresentedViewController
    }
}
