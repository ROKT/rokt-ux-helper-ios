//
//  CatalogResponseButtonViewModel.swift
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
class CatalogResponseButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    weak var eventService: EventDiagnosticServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: ImageLoader? {
        layoutState?.imageLoader
    }

    let defaultStyle: [CatalogResponseButtonStyles]?
    let pressedStyle: [CatalogResponseButtonStyles]?
    let hoveredStyle: [CatalogResponseButtonStyles]?
    let disabledStyle: [CatalogResponseButtonStyles]?

    init(children: [LayoutSchemaViewModel]?,
         layoutState: (any LayoutStateRepresenting)?,
         eventService: EventDiagnosticServicing?,
         defaultStyle: [CatalogResponseButtonStyles]?,
         pressedStyle: [CatalogResponseButtonStyles]?,
         hoveredStyle: [CatalogResponseButtonStyles]?,
         disabledStyle: [CatalogResponseButtonStyles]?) {
        self.children = children
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
        self.eventService = eventService
    }
}
