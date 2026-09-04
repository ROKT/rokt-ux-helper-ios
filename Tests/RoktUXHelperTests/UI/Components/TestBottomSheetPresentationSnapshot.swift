import XCTest
import SwiftUI
import SnapshotTesting
@testable import RoktUXHelper

/// Snapshots the bottom sheet's *container*, not its content.
///
/// Component snapshots cannot see this: the SwiftUI tree is byte-identical whichever way the
/// sheet is presented, and what changes is the geometry and chrome around it — whether the sheet
/// is flush with the screen edges, how tall it is, its corner radius and its backdrop. From
/// iOS 26 UIKit insets a `.pageSheet` from every edge, so that gutter is exactly what these
/// images are here to catch.
///
/// The container is composed here rather than presented, because UIKit modal presentation is not
/// reliable in a test bundle with no host app. The backdrop, the sheet's appearance and the frame
/// all come from `RoktBottomSheetPresentationController`; only the two `addSubview` calls and
/// their order are local.
@available(iOS 15.0, *)
final class TestBottomSheetPresentationSnapshot: XCTestCase {

    /// Stands in for the presentation controller's container view.
    private final class ContainerHost: UIViewController {
        let sheetView: UIView
        let cornerRadius: CGFloat
        let heightResolver: (CGFloat) -> CGFloat
        private let backdrop = RoktBottomSheetPresentationController.makeBackdrop()

        init(sheetView: UIView, cornerRadius: CGFloat, heightResolver: @escaping (CGFloat) -> CGFloat) {
            self.sheetView = sheetView
            self.cornerRadius = cornerRadius
            self.heightResolver = heightResolver
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            // A recognisable page behind the sheet, so the backdrop's dimming is visible.
            view.backgroundColor = .systemTeal
            view.addSubview(backdrop)
            view.addSubview(sheetView)
            RoktBottomSheetPresentationController.applySheetAppearance(to: sheetView,
                                                                       cornerRadius: cornerRadius)
        }

        // Mirrors containerViewDidLayoutSubviews: the frames follow the container's final bounds,
        // which the snapshot device config only applies after the view is loaded.
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            backdrop.frame = view.bounds
            let maximum = RoktBottomSheetPresentationController.maximumSheetHeight(
                containerHeight: view.bounds.height,
                topSafeArea: view.safeAreaInsets.top
            )
            sheetView.frame = RoktBottomSheetPresentationController.sheetFrame(
                containerSize: view.bounds.size,
                topSafeArea: view.safeAreaInsets.top,
                bottomSafeArea: view.safeAreaInsets.bottom,
                requestedHeight: heightResolver(maximum)
            )
        }
    }

    private func sheetContent() -> UIView {
        let content = VStack(alignment: .leading, spacing: 12) {
            Text("Your order is confirmed").font(.headline)
            Text("A representative offer body, long enough to show how the sheet's content sits "
                 + "against its rounded top corners and the screen edges.")
                .font(.subheadline)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)

        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .white
        return hosting.view
    }

    private func host(cornerRadius: CGFloat = 16,
                      heightResolver: @escaping (CGFloat) -> CGFloat) -> UIViewController {
        ContainerHost(sheetView: sheetContent(),
                      cornerRadius: cornerRadius,
                      heightResolver: heightResolver)
    }

    private func assertContainerSnapshot(_ controller: UIViewController,
                                         file: StaticString = #file,
                                         testName: String = #function,
                                         line: UInt = #line) {
        assertSnapshot(
            of: controller,
            as: .image(on: snapshotDevice,
                       precision: snapshotPrecision,
                       perceptualPrecision: snapshotPerceptualPrecision),
            file: file,
            testName: testName,
            line: line
        )
    }

    /// The regression this whole change exists to prevent: any gutter on the left, right or
    /// bottom edge shows up here as a band of the teal page behind the sheet.
    func testSnapshot_fixedHeightIsFlushWithScreenEdges() {
        assertContainerSnapshot(host(heightResolver: { _ in 400 }))
    }

    func testSnapshot_percentageHeight() {
        assertContainerSnapshot(host(heightResolver: { maximum in maximum * 0.5 }))
    }

    /// The expanded state of a percentage sheet: stops at the top safe area, still flush below.
    func testSnapshot_expandedToMaximumHeight() {
        assertContainerSnapshot(host(heightResolver: { maximum in maximum }))
    }

    /// A short wrap-content sheet, where the corner radius is most of what you see.
    func testSnapshot_shortSheetWithLargeCornerRadius() {
        assertContainerSnapshot(host(cornerRadius: 32, heightResolver: { _ in 180 }))
    }

    /// A layout that sets no border radius must render square top corners.
    func testSnapshot_noCornerRadius() {
        assertContainerSnapshot(host(cornerRadius: 0, heightResolver: { _ in 300 }))
    }
}
