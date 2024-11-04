//
//  DataImageUIModel.swift
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
class DataImageViewModel: Hashable, Identifiable, ObservableObject, ScreenSizeAdaptive {
    let id: UUID = UUID()

    let image: CreativeImage?
    let defaultStyle: [DataImageStyles]?
    let pressedStyle: [DataImageStyles]?
    let hoveredStyle: [DataImageStyles]?
    let disabledStyle: [DataImageStyles]?
    let layoutState: any LayoutStateRepresenting
    var imageLoader: ImageLoader? {
        layoutState.imageLoader
    }

    init(image: CreativeImage?,
         defaultStyle: [DataImageStyles]?,
         pressedStyle: [DataImageStyles]?,
         hoveredStyle: [DataImageStyles]?,
         disabledStyle: [DataImageStyles]?,
         layoutState: any LayoutStateRepresenting) {
        self.image = image
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
    }
}
