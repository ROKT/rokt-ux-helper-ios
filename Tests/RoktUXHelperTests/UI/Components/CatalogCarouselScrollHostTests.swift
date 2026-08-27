import XCTest
import SwiftUI
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class CatalogCarouselScrollHostTests: XCTestCase {
    func test_hostRetainsItsChildControllerAndTearsDownDelegatesAndContent() throws {
        let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 3))
        var controller: CatalogCarouselViewController? = CatalogCarouselViewController(model: model)
        weak var weakController = controller
        let geometry = model.geometry(viewportWidth: 300, breakpointIndex: 0)
        controller?.update(content: AnyView(Text("Example products")), geometry: geometry,
                           isRightToLeft: false, isEnabled: true)
        weak var weakHost = controller?.hostingController
        XCTAssertNotNil(weakHost)
        XCTAssertTrue(controller?.hostingController?.parent === controller)
        XCTAssertEqual(controller?.children.count, 1)
        XCTAssertTrue(controller?.scrollView.delegate === controller)
        controller?.tearDown()
        XCTAssertNil(controller?.scrollView.delegate)
        XCTAssertNil(controller?.scrollView.accessibilityScrollHandler)
        XCTAssertNil(controller?.hostingController)
        XCTAssertEqual(controller?.children.count, 0)
        XCTAssertNil(weakHost)
        controller = nil
        XCTAssertNil(weakController)
    }

    func test_contentSizeAndOffsetAreRecomputedWhenTheViewportChanges() throws {
        let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 4))
        let controller = CatalogCarouselViewController(model: model)
        let narrow = model.geometry(viewportWidth: 200, breakpointIndex: 0)
        controller.update(content: AnyView(Text("Products")), geometry: narrow, isRightToLeft: false, isEnabled: true)
        controller.view.frame = CGRect(x: 0, y: 0, width: 200, height: 120)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(controller.scrollView.contentSize.width, narrow.contentWidth, accuracy: 0.5)
        XCTAssertEqual(controller.scrollView.contentSize.height, 120, accuracy: 0.5)
        model.scrolled(offset: narrow.offset(for: 2), geometry: narrow)
        let wide = model.geometry(viewportWidth: 400, breakpointIndex: 0)
        controller.update(content: AnyView(Text("Products")), geometry: wide, isRightToLeft: false, isEnabled: true)
        controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 80)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(controller.scrollView.contentSize.width, wide.contentWidth, accuracy: 0.5)
        XCTAssertEqual(controller.scrollView.contentSize.height, 80, accuracy: 0.5)
        XCTAssertEqual(controller.scrollView.contentOffset.x, wide.offset(for: 2), accuracy: 0.5)
        controller.tearDown()
    }

    func test_horizontalHostLeavesVerticalScrollingToTheParentAndDisablesSingleCardScroll() throws {
        let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 1))
        let controller = CatalogCarouselViewController(model: model)
        controller.update(content: AnyView(Text("Product")), geometry: model.geometry(viewportWidth: 300, breakpointIndex: 0),
                          isRightToLeft: false, isEnabled: true)
        let parent = UIScrollView()
        parent.contentSize = CGSize(width: 300, height: 1000)
        parent.addSubview(controller.view)
        XCTAssertFalse(controller.scrollView.alwaysBounceVertical)
        XCTAssertTrue(controller.scrollView.isDirectionalLockEnabled)
        XCTAssertFalse(controller.scrollView.isScrollEnabled)
        XCTAssertEqual(controller.scrollView.contentInsetAdjustmentBehavior, .never)
        XCTAssertFalse(controller.scrollView.gestureRecognizerShouldBegin(controller.scrollView.panGestureRecognizer))
        XCTAssertEqual(parent.contentSize.height, 1000)
        controller.tearDown()
    }

    func test_mountAndScrollCallbacksHaveSeparateLifecycles() throws {
        var mountCount = 0
        var reached: [Int] = []
        let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 3),
                                                     callbacks: .init(onMount: { _ in mountCount += 1 },
                                                                      onReach: { context, _ in
                                                                      reached.append(context.itemIndex) }))
        let controller = CatalogCarouselViewController(model: model)
        let geometry = model.geometry(viewportWidth: 100, breakpointIndex: 0)
        controller.update(content: AnyView(Text("Products")), geometry: geometry, isRightToLeft: false, isEnabled: true)
        controller.view.frame = CGRect(x: 0, y: 0, width: 100, height: 80)
        controller.view.layoutIfNeeded()
        controller.viewDidAppear(false)
        controller.viewDidAppear(false)
        XCTAssertEqual(mountCount, 1)
        controller.scrollView.setContentOffset(CGPoint(x: 60, y: 0), animated: false)
        XCTAssertEqual(reached, [])
        controller.scrollView.setContentOffset(.zero, animated: false)
        controller.scrollViewWillBeginDragging(controller.scrollView)
        controller.scrollView.setContentOffset(CGPoint(x: 60, y: 0), animated: false)
        XCTAssertEqual(reached, [1])
        controller.scrollViewDidEndDragging(controller.scrollView, willDecelerate: false)
        controller.scrollView.setContentOffset(CGPoint(x: 160, y: 0), animated: false)
        XCTAssertEqual(reached, [1])
        controller.tearDown()
    }

    func test_rightToLeftStartsAtTheFirstLogicalCard() throws {
        let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 3))
        let controller = CatalogCarouselViewController(model: model)
        let geometry = model.geometry(viewportWidth: 100, breakpointIndex: 0)
        controller.update(content: AnyView(Text("Products")), geometry: geometry, isRightToLeft: true, isEnabled: true)
        controller.view.frame = CGRect(x: 0, y: 0, width: 100, height: 80)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(controller.scrollView.contentOffset.x, geometry.maximumOffset, accuracy: 0.5)
        controller.tearDown()
    }
}
