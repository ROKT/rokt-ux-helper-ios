//
//  DataImageCarouselViewModel.swift
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

import Foundation
import DcuiSchema

@available(iOS 15, *)
class DataImageCarouselViewModel: Hashable, Identifiable, ObservableObject, ScreenSizeAdaptive {
    let id: UUID = UUID()

    let images: [CreativeImage]?
    let defaultStyle: [DataImageCarouselStyles]?
    let pressedStyle: [DataImageCarouselStyles]?
    let hoveredStyle: [DataImageCarouselStyles]?
    let disabledStyle: [DataImageCarouselStyles]?

    let indicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?
    let seenIndicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?
    let activeIndicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?
    let progressIndicatorContainer: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?

    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(images: [CreativeImage]?,
         ownStyle: [BasicStateStylingBlock<DataImageCarouselStyles>]?,
         indicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?,
         seenIndicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?,
         activeIndicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?,
         progressIndicatorContainer: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?,
         layoutState: (any LayoutStateRepresenting)?) {
        self.images = images
        self.defaultStyle = ownStyle?.compactMap {$0.default}
        self.pressedStyle = ownStyle?.compactMap {$0.pressed}
        self.hoveredStyle = ownStyle?.compactMap {$0.hovered}
        self.disabledStyle = ownStyle?.compactMap {$0.disabled}
        self.indicatorStyle = indicatorStyle
        self.seenIndicatorStyle = seenIndicatorStyle
        self.activeIndicatorStyle = activeIndicatorStyle
        self.progressIndicatorContainer = progressIndicatorContainer
        self.layoutState = layoutState
    }
}
