//
//  StaticLinkUIModel.swift
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
class StaticLinkViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    
    private let src: String
    private let open: LinkOpenTarget
    private let eventService: EventDiagnosticServicing?
    private(set) var children: [LayoutSchemaViewModel]?
    let id: UUID = UUID()
    let defaultStyle: [StaticLinkStyles]?
    let pressedStyle: [StaticLinkStyles]?
    let hoveredStyle: [StaticLinkStyles]?
    let disabledStyle: [StaticLinkStyles]?
    let layoutState: any LayoutStateRepresenting
    var imageLoader: ImageLoader? {
        layoutState.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         src: String,
         open: LinkOpenTarget,
         defaultStyle: [StaticLinkStyles]?,
         pressedStyle: [StaticLinkStyles]?,
         hoveredStyle: [StaticLinkStyles]?,
         disabledStyle: [StaticLinkStyles]?,
         layoutState: any LayoutStateRepresenting,
         eventService: EventDiagnosticServicing?) {
        self.children = children
        self.src = src
        self.open = open
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
        self.eventService = eventService
    }

    func handleLink() {
        guard let url = URL(string: src) else {
            eventService?.sendDiagnostics(message: kUrlErrorCode,
                                          callStack: src)
            return
        }
        eventService?.openURL(url: url, type: .init(open), completionHandler: {})
    }
}
