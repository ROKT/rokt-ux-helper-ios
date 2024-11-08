//
//  EmbeddedComponentViewModel.swift
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
class EmbeddedComponentViewModel: ObservableObject {
    let layout: LayoutSchemaViewModel
    private let layoutState: LayoutState?
    private let eventService: EventServicing?
    private var onLoadCallback: (() -> Void)?
    private var onSizeChange: ((CGFloat) -> Void)?
    private var lastUpdatedHeight: CGFloat = 0

    init(
        layout: LayoutSchemaViewModel,
        layoutState: LayoutState?,
        eventService: EventServicing?,
        onLoad: (() -> Void)?, onSizeChange: ((CGFloat) -> Void)?
    ) {
        self.layout = layout
        self.layoutState = layoutState
        self.eventService = eventService
        self.onLoadCallback = onLoad
        self.onSizeChange = onSizeChange
    }

    func onLoad() {
        eventService?.sendEventsOnLoad()
        onLoadCallback?()
        layoutState?.actionCollection[.checkBoundingBox](nil)
    }

    func onFirstTouch() {
        eventService?.sendSignalActivationEvent()
    }

    func updateColorScheme(_ newColor: ColorScheme) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            AttributedStringTransformer.convertRichTextHTMLIfExists(
                uiModel: layout,
                config: layoutState?.config,
                colorScheme: newColor
            )
        }
    }

    func updateHeight(_ newHeight: CGFloat) {
        if lastUpdatedHeight != newHeight {
            onSizeChange?(newHeight)
            lastUpdatedHeight = newHeight
        }
    }
}
