//
//  ColumnUIModel.swift
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
class ColumnViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let defaultStyle: [ColumnStyle]?
    let pressedStyle: [ColumnStyle]?
    let hoveredStyle: [ColumnStyle]?
    let disabledStyle: [ColumnStyle]?
    let accessibilityGrouped: Bool
    weak var layoutState: (any LayoutStateRepresenting)?

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         defaultStyle: [ColumnStyle]?,
         pressedStyle: [ColumnStyle]?,
         hoveredStyle: [ColumnStyle]?,
         disabledStyle: [ColumnStyle]?,
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
