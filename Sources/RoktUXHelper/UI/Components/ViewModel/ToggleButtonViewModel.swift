//
//  ToggleButtonUIModel.swift
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
class ToggleButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let customStateKey: String
    let defaultStyle: [ToggleButtonStateTriggerStyle]?
    let pressedStyle: [ToggleButtonStateTriggerStyle]?
    let hoveredStyle: [ToggleButtonStateTriggerStyle]?
    let disabledStyle: [ToggleButtonStateTriggerStyle]?
    let layoutState: any LayoutStateRepresenting
    var imageLoader: ImageLoader? {
        layoutState.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         customStateKey: String,
         defaultStyle: [ToggleButtonStateTriggerStyle]?,
         pressedStyle: [ToggleButtonStateTriggerStyle]?,
         hoveredStyle: [ToggleButtonStateTriggerStyle]?,
         disabledStyle: [ToggleButtonStateTriggerStyle]?,
         layoutState: any LayoutStateRepresenting) {
        self.children = children
        self.customStateKey = customStateKey
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
    }
}
