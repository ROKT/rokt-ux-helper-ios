//
//  RowUIModel.swift
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
class RowViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let defaultStyle: [RowStyle]?
    let pressedStyle: [RowStyle]?
    let hoveredStyle: [RowStyle]?
    let disabledStyle: [RowStyle]?
    let accessibilityGrouped: Bool
    let layoutState: any LayoutStateRepresenting
    var imageLoader: ImageLoader? {
        layoutState.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         defaultStyle: [RowStyle]?,
         pressedStyle: [RowStyle]?,
         hoveredStyle: [RowStyle]?,
         disabledStyle: [RowStyle]?,
         accessibilityGrouped: Bool,
         layoutState: any LayoutStateRepresenting) {
        self.children = children
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.accessibilityGrouped = accessibilityGrouped
        self.layoutState = layoutState
    }
}
