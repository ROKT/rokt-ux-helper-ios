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
        delay = Double(model.delay ?? 0.0)/1000.0
        value = Int(model.value ?? 0.0)
        self.layoutState = layoutState
    }

    func triggerEvent(for position: Int?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.sendEvent(for: position)
        }
    }

    func sendEvent(for position: Int?) {
        layoutState?.actionCollection[.triggerTimer](
            TimerEvent(position: position, value: value, key: customStateKey)
        )
    }
}
