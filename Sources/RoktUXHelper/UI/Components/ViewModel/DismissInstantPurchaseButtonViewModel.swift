//
//  DismissInstantPurchaseButtonViewModel.swift
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
class DismissInstantPurchaseButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    let children: [LayoutSchemaViewModel]?
    let defaultStyle: [DismissInstantPurchaseButtonStyles]?
    let pressedStyle: [DismissInstantPurchaseButtonStyles]?
    let hoveredStyle: [DismissInstantPurchaseButtonStyles]?
    let disabledStyle: [DismissInstantPurchaseButtonStyles]?
    weak var eventService: EventServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         defaultStyle: [DismissInstantPurchaseButtonStyles]?,
         pressedStyle: [DismissInstantPurchaseButtonStyles]?,
         hoveredStyle: [DismissInstantPurchaseButtonStyles]?,
         disabledStyle: [DismissInstantPurchaseButtonStyles]?,
         layoutState: (any LayoutStateRepresenting)?,
         eventService: EventServicing?) {
        self.children = children
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
        self.eventService = eventService
    }

    func sendDismissInstantPurchaseEvent() {
        eventService?.dismissOption = .instantPurchaseDismiss
        eventService?.sendDismissalEvent()
    }
}
