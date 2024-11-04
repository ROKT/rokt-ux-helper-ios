//
//  CloseButtonUIModel.swift
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
class CloseButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    let children: [LayoutSchemaViewModel]?
    let defaultStyle: [CloseButtonStyles]?
    let pressedStyle: [CloseButtonStyles]?
    let hoveredStyle: [CloseButtonStyles]?
    let disabledStyle: [CloseButtonStyles]?
    let eventService: EventServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: ImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         defaultStyle: [CloseButtonStyles]?,
         pressedStyle: [CloseButtonStyles]?,
         hoveredStyle: [CloseButtonStyles]?,
         disabledStyle: [CloseButtonStyles]?,
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

    func sendCloseEvent() {
        eventService?.dismissOption = .closeButton
        eventService?.sendDismissalEvent()
    }
}
