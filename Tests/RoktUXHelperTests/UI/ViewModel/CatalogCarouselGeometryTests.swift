import XCTest
import CoreGraphics
@testable import RoktUXHelper

final class CatalogCarouselGeometryTests: XCTestCase {
    func test_emptyAndInvalidSizesStayFinite() {
        for width in [CGFloat.zero, -1, .nan, .infinity] {
            let geometry = CatalogCarouselGeometry(viewportWidth: width, itemCount: 0, viewableItems: 0, gap: 10, peek: 20)
            XCTAssertEqual(geometry.itemWidth, 0)
            XCTAssertEqual(geometry.maximumOffset, 0)
            XCTAssertEqual(geometry.visibleIndexes(at: 0), [])
            XCTAssertEqual(geometry.snappedOffset(proposedOffset: .infinity), 0)
        }
    }

    func test_oneItemUsesTheViewportWithoutPeekOrScrolling() {
        let geometry = CatalogCarouselGeometry(viewportWidth: 300, itemCount: 1, viewableItems: 3, gap: 10, peek: 20)
        XCTAssertEqual(geometry.itemWidth, 300)
        XCTAssertEqual(geometry.peek, 0)
        XCTAssertEqual(geometry.maximumOffset, 0)
        XCTAssertEqual(geometry.visibleIndexes(at: 0), [0])
    }

    func test_multipleItemsReserveBothPeeksAndGaps() {
        let geometry = CatalogCarouselGeometry(viewportWidth: 340, itemCount: 5, viewableItems: 2, gap: 10, peek: 20)
        XCTAssertEqual(geometry.itemWidth, 135)
        XCTAssertEqual(geometry.contentWidth, 715)
        XCTAssertEqual(geometry.offset(for: 0), 0)
        XCTAssertEqual(geometry.offset(for: 1), 115)
        XCTAssertEqual(geometry.offset(for: 4), 375)
        XCTAssertEqual(geometry.leadingIndex(at: 375), 3)
        XCTAssertEqual(geometry.snappedOffset(proposedOffset: 120), 115)
    }

    func test_noPeekOnlyReservesGapsBetweenVisibleItems() {
        let geometry = CatalogCarouselGeometry(viewportWidth: 340, itemCount: 5, viewableItems: 2, gap: 10, peek: 0)
        XCTAssertEqual(geometry.itemWidth, 165)
        XCTAssertEqual(geometry.maximumOffset, 525)
        let single = CatalogCarouselGeometry(viewportWidth: 340, itemCount: 5, viewableItems: 1, gap: 10, peek: 0)
        XCTAssertEqual(single.itemWidth, 340)
        XCTAssertEqual(single.gap, 10)
        XCTAssertEqual(single.offset(for: 1), 350)
    }

    func test_visibilityUsesSixtyPercentOfEachCard() {
        let geometry = CatalogCarouselGeometry(viewportWidth: 100, itemCount: 3, viewableItems: 1, gap: 0, peek: 0)
        XCTAssertEqual(geometry.visibleIndexes(at: 40), [0])
        XCTAssertEqual(geometry.visibleIndexes(at: 40.01), [])
        XCTAssertEqual(geometry.visibleIndexes(at: 59.99), [])
        XCTAssertEqual(geometry.visibleIndexes(at: 60), [1])
        XCTAssertEqual(geometry.visibleIndexes(at: 100), [1])
    }

    func test_oversizedSettingsCannotProduceNegativeCardWidths() {
        let geometry = CatalogCarouselGeometry(viewportWidth: 20, itemCount: 8, viewableItems: 4, gap: 100, peek: 500)
        XCTAssertGreaterThan(geometry.itemWidth, 0)
        XCTAssertLessThanOrEqual(geometry.itemWidth * 4 + geometry.gap * 5 + geometry.peek * 2, 20)
    }

    func test_scrollTrackingRequiresInteractionAndOnlyReportsNewHigherIndexes() {
        var tracker = CatalogCarouselScrollTracker()
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [0, 1]), [])
        tracker.beginInteraction(visibleIndexes: [0, 1])
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [1, 2]), [2])
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [2]), [])
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [5, 4, 5]), [4, 5])
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [3]), [])
        tracker.endInteraction()
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [6]), [])
    }

    func test_rotationDoesNotBecomeAScrollInteraction() {
        var tracker = CatalogCarouselScrollTracker()
        tracker.beginInteraction(visibleIndexes: [0])
        tracker.layoutChanged(visibleIndexes: [0, 1, 2])
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [2]), [])
        tracker.beginInteraction(visibleIndexes: [1, 2])
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [2]), [])
        XCTAssertEqual(tracker.newlyReachedIndexes(visibleIndexes: [3]), [3])
    }

    func test_verticalAndStationaryDragsRemainAvailableToTheParent() {
        XCTAssertTrue(CatalogCarouselGeometry.isHorizontalDrag(velocity: CGPoint(x: 30, y: 2)))
        XCTAssertTrue(CatalogCarouselGeometry.isHorizontalDrag(velocity: CGPoint(x: -30, y: 2)))
        XCTAssertFalse(CatalogCarouselGeometry.isHorizontalDrag(velocity: CGPoint(x: 2, y: 30)))
        XCTAssertFalse(CatalogCarouselGeometry.isHorizontalDrag(velocity: CGPoint(x: 20, y: 20)))
        XCTAssertFalse(CatalogCarouselGeometry.isHorizontalDrag(velocity: .zero))
    }
}
