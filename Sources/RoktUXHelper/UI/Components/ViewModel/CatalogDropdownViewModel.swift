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
    let hoveredStyle: [CatalogDropdownStyles]?
    let disabledStyle: [CatalogDropdownStyles]?
    let dropDownListItemDefaultStyle: [CatalogDropdownStyles]?
    let dropDownListItemPressedStyle: [CatalogDropdownStyles]?
    let dropDownListItemHoveredStyle: [CatalogDropdownStyles]?
    let dropDownListItemDisabledStyle: [CatalogDropdownStyles]?
    let dropDownSelectedItemDefaultStyle: [CatalogDropdownStyles]?
    let dropDownSelectedItemPressedStyle: [CatalogDropdownStyles]?
    let dropDownSelectedItemHoveredStyle: [CatalogDropdownStyles]?
    let dropDownSelectedItemDisabledStyle: [CatalogDropdownStyles]?
    let dropDownListContainerDefaultStyle: [CatalogDropdownStyles]?
    let dropDownListContainerPressedStyle: [CatalogDropdownStyles]?
    let dropDownListContainerHoveredStyle: [CatalogDropdownStyles]?
    let dropDownListContainerDisabledStyle: [CatalogDropdownStyles]?
    weak var layoutState: (any LayoutStateRepresenting)?
    weak var eventService: EventDiagnosticServicing?
    let a11yLabel: String?
    let openDropdownChildren: [LayoutSchemaViewModel]
    let closedTemplate: LayoutSchemaViewModel?
    let closedDefaultTemplate: LayoutSchemaViewModel?
    let requiredSelectionErrorTemplate: LayoutSchemaViewModel?

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
         hoveredStyle: [CatalogDropdownStyles]?,
         disabledStyle: [CatalogDropdownStyles]?,
         dropDownListItemDefaultStyle: [CatalogDropdownStyles]?,
         dropDownListItemPressedStyle: [CatalogDropdownStyles]?,
         dropDownListItemHoveredStyle: [CatalogDropdownStyles]?,
         dropDownListItemDisabledStyle: [CatalogDropdownStyles]?,
         dropDownSelectedItemDefaultStyle: [CatalogDropdownStyles]?,
         dropDownSelectedItemPressedStyle: [CatalogDropdownStyles]?,
         dropDownSelectedItemHoveredStyle: [CatalogDropdownStyles]?,
         dropDownSelectedItemDisabledStyle: [CatalogDropdownStyles]?,
         dropDownListContainerDefaultStyle: [CatalogDropdownStyles]?,
         dropDownListContainerPressedStyle: [CatalogDropdownStyles]?,
         dropDownListContainerHoveredStyle: [CatalogDropdownStyles]?,
         dropDownListContainerDisabledStyle: [CatalogDropdownStyles]?,
         a11yLabel: String?,
         openDropdownChildren: [LayoutSchemaViewModel],
         closedTemplate: LayoutSchemaViewModel?,
         closedDefaultTemplate: LayoutSchemaViewModel?,
         requiredSelectionErrorTemplate: LayoutSchemaViewModel?,
         eventService: EventDiagnosticServicing?) {
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.dropDownListItemDefaultStyle = dropDownListItemDefaultStyle
        self.dropDownListItemPressedStyle = dropDownListItemPressedStyle
        self.dropDownListItemHoveredStyle = dropDownListItemHoveredStyle
        self.dropDownListItemDisabledStyle = dropDownListItemDisabledStyle
        self.dropDownSelectedItemDefaultStyle = dropDownSelectedItemDefaultStyle
        self.dropDownSelectedItemPressedStyle = dropDownSelectedItemPressedStyle
        self.dropDownSelectedItemHoveredStyle = dropDownSelectedItemHoveredStyle
        self.dropDownSelectedItemDisabledStyle = dropDownSelectedItemDisabledStyle
        self.dropDownListContainerDefaultStyle = dropDownListContainerDefaultStyle
        self.dropDownListContainerPressedStyle = dropDownListContainerPressedStyle
        self.dropDownListContainerHoveredStyle = dropDownListContainerHoveredStyle
        self.dropDownListContainerDisabledStyle = dropDownListContainerDisabledStyle
        self.layoutState = layoutState
        self.eventService = eventService
        self.a11yLabel = a11yLabel
        self.openDropdownChildren = openDropdownChildren
        self.closedTemplate = closedTemplate
        self.closedDefaultTemplate = closedDefaultTemplate
        self.requiredSelectionErrorTemplate = requiredSelectionErrorTemplate
    }
}
