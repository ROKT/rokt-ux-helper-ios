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

    static func stableTopViewController(
        startingAt controller: UIViewController?,
        isPresenterUsable: (UIViewController) -> Bool = defaultIsPresenterUsable
    ) -> UIViewController? {
        guard let controller else {
            RoktUXLogger.shared.warning(
                "Overlay presenter resolution failed: starting view controller was nil (no key-window rootViewController)."
            )
            return nil
        }

        // The starting controller (key window's `rootViewController`) is routinely detached
        // from the window when a `.fullScreen` modal is presented on top. That must not abort
        // resolution — walk the chain and return the deepest usable controller (staleness checks
        // still apply to each step along the chain).
        var bestUsable: UIViewController? = isPresenterUsable(controller) ? controller : nil
        var cursor = controller
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

    private static func defaultIsPresenterUsable(_ controller: UIViewController) -> Bool {
        controller.viewIfLoaded?.window != nil &&
        !controller.isBeingDismissed &&
        !controller.isMovingFromParent
    }
}
