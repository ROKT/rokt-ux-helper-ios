//
//  EscapeHatchViewModel.swift
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
class EscapeHatchViewModel: Hashable, Identifiable, ScreenSizeAdaptive {
    
    let id: UUID = UUID()
    var data: String
    weak var layoutState: (any LayoutStateRepresenting)?
    weak var eventService: EventDiagnosticServicing?
    var slot: SlotOfferModel?
    
    // ScreenSizeAdaptive protocol requirements
    var defaultStyle: [Any]?
    var hoveredStyle: [Any]?
    var pressedStyle: [Any]?
    var disabledStyle: [Any]?
    var breakpointIndex: Int = 0
    
    init(data: String, layoutState: (any LayoutStateRepresenting)?, eventService: EventDiagnosticServicing?, slot: SlotOfferModel?) {
        self.data = data
        self.layoutState = layoutState
        self.eventService = eventService
        self.slot = slot
    }
    
    // Hashable conformance
    static func == (lhs: EscapeHatchViewModel, rhs: EscapeHatchViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
