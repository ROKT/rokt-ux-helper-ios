//
//  CatalogDropdownViewModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

@available(iOS 15, *)
class CatalogDropdownViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    typealias Item = CatalogDropdownStyles
    let id: UUID = UUID()

    let defaultStyle: [CatalogDropdownStyles]?
    let pressedStyle: [CatalogDropdownStyles]?
    let dropDownListItemDefaultStyle: [CatalogDropdownStyles]?
    let dropDownListItemPressedStyle: [CatalogDropdownStyles]?
    let dropDownSelectedItemDefaultStyle: [CatalogDropdownStyles]?
    let dropDownSelectedItemPressedStyle: [CatalogDropdownStyles]?
    let dropDownDisabledItemDefaultStyle: [CatalogDropdownStyles]?
    let dropDownDisabledItemPressedStyle: [CatalogDropdownStyles]?
    let dropDownListContainerDefaultStyle: [CatalogDropdownStyles]?
    let dropDownListContainerPressedStyle: [CatalogDropdownStyles]?
    weak var layoutState: (any LayoutStateRepresenting)?
    weak var eventService: EventDiagnosticServicing?
    let a11yLabel: String?
    let openDropdownChildren: [LayoutSchemaViewModel]
    let closedTemplate: LayoutSchemaViewModel?
    let closedDefaultTemplate: LayoutSchemaViewModel?
    let requiredSelectionErrorTemplate: LayoutSchemaViewModel?
    let validatorFieldKey: String?
    let validatorRules: [CatalogDropDownValidators]
    let validateOnChange: Bool

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    var catalogItems: [CatalogItem] {
        guard let fullOffer = layoutState?.items[LayoutState.fullOfferKey] as? OfferModel else {
            return []
        }
        return fullOffer.catalogItems ?? []
    }

    init(layoutState: any LayoutStateRepresenting,
         defaultStyle: [CatalogDropdownStyles]?,
         pressedStyle: [CatalogDropdownStyles]?,
         dropDownListItemDefaultStyle: [CatalogDropdownStyles]?,
         dropDownListItemPressedStyle: [CatalogDropdownStyles]?,
         dropDownDisabledItemDefaultStyle: [CatalogDropdownStyles]?,
         dropDownDisabledItemPressedStyle: [CatalogDropdownStyles]?,
         dropDownSelectedItemDefaultStyle: [CatalogDropdownStyles]?,
         dropDownSelectedItemPressedStyle: [CatalogDropdownStyles]?,
         dropDownListContainerDefaultStyle: [CatalogDropdownStyles]?,
         dropDownListContainerPressedStyle: [CatalogDropdownStyles]?,
         validatorFieldKey: String?,
         validatorRules: [CatalogDropDownValidators],
         validateOnChange: Bool,
         a11yLabel: String?,
         openDropdownChildren: [LayoutSchemaViewModel],
         closedTemplate: LayoutSchemaViewModel?,
         closedDefaultTemplate: LayoutSchemaViewModel?,
         requiredSelectionErrorTemplate: LayoutSchemaViewModel?,
         eventService: EventDiagnosticServicing?) {
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.dropDownListItemDefaultStyle = dropDownListItemDefaultStyle
        self.dropDownListItemPressedStyle = dropDownListItemPressedStyle
        self.dropDownDisabledItemDefaultStyle = dropDownDisabledItemDefaultStyle
        self.dropDownDisabledItemPressedStyle = dropDownDisabledItemPressedStyle
        self.dropDownSelectedItemDefaultStyle = dropDownSelectedItemDefaultStyle
        self.dropDownSelectedItemPressedStyle = dropDownSelectedItemPressedStyle
        self.dropDownListContainerDefaultStyle = dropDownListContainerDefaultStyle
        self.dropDownListContainerPressedStyle = dropDownListContainerPressedStyle
        self.layoutState = layoutState
        self.eventService = eventService
        self.a11yLabel = a11yLabel
        self.openDropdownChildren = openDropdownChildren
        self.closedTemplate = closedTemplate
        self.closedDefaultTemplate = closedDefaultTemplate
        self.requiredSelectionErrorTemplate = requiredSelectionErrorTemplate
        self.validatorFieldKey = validatorFieldKey
        self.validatorRules = validatorRules
        self.validateOnChange = validateOnChange
    }

    func isItemDisabled(at index: Int) -> Bool {
        guard index >= 0, index < catalogItems.count else { return false }
        return catalogItems[index].isOutOfStock
    }

    func handleItemSelection(at index: Int) {
        guard index >= 0, index < catalogItems.count else { return }
        let selectedItem = catalogItems[index]

        eventService?.cartItemUserInteraction(
            itemId: selectedItem.catalogItemId,
            action: .DropDownItemSelected,
            context: .CatalogDropDown
        )
    }
}

private extension CatalogItem {
    var isOutOfStock: Bool {
        inventoryStatus?.caseInsensitiveCompare("OutOfStock") == .orderedSame
    }
}
