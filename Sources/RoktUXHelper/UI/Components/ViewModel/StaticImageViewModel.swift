//
//  ImageUIModel.swift
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
class StaticImageViewModel: Hashable, Identifiable, ScreenSizeAdaptive {

    let id: UUID = UUID()

    let url: StaticImageUrl?
    let alt: String?
    let defaultStyle: [StaticImageStyles]?
    let pressedStyle: [StaticImageStyles]?
    let hoveredStyle: [StaticImageStyles]?
    let disabledStyle: [StaticImageStyles]?
    weak var layoutState: (any LayoutStateRepresenting)?

    var imageLoader: ImageLoader? {
        layoutState?.imageLoader
    }

    init(url: StaticImageUrl?,
         alt: String?,
         defaultStyle: [StaticImageStyles]?,
         pressedStyle: [StaticImageStyles]?,
         hoveredStyle: [StaticImageStyles]?,
         disabledStyle: [StaticImageStyles]?,
         layoutState: (any LayoutStateRepresenting)?) {
        self.url = url
        self.alt = alt

        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
    }
}
