import XCTest
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogItemPredicateContextTests: XCTestCase {
    func test_cardPredicatesIgnoreTheSharedActiveItemAndOfferIndex() throws {
        let slots = try CatalogProductFixture.slots()
        let first = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let second = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 1))
        let state = LayoutState()
        state.items[LayoutState.activeCatalogItemKey] = second.catalogItem
        let predicates: [WhenPredicate] = [
            .placeholder(.textValue(.init(condition: .is, input: "%^DATA.catalogItem.productCartAttribute1^%", value: "title"))),
            .placeholder(.textValue(.init(condition: .is, input: "%^DATA.creative.copy.title^%", value: "Product offer"))),
            .creativeCopy(.init(condition: .exists, value: "firstCardOnly")),
            .creativeCopy(.init(condition: .exists, value: "parentOnly")),
            .creativeCopy(.init(condition: .notExists, value: "otherOfferOnly"))
        ]
        let firstModel = makeModel(predicates: predicates, slots: slots, state: state, context: first)
        let secondModel = makeModel(predicates: predicates, slots: slots, state: state, context: second)
        let uiState = get_mock_uistate(currentProgress: 0)

        XCTAssertTrue(firstModel.shouldApply(uiState))
        XCTAssertFalse(secondModel.shouldApply(uiState))
        state.items[LayoutState.activeCatalogItemKey] = first.catalogItem
        XCTAssertTrue(firstModel.shouldApply(uiState))
        XCTAssertFalse(secondModel.shouldApply(uiState))
        XCTAssertEqual((state.items[LayoutState.activeCatalogItemKey] as? CatalogItem)?.catalogItemId,
                       first.catalogItem.catalogItemId)
    }

    func test_nilContextKeepsLegacyActiveItemAndCurrentOfferLookup() throws {
        let slots = try CatalogProductFixture.slots()
        let first = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let second = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 1))
        let state = LayoutState()
        state.items[LayoutState.activeCatalogItemKey] = first.catalogItem
        let predicates: [WhenPredicate] = [
            .placeholder(.textValue(.init(condition: .is, input: "%^DATA.catalogItem.productCartAttribute1^%", value: "title"))),
            .creativeCopy(.init(condition: .exists, value: "parentOnly"))
        ]
        let model = makeModel(predicates: predicates, slots: slots, state: state)

        XCTAssertNil(model.catalogItemContext)
        XCTAssertTrue(model.shouldApply(get_mock_uistate(currentProgress: 1)))
        XCTAssertFalse(model.shouldApply(get_mock_uistate(currentProgress: 0)))
        state.items[LayoutState.activeCatalogItemKey] = second.catalogItem
        XCTAssertFalse(model.shouldApply(get_mock_uistate(currentProgress: 1)))
    }

    func test_cardContextDoesNotReplaceOuterProgressionPredicates() throws {
        let slots = try CatalogProductFixture.slots()
        let card = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let state = LayoutState()
        let model = makeModel(predicates: [.progression(.init(condition: .is, value: "1"))],
                              slots: slots, state: state, context: card)

        XCTAssertTrue(model.shouldApply(get_mock_uistate(currentProgress: 1)))
        XCTAssertFalse(model.shouldApply(get_mock_uistate(currentProgress: 0)))
        XCTAssertNil(state.items[LayoutState.activeCatalogItemKey])
    }

    func test_rowStylePredicatesCanUseTheSameCardContext() throws {
        let slots = try CatalogProductFixture.slots()
        let card = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let state = LayoutState()
        let row = RowViewModel(children: [], stylingProperties: nil, animatableStyle: nil,
                               accessibilityGrouped: false, layoutState: state,
                               predicates: [.creativeCopy(.init(condition: .exists, value: "firstCardOnly"))],
                               globalBreakPoints: nil, offers: slots.map(\.offer), catalogItemContext: card)

        XCTAssertTrue(row.shouldApply(get_mock_uistate(currentProgress: 0)))
        XCTAssertNil(state.items[LayoutState.activeCatalogItemKey])
    }

    private func makeModel(predicates: [WhenPredicate], slots: [SlotModel], state: LayoutState,
                           context: CatalogItemContext? = nil) -> WhenViewModel {
        WhenViewModel(predicates: predicates, transition: nil, offers: slots.map(\.offer),
                      globalBreakPoints: nil, layoutState: state, catalogItemContext: context)
    }
}
