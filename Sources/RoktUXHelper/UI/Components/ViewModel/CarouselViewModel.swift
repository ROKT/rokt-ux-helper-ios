//
//  CarouselUIModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import SwiftUI
import DcuiSchema

@available(iOS 15, *)
class CarouselViewModel: DistributionViewModel, Identifiable {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let defaultStyle: [CarouselDistributionStyles]?
    let viewableItems: [UInt8]
    let peekThroughSize: [PeekThroughSize]
    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         defaultStyle: [CarouselDistributionStyles]?,
         viewableItems: [UInt8],
         peekThroughSize: [PeekThroughSize],
         eventService: EventServicing?,
         slots: [SlotModel],
         layoutState: any LayoutStateRepresenting) {
        self.children = children
        self.defaultStyle = defaultStyle
        self.viewableItems = viewableItems
        self.peekThroughSize = peekThroughSize
        super.init(eventService: eventService, slots: slots, layoutState: layoutState)
    }

    func sendViewableImpressionEvents(viewableItems: Int, currentLeadingOffer: Int) {
        for offer in currentLeadingOffer..<currentLeadingOffer + viewableItems {
            sendImpressionEvents(currentOffer: offer)
        }
    }

    func getGlobalBreakpointIndex(_ width: CGFloat?) -> Int {
        layoutState?.getGlobalBreakpointIndex(width) ?? 0
    }

    func setupBindings(
        currentProgress: Binding<Int>,
        totalItems: Int,
        viewableItems: Binding<Int>,
        customStateMap: Binding<RoktUXCustomStateMap?>
    ) {
        layoutState?.items[LayoutState.currentProgressKey] = currentProgress
        layoutState?.items[LayoutState.totalItemsKey] = totalItems
        layoutState?.items[LayoutState.viewableItemsKey] = viewableItems
        layoutState?.items[LayoutState.customStateMap] = customStateMap
    }
}
