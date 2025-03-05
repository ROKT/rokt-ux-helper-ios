//
//  ExtensionComponent.swift
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
protocol ExtensionComponent: View {
    associatedtype Model: Codable
    
    static func create(from data: ExtensionData, config: ComponentConfig, layoutState: (any LayoutStateRepresenting)?, eventService: EventDiagnosticServicing?, slot: SlotOfferModel?) -> Self?
    
    var config: ComponentConfig { get }
    var model: Model { get }
    var data: ExtensionData { get }
    var layoutState: (any LayoutStateRepresenting)? { get }
    var eventService: EventDiagnosticServicing? { get }
    var slot: SlotOfferModel? { get }
} 
