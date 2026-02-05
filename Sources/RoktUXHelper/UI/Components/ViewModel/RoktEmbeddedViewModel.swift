//
//  RoktEmbeddedComponentViewModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI

@available(iOS 15, *)
class RoktEmbeddedViewModel {
    let layouts: [LayoutSchemaViewModel]?
    weak var eventService: EventServicing?
    weak var layoutState: (any LayoutStateRepresenting)?

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    var config: RoktUXConfig? {
        layoutState?.config
    }

    init(layouts: [LayoutSchemaViewModel]?,
         eventService: EventServicing?,
         layoutState: (any LayoutStateRepresenting)?) {
        self.layouts = layouts
        self.eventService = eventService
        self.layoutState = layoutState
    }

    func sendOnLoadEvents() {
        RoktUXLogger.shared.debug("View loaded")
        eventService?.sendEventsOnLoad()
    }

    func sendSignalActivationEvent() {
        eventService?.sendSignalActivationEvent()
    }

    func updateAttributedStrings(_ newColor: ColorScheme) {
        DispatchQueue.main.async { [config, layouts] in
            if let layouts = layouts {
                layouts.forEach { layout in
                    AttributedStringTransformer.convertRichTextHTMLIfExists(
                        uiModel: layout,
                        config: config,
                        colorScheme: newColor
                    )
                }
            }
        }
    }
}
