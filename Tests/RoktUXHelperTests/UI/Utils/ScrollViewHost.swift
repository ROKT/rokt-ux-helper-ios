import XCTest
import SwiftUI
import UIKit
@testable import RoktUXHelper

/// Hosts a layout in a real `UIWindow` so tests can assert against the native
/// `UIScrollView` geometry that SwiftUI produces -- the viewport bounds and the
/// content size, which is what decides whether a scrollable container can scroll.
@available(iOS 15.0, *)
final class ScrollViewHost {
    let hostingController: UIHostingController<AnyView>
    private let window: UIWindow

    init(layout: LayoutSchemaViewModel, size: CGSize, layoutState: LayoutState = LayoutState()) {
        let content = TestPlaceHolder(layout: layout, layoutState: layoutState)
            .frame(width: size.width, height: size.height)
        hostingController = UIHostingController(rootView: AnyView(content))
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
    }

    deinit {
        window.isHidden = true
    }

    /// Drives the run loop until the scroll view's geometry stops changing, then returns
    /// it so callers assert against the real value rather than one they waited for.
    func settledScrollView(
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> UIScrollView {
        let deadline = Date().addingTimeInterval(timeout)
        var previous: CGRect?

        while Date() < deadline {
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()

            if let scrollView = Self.firstScrollView(in: hostingController.view),
               scrollView.bounds.height > 0,
               scrollView.bounds.width > 0 {
                let geometry = CGRect(origin: .zero, size: scrollView.contentSize)
                    .union(scrollView.bounds)
                if geometry == previous {
                    return scrollView
                }
                previous = geometry
            }

            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }

        XCTFail("Timed out waiting for the scroll view geometry to settle", file: file, line: line)
        throw ScrollViewHostError.didNotSettle
    }

    func layoutIfNeeded() {
        hostingController.view.layoutIfNeeded()
    }

    private static func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }

        for subview in view.subviews {
            if let scrollView = firstScrollView(in: subview) {
                return scrollView
            }
        }

        return nil
    }
}

enum ScrollViewHostError: Error {
    case didNotSettle
}
