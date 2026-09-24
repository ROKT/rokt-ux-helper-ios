import XCTest
import UIKit
import SwiftUI
import DcuiSchema
@testable import RoktUXHelper

// Geometry only. Real presentation behaviour across OS versions is covered by the throwaway
// probe app, not here: presenting for real inside the test bundle is what makes these flaky.
@available(iOS 15, *)
final class TestRoktBottomSheetPresentationController: XCTestCase {

    private let container = CGSize(width: 390, height: 844)
    private let topSafeArea: CGFloat = 59
    private let bottomSafeArea: CGFloat = 34

    private func frame(_ requestedHeight: CGFloat) -> CGRect {
        RoktBottomSheetPresentationController.sheetFrame(containerSize: container,
                                                         topSafeArea: topSafeArea,
                                                         bottomSafeArea: bottomSafeArea,
                                                         requestedHeight: requestedHeight)
    }

    /// What the hosted content actually gets: the sheet reaches the bottom of the screen, so
    /// UIKit insets its content by the bottom safe area.
    private func contentHeight(_ requestedHeight: CGFloat) -> CGFloat {
        frame(requestedHeight).height - bottomSafeArea
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

    // Measured against the custom-detent path on device: a detent of 400 yields a 434pt frame
    // whose content region is 400. The requested height is the content's, not the frame's.
    func testContentGetsTheRequestedHeightAndTheFrameCarriesTheSafeArea() {
        XCTAssertEqual(contentHeight(400), 400, accuracy: 0.001)
        XCTAssertEqual(frame(400).height, 434, accuracy: 0.001)

        XCTAssertEqual(contentHeight(437.5), 437.5, accuracy: 0.001)
        XCTAssertEqual(frame(437.5).height, 471.5, accuracy: 0.001)
    }

    // A device with no home indicator has nothing to compensate for.
    func testNoBottomSafeAreaMeansNoCompensation() {
        let sheet = RoktBottomSheetPresentationController.sheetFrame(containerSize: container,
                                                                     topSafeArea: topSafeArea,
                                                                     bottomSafeArea: 0,
                                                                     requestedHeight: 400)

        XCTAssertEqual(sheet.height, 400, accuracy: 0.001)
    }

    func testHeightIsClampedToTheAvailableHeight() {
        let maximum = RoktBottomSheetPresentationController.maximumSheetHeight(
            containerHeight: container.height,
            topSafeArea: topSafeArea
        )

        XCTAssertEqual(frame(100_000).height, maximum, accuracy: 0.001)
        XCTAssertEqual(frame(100_000).minY, container.height - maximum, accuracy: 0.001)
    }

    // The clamp exists so the hosted tree always gets a non-zero layout proposal to measure
    // against, so it is the content that must not collapse, not the frame.
    func testContentIsClampedToAtLeastOnePoint() {
        XCTAssertEqual(contentHeight(0), 1, accuracy: 0.001)
        XCTAssertEqual(contentHeight(-50), 1, accuracy: 0.001)
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
                                                                     bottomSafeArea: 0,
                                                                     requestedHeight: 400)

        XCTAssertGreaterThanOrEqual(sheet.height, 0)
        XCTAssertFalse(sheet.height.isNaN)
    }

    // MARK: Heights that are not numbers

    // The crash this guards: the frame is assigned to the presented view on every layout pass, and
    // a view frame holding a value that is not a number raises an exception no caller can catch,
    // which stops the host application. `min` and `max` pass such a value straight through, so the
    // existing clamp is not what stops it.
    func testRequestedHeightThatIsNotANumberNeverReachesTheFrame() {
        let sheet = frame(.nan)

        XCTAssertTrue(sheet.origin.y.isFinite)
        XCTAssertTrue(sheet.size.height.isFinite)
        XCTAssertGreaterThanOrEqual(sheet.height, 0)
        XCTAssertLessThanOrEqual(sheet.maxY, container.height)
    }

    // Falls back to the half-height a layout stating no height at all gets, so the sheet is still
    // on screen and its content still has room to measure itself.
    func testRequestedHeightThatIsNotANumberFallsBackToHalfTheAvailableHeight() {
        let maximum = RoktBottomSheetPresentationController.maximumSheetHeight(
            containerHeight: container.height,
            topSafeArea: topSafeArea
        )

        XCTAssertEqual(frame(.nan).height, frame(maximum/2).height, accuracy: 0.001)
    }

    // An infinite height is treated the same as one that is not a number, matching the rule the
    // style parser applies to an infinite edge. A very large finite height is still just clamped,
    // which is what `testHeightIsClampedToTheAvailableHeight` covers.
    func testInfiniteRequestedHeightFallsBackTheSameWay() {
        let maximum = RoktBottomSheetPresentationController.maximumSheetHeight(
            containerHeight: container.height,
            topSafeArea: topSafeArea
        )

        XCTAssertEqual(frame(.infinity).height, frame(maximum/2).height, accuracy: 0.001)
        XCTAssertEqual(frame(-.infinity).height, frame(maximum/2).height, accuracy: 0.001)
    }

    // UIKit hands the container's own geometry in, so sanitising only the requested height would
    // leave a second way for a value that is not a number to reach the rect.
    func testContainerGeometryThatIsNotANumberProducesAFiniteFrame() {
        let sheet = RoktBottomSheetPresentationController.sheetFrame(
            containerSize: CGSize(width: CGFloat.nan, height: CGFloat.nan),
            topSafeArea: .nan,
            bottomSafeArea: .nan,
            requestedHeight: 400
        )

        XCTAssertTrue(sheet.origin.x.isFinite)
        XCTAssertTrue(sheet.origin.y.isFinite)
        XCTAssertTrue(sheet.size.width.isFinite)
        XCTAssertTrue(sheet.size.height.isFinite)
    }

    func testClampedHeightRejectsAHeightThatIsNotANumber() {
        XCTAssertEqual(RoktBottomSheetPresentationController.clampedHeight(.nan, maximum: 800),
                       400,
                       accuracy: 0.001)
        XCTAssertEqual(RoktBottomSheetPresentationController.clampedHeight(400, maximum: .nan),
                       0,
                       accuracy: 0.001)
    }

    func testClampedHeightStillClampsOrdinaryHeights() {
        XCTAssertEqual(RoktBottomSheetPresentationController.clampedHeight(400, maximum: 800),
                       400,
                       accuracy: 0.001)
        XCTAssertEqual(RoktBottomSheetPresentationController.clampedHeight(900, maximum: 800),
                       800,
                       accuracy: 0.001)
        XCTAssertEqual(RoktBottomSheetPresentationController.clampedHeight(-50, maximum: 800),
                       1,
                       accuracy: 0.001)
    }

    // The wrap-content sheet is sized by a height SwiftUI reports for its content, with the
    // layout's own padding and margin added to it. A report that is not a number is ignored, so
    // the sheet keeps the height it already has rather than being resized to an invalid one.
    func testAReportedSizeThatIsNotANumberIsIgnored() {
        XCTAssertNil(UIViewController.sheetHeight(reportedBy: .nan))
        XCTAssertNil(UIViewController.sheetHeight(reportedBy: .infinity))
        XCTAssertNil(UIViewController.sheetHeight(reportedBy: -.infinity))
    }

    func testAReportedSizeIsUsedAndFlooredAtOnePoint() {
        XCTAssertEqual(UIViewController.sheetHeight(reportedBy: 437.5), 437.5)
        XCTAssertEqual(UIViewController.sheetHeight(reportedBy: 0), 1)
        XCTAssertEqual(UIViewController.sheetHeight(reportedBy: -50), 1)
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

    // MARK: Presentation gate

    private func shouldPresentFullBleed(_ presentation: BottomSheetPresentation?,
                                        _ sizeClass: UIUserInterfaceSizeClass) -> Bool {
        RoktBottomSheetPresentationController.shouldPresentFullBleed(presentation: presentation,
                                                                     horizontalSizeClass: sizeClass)
    }

    func testFullBleedIsUsedOnlyForTheFullBleedSettingInCompactWidth() {
        XCTAssertTrue(shouldPresentFullBleed(.fullBleed, .compact))
    }

    // Every layout published before schema 2.10 decodes with the field absent.
    func testAbsentPresentationKeepsThePlatformSheet() {
        XCTAssertFalse(shouldPresentFullBleed(nil, .compact))
    }

    func testPlatformDefaultKeepsThePlatformSheet() {
        XCTAssertFalse(shouldPresentFullBleed(.platformDefault, .compact))
    }

    // Regular width would stretch the sheet across an iPad.
    func testRegularWidthKeepsThePlatformSheet() {
        XCTAssertFalse(shouldPresentFullBleed(.fullBleed, .regular))
    }

    // Matched positively, so an unknown size class must not opt in.
    func testUnspecifiedSizeClassKeepsThePlatformSheet() {
        XCTAssertFalse(shouldPresentFullBleed(.fullBleed, .unspecified))
    }

    // MARK: Expanded-state resolvers

    // The bug this guards: passing a resolved point value in would freeze the sheet at a height
    // computed for the previous container, so a rotation would strand it.
    func testExpandedAndCollapsedResolversBothStayRelative() {
        let collapsed: (CGFloat) -> CGFloat = { $0 * 0.6 }

        let expandedResolver = RoktBottomSheetPresentationController.resolver(expanded: true,
                                                                              collapsed: collapsed)
        let collapsedResolver = RoktBottomSheetPresentationController.resolver(expanded: false,
                                                                               collapsed: collapsed)

        // Same resolvers, two container heights: both re-resolve rather than returning a constant.
        XCTAssertEqual(expandedResolver(785), 785, accuracy: 0.001)
        XCTAssertEqual(expandedResolver(331), 331, accuracy: 0.001)
        XCTAssertEqual(collapsedResolver(785), 471, accuracy: 0.001)
        XCTAssertEqual(collapsedResolver(331), 198.6, accuracy: 0.001)
    }

    // MARK: Expanded-state reading

    private func items(expandedStateValue: Int?) -> [String: Any] {
        guard let expandedStateValue else { return [:] }
        let map = RoktUXCustomStateMap(uniqueKeysWithValues: [
            (key: CustomStateIdentifiable(position: nil, key: "BottomSheetExpandedState"),
             value: expandedStateValue)
        ])
        return [LayoutState.customStateMap: Binding<RoktUXCustomStateMap?>.constant(map)]
    }

    func testExpandedStateIsReadFromTheLayoutsCustomStateMap() {
        XCTAssertTrue(UIViewController.isBottomSheetExpanded(in: items(expandedStateValue: 1)))
    }

    func testExpandedStateIsOffWhenTheFlagIsZero() {
        XCTAssertFalse(UIViewController.isBottomSheetExpanded(in: items(expandedStateValue: 0)))
    }

    func testExpandedStateIsOffWhenThereIsNoCustomStateMap() {
        XCTAssertFalse(UIViewController.isBottomSheetExpanded(in: items(expandedStateValue: nil)))
    }
}
