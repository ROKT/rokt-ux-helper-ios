import UIKit

@available(iOS 15.0, *)
enum RoktUXPresentationResolver {
    static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    /// Walks toward the logical UI front: `presentedViewController` first (when we should traverse
    /// into it), then drills `UINavigationController`, `UITabBarController`, and `UISplitViewController`
    /// so a `.fullScreen` checkout from a nested screen is found.
    ///
    /// A freshly presented `UINavigationController` (typical checkout shell) may not yet have
    /// `view.window != nil` while its root is already loading; we still descend into that container
    /// so resolution can reach the visible child. Plain `UIViewController` presenters that fail
    /// `isPresenterUsable` are not followed (avoids stale / dismissing modals).
    static func frontmostViewController(
        from root: UIViewController?,
        isPresenterUsable: (UIViewController) -> Bool
    ) -> UIViewController? {
        guard let root else { return nil }

        if let presented = root.presentedViewController,
           shouldTraverseIntoPresentedChild(presented, isPresenterUsable: isPresenterUsable) {
            return frontmostViewController(from: presented, isPresenterUsable: isPresenterUsable) ?? presented
        }

        if let navigation = root as? UINavigationController,
           let visible = navigation.visibleViewController,
           visible !== navigation {
            return frontmostViewController(from: visible, isPresenterUsable: isPresenterUsable) ?? visible
        }

        if let tab = root as? UITabBarController,
           let selected = tab.selectedViewController,
           selected !== tab {
            return frontmostViewController(from: selected, isPresenterUsable: isPresenterUsable) ?? selected
        }

        if let split = root as? UISplitViewController {
            for child in split.viewControllers.reversed() {
                if let found = frontmostViewController(from: child, isPresenterUsable: isPresenterUsable) {
                    return found
                }
            }
        }

        return root
    }

    static func stableTopViewController(
        startingAt controller: UIViewController?,
        isPresenterUsable: (UIViewController) -> Bool = defaultIsPresenterUsable
    ) -> UIViewController? {
        guard let controller else {
            RoktUXLogger.shared.warning(
                "Overlay presenter resolution failed: starting view controller was nil "
                    + "(no key-window rootViewController)."
            )
            return nil
        }

        let front = frontmostViewController(from: controller, isPresenterUsable: isPresenterUsable) ?? controller

        // The key window root can be detached under a `.fullScreen` cover; `front` may still be the
        // on-screen nested presenter. Walk usable `presentedViewController` from there.
        var bestUsable: UIViewController? = isPresenterUsable(front) ? front : nil
        var cursor = front
        while let presented = cursor.presentedViewController {
            guard isPresenterUsable(presented) else { break }
            bestUsable = presented
            cursor = presented
        }
        if bestUsable == nil {
            RoktUXLogger.shared.warning(
                "Overlay presenter resolution failed: no usable view controller in the "
                    + "presentation chain (e.g. detached or dismissing). "
                    + "Overlay UI will not be presented."
            )
        }
        return bestUsable
    }

    /// Follow `presentedViewController` when the child is already usable, or when it is a container
    /// we can drill into to find a usable leaf (see ``frontmostViewController``).
    private static func shouldTraverseIntoPresentedChild(
        _ presented: UIViewController,
        isPresenterUsable: (UIViewController) -> Bool
    ) -> Bool {
        if isPresenterUsable(presented) { return true }
        return presented is UINavigationController
            || presented is UITabBarController
            || presented is UISplitViewController
    }

    private static func defaultIsPresenterUsable(_ controller: UIViewController) -> Bool {
        guard !controller.isBeingDismissed, !controller.isMovingFromParent else { return false }
        if controller.viewIfLoaded?.window != nil { return true }
        // Embedded root may briefly lack a direct window while the navigation shell is already attached.
        if let nav = controller.navigationController, nav.viewIfLoaded?.window != nil {
            return controller.isViewLoaded
        }
        return false
    }
}
