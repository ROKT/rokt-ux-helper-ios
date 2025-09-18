//
//  BasicTextComponent.swift
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
    var model: TimerStateTriggerViewModel

    init(model: TimerStateTriggerViewModel) {
        self.model = model
    }

    var body: some View {
        EmptyView()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + model.delay) {
                    model.layoutState?.actionCollection[.toggleCustomState](
                        CustomStateIdentifiable(
                            position: model.value,
                            key: model.customStateKey
                        )
                    )
                }
            }
    }
}
