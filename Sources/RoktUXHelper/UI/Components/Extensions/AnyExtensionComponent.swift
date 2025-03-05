//
//  AnyExtensionComponent.swift
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
class AnyExtensionComponentFactory {
    static func create<C: ExtensionComponent>(
        _ componentType: C.Type,
        config: ComponentConfig,
        model: C.Model,
        data: ExtensionData,
        layoutState: (any LayoutStateRepresenting)?,
        eventService: EventDiagnosticServicing?,
        slot: SlotOfferModel?
    ) -> AnyExtensionComponent? {
        componentType.create(from: data, config: config, layoutState: layoutState, eventService: eventService, slot: slot).map { AnyExtensionComponent($0) }
    }
}

@available(iOS 15, *)
struct AnyExtensionComponent: View {
    private let wrapped: AnyView
    
    init<C: ExtensionComponent>(_ component: C) {
        self.wrapped = AnyView(component)
    }
    
    var body: some View {
        wrapped
    }
} 
