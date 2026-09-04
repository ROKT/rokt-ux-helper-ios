import XCTest
import UIKit
import DcuiSchema
@testable import RoktUXHelper

// Geometry only. Real presentation behaviour across OS versions is covered by the throwaway
// probe app, not here: presenting for real inside the test bundle is what makes these flaky.
@available(iOS 15, *)
final class TestRoktBottomSheetPresentationController: XCTestCase {

    private let container = CGSize(width: 390, height: 844)
    private let topSafeArea: CGFloat = 59

    private func frame(_ requestedHeight: CGFloat) -> CGRect {
        RoktBottomSheetPresentationController.sheetFrame(containerSize: container,
                                                         topSafeArea: topSafeArea,
                                                         requestedHeight: requestedHeight)
    }

    private func makeController(allowBackdropToClose: Bool) -> RoktBottomSheetPresentationController {
        RoktBottomSheetPresentationController(presentedViewController: UIViewController(),
                                              presenting: nil,
                                              heightResolver: { _ in 400 },
                                              cornerRadius: 24,
                                              allowBackdropToClose: allowBackdropToClose)
    }

    // The whole point of the setting: no gutter on the three attached edges.
    func testSheetIsFlushWithLeftRightAndBottomEdges() {
        let sheet = frame(400)

        XCTAssertEqual(sheet.minX, 0, accuracy: 0.001)
        XCTAssertEqual(container.width - sheet.maxX, 0, accuracy: 0.001)
        XCTAssertEqual(container.height - sheet.maxY, 0, accuracy: 0.001)
    }

    func testSheetUsesFullContainerWidth() {
        XCTAssertEqual(frame(400).width, container.width, accuracy: 0.001)
    }

    // The custom-detent path renders `height + safeAreaInsets.bottom`. This must not.
    func testRequestedHeightIsHonouredExactly() {
        XCTAssertEqual(frame(400).height, 400, accuracy: 0.001)
        XCTAssertEqual(frame(437.5).height, 437.5, accuracy: 0.001)
    }

    func testHeightIsClampedToTheAvailableHeight() {
        let maximum = RoktBottomSheetPresentationController.maximumSheetHeight(
            containerHeight: container.height,
            topSafeArea: topSafeArea
        )

        XCTAssertEqual(frame(100_000).height, maximum, accuracy: 0.001)
        XCTAssertEqual(frame(100_000).minY, container.height - maximum, accuracy: 0.001)
    }

    func testHeightIsClampedToAtLeastOnePoint() {
        XCTAssertEqual(frame(0).height, 1, accuracy: 0.001)
        XCTAssertEqual(frame(-50).height, 1, accuracy: 0.001)
    }

    // Expanding stops at the top safe area, where UIKit's .large() detent stops.
    func testMaximumHeightLeavesTheTopSafeAreaUncovered() {
        let maximum = RoktBottomSheetPresentationController.maximumSheetHeight(
            containerHeight: container.height,
            topSafeArea: topSafeArea
        )

        XCTAssertEqual(maximum, container.height - topSafeArea, accuracy: 0.001)
        XCTAssertEqual(frame(maximum).minY, topSafeArea, accuracy: 0.001)
    }

    func testSheetStaysFlushAtEveryHeight() {
        for requested in [1, 80, 200, 437.5, 844, 5000] as [CGFloat] {
            let sheet = frame(requested)
            XCTAssertEqual(sheet.minX, 0, accuracy: 0.001, "left inset at \(requested)")
            XCTAssertEqual(container.width - sheet.maxX, 0, accuracy: 0.001, "right inset at \(requested)")
            XCTAssertEqual(container.height - sheet.maxY, 0, accuracy: 0.001, "bottom inset at \(requested)")
        }
    }

    func testZeroSizedContainerDoesNotProduceNegativeGeometry() {
        let sheet = RoktBottomSheetPresentationController.sheetFrame(containerSize: .zero,
                                                                     topSafeArea: 0,
                                                                     requestedHeight: 400)

        XCTAssertGreaterThanOrEqual(sheet.height, 0)
        XCTAssertFalse(sheet.height.isNaN)
    }

    // A top safe area larger than the container must not yield a negative maximum.
    func testMaximumHeightNeverGoesNegative() {
        let maximum = RoktBottomSheetPresentationController.maximumSheetHeight(containerHeight: 40,
                                                                               topSafeArea: 59)

        XCTAssertEqual(maximum, 0, accuracy: 0.001)
    }

    // MARK: Height resolution

    private let available: CGFloat = 785

    func testFixedHeightResolvesToThatManyPoints() {
        let resolve = RoktBottomSheetPresentationController.heightResolver(for: .fixed(400))

        XCTAssertEqual(resolve(available), 400, accuracy: 0.001)
    }

    func testPercentageHeightResolvesAgainstAvailableHeight() {
        let resolve = RoktBottomSheetPresentationController.heightResolver(for: .percentage(60))

        XCTAssertEqual(resolve(available), available * 0.6, accuracy: 0.001)
    }

    func testFitHeightTakesTheWholeAvailableHeight() {
        let resolve = RoktBottomSheetPresentationController.heightResolver(for: .fit(.fitHeight))

        XCTAssertEqual(resolve(available), available, accuracy: 0.001)
    }

    // Wrap-content is sized by its content; it only needs a starting height to measure against.
    func testWrapContentStartsAtHalfTheAvailableHeight() {
        let resolve = RoktBottomSheetPresentationController.heightResolver(for: .fit(.wrapContent))

        XCTAssertEqual(resolve(available), available/2, accuracy: 0.001)
    }

    func testAbsentHeightStartsAtHalfTheAvailableHeight() {
        let resolve = RoktBottomSheetPresentationController.heightResolver(for: nil)

        XCTAssertEqual(resolve(available), available/2, accuracy: 0.001)
    }

    // A percentage sheet is the expandable one: it must still be clamped when expanded.
    func testPercentageOverOneHundredIsClampedByTheFrame() {
        let resolve = RoktBottomSheetPresentationController.heightResolver(for: .percentage(150))
        let sheet = frame(resolve(available))

        XCTAssertEqual(sheet.height,
                       RoktBottomSheetPresentationController.maximumSheetHeight(
                           containerHeight: container.height,
                           topSafeArea: topSafeArea
                       ),
                       accuracy: 0.001)
    }

    // MARK: Appearance

    // The snapshot references bake in the backdrop's dimming, so pin it here rather than trusting
    // that a reference image "looks dimmed".
    func testBackdropIsBlackAtFortyPercent() {
        let backdrop = RoktBottomSheetPresentationController.makeBackdrop()

        var white: CGFloat = -1
        var alpha: CGFloat = -1
        XCTAssertTrue(backdrop.backgroundColor?.getWhite(&white, alpha: &alpha) ?? false)
        XCTAssertEqual(white, 0, accuracy: 0.001)
        XCTAssertEqual(alpha, 0.4, accuracy: 0.001)
        XCTAssertEqual(backdrop.alpha, 1, accuracy: 0.001)
    }

    // A backdrop in the a11y tree would put an unlabelled element ahead of the sheet's content.
    func testBackdropIsHiddenFromAccessibility() {
        let backdrop = RoktBottomSheetPresentationController.makeBackdrop()

        XCTAssertFalse(backdrop.isAccessibilityElement)
        XCTAssertTrue(backdrop.accessibilityElementsHidden)
    }

    func testSheetAppearanceRoundsTopCorners() {
        let view = UIView()

        RoktBottomSheetPresentationController.applySheetAppearance(to: view, cornerRadius: 24)

        XCTAssertEqual(view.layer.cornerRadius, 24, accuracy: 0.001)
        XCTAssertEqual(view.layer.maskedCorners, [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        XCTAssertTrue(view.layer.masksToBounds)
    }

    // The modal flag belongs on the container, not the sheet: it hides the flagged view's
    // siblings, and the presenting app's view is a sibling of the container.
    func testVoiceOverIsTrappedOnTheContainerNotTheSheet() {
        let sheet = UIView()

        RoktBottomSheetPresentationController.applySheetAppearance(to: sheet, cornerRadius: 24)

        XCTAssertFalse(sheet.accessibilityViewIsModal)
    }

    func testAccessibilityEscapeDismissesADismissibleSheet() {
        let controller = makeController(allowBackdropToClose: true)

        XCTAssertTrue(controller.performAccessibilityEscape())
    }

    func testAccessibilityEscapeIsUnhandledWhenTheSheetCannotBeDismissed() {
        let controller = makeController(allowBackdropToClose: false)

        XCTAssertFalse(controller.performAccessibilityEscape())
    }
}
