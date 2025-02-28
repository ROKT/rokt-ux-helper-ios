//
//  DataImageCarouselComponent.swift
//  RoktUXHelper
//
//  Copyright 2020 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import Combine
import DcuiSchema

@available(iOS 15, *)
struct DataImageCarouselComponent: View {
    let config: ComponentConfig
    let model: DataImageCarouselViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState

    let parentOverride: ComponentParentOverride?

    var body: some View {
        EmptyView()
    }
}
