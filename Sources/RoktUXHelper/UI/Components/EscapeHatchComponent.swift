//
//  EscapeHatchComponent.swift
//  RoktUXHelper
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
struct EscapeHatchComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    let config: ComponentConfig
    let model: EscapeHatchViewModel

    private let escapeHatchExtensionComponents: [String: (ExtensionData, ComponentConfig, (any LayoutStateRepresenting)?, EventDiagnosticServicing?, SlotOfferModel?) -> AnyExtensionComponent?] = [
        // Register extension components here
    ]
    
    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?
    @State var styleState: StyleState = .default
    @State var frameChangeIndex: Int = 0

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex: Int = 0
    
    let parentOverride: ComponentParentOverride?


    init(
        config: ComponentConfig,
        model: EscapeHatchViewModel,
        parentWidth: Binding<CGFloat?>,
        parentHeight: Binding<CGFloat?>,
        parentOverride: ComponentParentOverride? = nil
    ) {
        self.config = config
        self.model = model
        self._parentWidth = parentWidth
        self._parentHeight = parentHeight
        self.parentOverride = parentOverride
    }
    
    private func createExtensionComponent(name: String, data: ExtensionData) -> AnyExtensionComponent? {
        escapeHatchExtensionComponents[name]?(data, config, model.layoutState, model.eventService, model.slot)
    }
    
    var body: some View {
        if let extensionData = try? JSONDecoder().decode(ExtensionData.self, from: model.data.data(using: .utf8) ?? Data()),
           let extensionComponent = createExtensionComponent(name: extensionData.name, data: extensionData) {
            extensionComponent
        } else {
            // TODO: error reporting
            EmptyView()
        }
    }
}
