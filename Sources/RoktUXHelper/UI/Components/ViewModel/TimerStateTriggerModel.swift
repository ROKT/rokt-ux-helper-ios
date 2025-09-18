//
//  OverlayUIModel.swift
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
class TimerStateTriggerViewModel: Identifiable, Hashable {
    var layoutState: (any LayoutStateRepresenting)?

    let id: UUID = UUID()

    let customStateKey: String
    let delay: Double
    let value: Int?

    init(model: TimerStateTriggerModel, layoutState: (any LayoutStateRepresenting)?) {
        customStateKey = model.customStateKey
        delay = Double(model.delay ?? 0)/1000
        value = (model.value == nil ? Int(model.value!) : nil)
        self.layoutState = layoutState
    }
}
