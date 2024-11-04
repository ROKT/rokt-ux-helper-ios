//
//  BottomSheetUIModel.swift
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
class BottomSheetViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let allowBackdropToClose: Bool?
    let defaultStyle: [BottomSheetStyles]?
    let eventService: EventServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: ImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         allowBackdropToClose: Bool?,
         defaultStyle: [BottomSheetStyles]?,
         eventService: EventServicing?,
         layoutState: (any LayoutStateRepresenting)?) {
        self.children = children
        self.allowBackdropToClose = allowBackdropToClose
        self.defaultStyle = defaultStyle
        self.eventService = eventService
        self.layoutState = layoutState
    }
}
