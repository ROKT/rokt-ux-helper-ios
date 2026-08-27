import XCTest
import SwiftUI
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogCarouselCollectionViewModelTests: XCTestCase {
    func test_zeroOneAndManyItemsBuildExactlyOneCardPerItem() throws {
        for count in [0, 1, 5] {
            let slots = try CatalogCarouselTestFixture.slots(count: count)
            let model = CatalogCarouselTestFixture.model(slots: slots)
            XCTAssertEqual(model.cards.count, count)
            XCTAssertEqual(model.cards.map(\.context.itemIndex), Array(0..<count))
            XCTAssertTrue(model.cards.allSatisfy { $0.context.offerIndex == 1 })
        }
    }

    func test_duplicateAndMissingWireIDsDoNotMergeCards() throws {
        let slots = try CatalogCarouselTestFixture.slots(count: 4, duplicateIDs: true)
        let model = CatalogCarouselTestFixture.model(slots: slots)
        let identities = model.cards.map(\.id)
        XCTAssertEqual(Set(identities).count, 4)
        XCTAssertEqual(model.cards.map(\.context.catalogItem.token), (0..<4).map { "example-item-token-\($0)" })
        model.layoutChanged(geometry: model.geometry(viewportWidth: 600, breakpointIndex: 1))
        XCTAssertEqual(model.cards.map(\.id), identities)
    }

    func test_responsiveSettingsUseLastEntryAndHandleEmptyArrays() throws {
        let slots = try CatalogCarouselTestFixture.slots(count: 5)
        let state = MockLayoutState()
        let model = CatalogCarouselCollectionViewModel(slots: slots, offerIndex: 1, viewableItems: [1, 2],
                                                       peekThroughSize: [.fixed(10), .percentage(10)],
                                                       layoutState: state) { _ in .empty }
        XCTAssertEqual(model.geometry(viewportWidth: 400, breakpointIndex: 0).itemWidth, 380)
        XCTAssertEqual(model.geometry(viewportWidth: 400, breakpointIndex: 9).itemWidth, 160)
        let empty = CatalogCarouselCollectionViewModel(slots: slots, offerIndex: 1, viewableItems: [],
                                                       peekThroughSize: [], layoutState: state) { _ in .empty }
        XCTAssertEqual(empty.geometry(viewportWidth: 400, breakpointIndex: 0).itemWidth, 400)
    }

    func test_mountReportsEveryCardOnceRegardlessOfVisibility() throws {
        var mounted: [[CatalogItemContext]] = []
        let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 4),
                                                     callbacks: .init(onMount: { mounted.append($0) }))
        model.mounted()
        model.mounted()
        XCTAssertEqual(mounted.count, 1)
        XCTAssertEqual(mounted[0].map(\.itemIndex), [0, 1, 2, 3])
        XCTAssertEqual(model.geometry(viewportWidth: 300, breakpointIndex: 0).visibleIndexes(at: 0), [0])
        let empty = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 0),
                                                     callbacks: .init(onMount: { mounted.append($0) }))
        empty.mounted()
        XCTAssertEqual(mounted.count, 1)
    }

    func test_scrollReportsReachedCardsWithoutChangingOuterStateOrActions() throws {
        let state = MockLayoutState()
        var outerIndex = 7
        var called: [RoktActionType] = []
        let actionTypes: [RoktActionType] = [.close, .nextOffer, .progressControlNext, .progressControlPrevious]
        for action in actionTypes { state.actionCollection[action] = { _ in called.append(action) } }
        state.items[LayoutState.currentProgressKey] = Binding(get: { outerIndex }, set: { outerIndex = $0 })
        state.items[LayoutState.totalItemsKey] = 12
        var reached: [Int] = []
        let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 4), state: state,
                                                     callbacks: .init(onReach: { context, lastIndex in
            XCTAssertEqual(lastIndex, 3)
            reached.append(context.itemIndex)
        }))
        let geometry = model.geometry(viewportWidth: 100, breakpointIndex: 0)
        model.mounted()
        model.scrolled(offset: 60, geometry: geometry)
        XCTAssertEqual(reached, [])
        model.beginInteraction(offset: 0, geometry: geometry)
        model.scrolled(offset: 59.99, geometry: geometry)
        model.scrolled(offset: 60, geometry: geometry)
        model.scrolled(offset: 100, geometry: geometry)
        model.scrolled(offset: 0, geometry: geometry)
        XCTAssertEqual(reached, [1])
        XCTAssertEqual(outerIndex, 7)
        XCTAssertEqual(state.items[LayoutState.totalItemsKey] as? Int, 12)
        XCTAssertNil(state.items[LayoutState.activeCatalogItemKey])
        XCTAssertEqual(called, [])
        for action in actionTypes { state.actionCollection[action](nil) }
        XCTAssertEqual(called, actionTypes)
    }

    func test_heightCanGrowShrinkAndRemeasureAfterRotation() throws {
        let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 2))
        let narrow = model.geometry(viewportWidth: 200, breakpointIndex: 0)
        model.layoutChanged(geometry: narrow)
        model.recordHeight(80, itemIndex: 0, itemWidth: narrow.itemWidth)
        model.recordHeight(120, itemIndex: 1, itemWidth: narrow.itemWidth)
        XCTAssertEqual(model.contentHeight, 120)
        model.recordHeight(160, itemIndex: 1, itemWidth: narrow.itemWidth)
        XCTAssertEqual(model.contentHeight, 160)
        let wide = model.geometry(viewportWidth: 400, breakpointIndex: 0)
        model.layoutChanged(geometry: wide)
        model.recordHeight(60, itemIndex: 0, itemWidth: wide.itemWidth)
        XCTAssertEqual(model.contentHeight, 160)
        model.recordHeight(999, itemIndex: 1, itemWidth: narrow.itemWidth)
        model.recordHeight(70, itemIndex: 1, itemWidth: wide.itemWidth)
        XCTAssertEqual(model.contentHeight, 70)
        model.recordHeight(.nan, itemIndex: 0, itemWidth: wide.itemWidth)
        XCTAssertEqual(model.contentHeight, 70)
    }
}

@available(iOS 15, *)
enum CatalogCarouselTestFixture {
    static func slots(count: Int, duplicateIDs: Bool = false) throws -> [SlotModel] {
        let items: [[String: Any]] = (0..<count).map { index in
            ["catalog_item_id": duplicateIDs ? "" : "example-item-\(index)",
             "instance_guid": duplicateIDs ? "example-duplicate" : "example-instance-\(index)",
             "title": "Example product \(index)", "token": "example-item-token-\(index)",
             "product_cart_attribute1": index.isMultiple(of: 2) ? "title" : "price"]
        }
        let offer = try CatalogProductFixture.offer(["creative": ["copy": ["title": "Example parent"]], "catalog_items": items])
        return [SlotModel(instanceGuid: nil, offer: nil, layoutVariant: nil, jwtToken: ""),
                SlotModel(instanceGuid: "example-slot", offer: offer,
                          layoutVariant: LayoutVariantModel(layoutVariantSchema: nil, moduleName: "standard-marketing"),
                          jwtToken: "")]
    }

    static func model(slots: [SlotModel], state: MockLayoutState = MockLayoutState(),
                      callbacks: CatalogCarouselCallbacks = .init()) -> CatalogCarouselCollectionViewModel {
        CatalogCarouselCollectionViewModel(slots: slots, offerIndex: 1, viewableItems: [1], peekThroughSize: [],
                                           layoutState: state, callbacks: callbacks) { _ in .empty }
    }
}
