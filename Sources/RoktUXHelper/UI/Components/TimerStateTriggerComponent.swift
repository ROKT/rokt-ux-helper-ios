//
//  TimerStateTriggerComponent.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import DcuiSchema

@available(iOS 15, *)
struct TimerStateTriggerComponent: View {
    let config: ComponentConfig
    let model: TimerStateTriggerViewModel

    init(config: ComponentConfig, model: TimerStateTriggerViewModel) {
        self.config = config
        self.model = model
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                model.triggerEvent(for: config.position)
            }
    }
}
