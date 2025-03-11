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
class StaticImageViewModel: Hashable, Identifiable, BaseStyleAdaptive {

    let id: UUID = UUID()

    let url: StaticImageUrl?
    let alt: String?
    let stylingProperties: [BasicStateStylingBlock<BaseStyles>]?

    weak var layoutState: (any LayoutStateRepresenting)?

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(url: StaticImageUrl?,
         alt: String?,
         stylingProperties: [BasicStateStylingBlock<BaseStyles>]?,
         layoutState: (any LayoutStateRepresenting)?) {
        self.url = url
        self.alt = alt

        self.stylingProperties = stylingProperties
        self.layoutState = layoutState
    }
}
