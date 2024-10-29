//
//  OneByOneUIModel.swift
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
class OneByOneViewModel: DistributionViewModel, Identifiable, ScreenSizeAdaptive {
    
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let defaultStyle: [OneByOneDistributionStyles]?
    let transition: DcuiSchema.Transition?
    var imageLoader: ImageLoader? {
        layoutState.imageLoader
    }

    init(
        children: [LayoutSchemaViewModel]?,
        defaultStyle: [OneByOneDistributionStyles]?,
        transition: DcuiSchema.Transition?,
        eventService: EventServicing?,
        slots: [SlotModel],
        layoutState: any LayoutStateRepresenting
    ) {
        self.children = children
        self.defaultStyle = defaultStyle
        self.transition = transition
        super.init(
            eventService: eventService,
            slots: slots,
            layoutState: layoutState
        )
    }
    
    func setupBindings(
        currentProgess: Binding<Int>,
        customStateMap: Binding<CustomStateMap?>,
        totalItems: Int
    ) {
        layoutState.items[LayoutState.currentProgressKey] = currentProgess
        layoutState.items[LayoutState.customStateMap] = customStateMap
        layoutState.items[LayoutState.totalItemsKey] = totalItems
    }
}
