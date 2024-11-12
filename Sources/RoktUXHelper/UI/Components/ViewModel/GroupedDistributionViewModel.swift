//
//  GroupedDistributionUIModel.swift
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
class GroupedDistributionViewModel: DistributionViewModel, Identifiable, ScreenSizeAdaptive {

    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let defaultStyle: [GroupedDistributionStyles]?
    let viewableItems: [UInt8]
    let transition: DcuiSchema.Transition
    var imageLoader: ImageLoader? {
        config?.imageLoader
    }

    init(
        children: [LayoutSchemaViewModel]?,
        defaultStyle: [GroupedDistributionStyles]?,
        viewableItems: [UInt8],
        transition: DcuiSchema.Transition,
        eventService: EventServicing?,
        slots: [SlotModel],
        layoutState: (any LayoutStateRepresenting)?
    ) {
        self.children = children
        self.defaultStyle = defaultStyle
        self.viewableItems = viewableItems
        self.transition = transition
        super.init(eventService: eventService,
                   slots: slots,
                   layoutState: layoutState)
    }

    func sendViewableImpressionEvents(viewableItems: Int, currentLeadingOffer: Int) {
        for offer in currentLeadingOffer..<currentLeadingOffer + viewableItems {
            sendImpressionEvents(currentOffer: offer)
        }
    }

    func setupBindings(
        currentProgress: Binding<Int>,
        totalItems: Int,
        viewableItems: Binding<Int>,
        customStateMap: Binding<CustomStateMap?>
    ) {
        layoutState?.items[LayoutState.currentProgressKey] = currentProgress
        layoutState?.items[LayoutState.totalItemsKey] = totalItems
        layoutState?.items[LayoutState.viewableItemsKey] = viewableItems
        layoutState?.items[LayoutState.customStateMap] = customStateMap
    }

    func getGlobalBreakpointIndex(_ width: CGFloat?) -> Int {
        layoutState?.getGlobalBreakpointIndex(width) ?? 0
    }
}
