import XCTest
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15, *)
final class CatalogDropdownViewModelTests: XCTestCase {

    func test_isItemDisabled_detectsOutOfStock() {
        let layoutState = LayoutState()
        let enabledItem = CatalogItem.mock(catalogItemId: "enabled", inventoryStatus: "InStock")
        let disabledItem = CatalogItem.mock(catalogItemId: "disabled", inventoryStatus: "OutOfStock")
        layoutState.items[LayoutState.fullOfferKey] = OfferModel.mock(catalogItems: [enabledItem, disabledItem])

        let viewModel = makeViewModel(layoutState: layoutState, openChildrenCount: 2)

        XCTAssertFalse(viewModel.isItemDisabled(at: 0))
        XCTAssertTrue(viewModel.isItemDisabled(at: 1))
    }

    func test_isItemDisabled_outOfBoundsReturnsFalse() {
        let layoutState = LayoutState()
        layoutState.items[LayoutState.fullOfferKey] = OfferModel.mock(catalogItems: [])

        let viewModel = makeViewModel(layoutState: layoutState, openChildrenCount: 0)

        XCTAssertFalse(viewModel.isItemDisabled(at: -1))
        XCTAssertFalse(viewModel.isItemDisabled(at: 0))
    }

    func test_handleItemSelection_sendsUserInteractionEvent() {
        // Arrange
        let layoutState = LayoutState()
        let eventService = MockEventService()
        let catalogItem1 = CatalogItem.mock(catalogItemId: "item1")
        let catalogItem2 = CatalogItem.mock(catalogItemId: "item2")
        layoutState.items[LayoutState.fullOfferKey] = OfferModel.mock(catalogItems: [catalogItem1, catalogItem2])

        let viewModel = makeViewModel(layoutState: layoutState, openChildrenCount: 2, eventService: eventService)

        // Act
        viewModel.handleItemSelection(at: 1)

        // Assert
        XCTAssertTrue(eventService.cartItemUserInteractionCalled, "Should call cartItemUserInteraction")
        XCTAssertEqual(eventService.lastUserInteractionItemId, "item2", "Should send correct item ID")
        XCTAssertEqual(eventService.lastUserInteractionAction, .DropDownItemSelected, "Should send DropDownItemSelected action")
        XCTAssertEqual(eventService.lastUserInteractionContext, .CatalogDropDown, "Should send CatalogDropDown context")
    }

    func test_handleItemSelection_sendsCorrectItemId_forFirstItem() {
        // Arrange
        let layoutState = LayoutState()
        let eventService = MockEventService()
        let catalogItem1 = CatalogItem.mock(catalogItemId: "first-item")
        let catalogItem2 = CatalogItem.mock(catalogItemId: "second-item")
        layoutState.items[LayoutState.fullOfferKey] = OfferModel.mock(catalogItems: [catalogItem1, catalogItem2])

        let viewModel = makeViewModel(layoutState: layoutState, openChildrenCount: 2, eventService: eventService)

        // Act
        viewModel.handleItemSelection(at: 0)

        // Assert
        XCTAssertTrue(eventService.cartItemUserInteractionCalled)
        XCTAssertEqual(eventService.lastUserInteractionItemId, "first-item")
    }

    private func makeViewModel(
        layoutState: LayoutState,
        openChildrenCount: Int,
        eventService: EventDiagnosticServicing? = nil
    ) -> CatalogDropdownViewModel {
        let children = Array(repeating: LayoutSchemaViewModel.empty, count: openChildrenCount)

        return CatalogDropdownViewModel(layoutState: layoutState,
                                        defaultStyle: nil,
                                        pressedStyle: nil,
                                        dropDownListItemDefaultStyle: nil,
                                        dropDownListItemPressedStyle: nil,
                                        dropDownDisabledItemDefaultStyle: nil,
                                        dropDownDisabledItemPressedStyle: nil,
                                        dropDownSelectedItemDefaultStyle: nil,
                                        dropDownSelectedItemPressedStyle: nil,
                                        dropDownListContainerDefaultStyle: nil,
                                        dropDownListContainerPressedStyle: nil,
                                        validatorFieldKey: nil,
                                        validatorRules: [],
                                        validateOnChange: false,
                                        a11yLabel: nil,
                                        openDropdownChildren: children,
                                        closedTemplate: .empty,
                                        closedDefaultTemplate: .empty,
                                        requiredSelectionErrorTemplate: nil,
                                        eventService: eventService)
    }
}
