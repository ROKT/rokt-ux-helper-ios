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

    private func makeViewModel(layoutState: LayoutState, openChildrenCount: Int) -> CatalogDropdownViewModel {
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
                                        eventService: nil)
    }
}
