//
//  EmbeddedComponent.swift
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

struct EmbeddedComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    let layout: LayoutSchemaViewModel
    let layoutState: LayoutState
    let eventService: EventServicing?
    let config: RoktUXConfig?
    let onLoad: (() -> Void)?
    let onSizeChange: ((CGFloat) -> Void)?

    @State var lastUpdatedHeight: CGFloat = 0
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?

    @StateObject var globalScreenSize = GlobalScreenSize()

    var body: some View {
        VStack {
            LayoutSchemaComponent(config: ComponentConfig(parent: .column, position: nil),
                                  layout: layout,
                                  parentWidth: $availableWidth,
                                  parentHeight: $availableHeight,
                                  styleState: .constant(.default))
        }
        .frame(maxWidth: .infinity)
        .readSize { size in
            availableWidth = size.width
            availableHeight = size.height

            notifyHeightChanged(size.height)
            // 0 at the start
            globalScreenSize.width = size.width
            globalScreenSize.height = size.height
        }
        .onLoad {
            eventService?.sendEventsOnLoad()
            onLoad?()
            layoutState.actionCollection[.checkBoundingBox](nil)
        }
        .onFirstTouch {
            eventService?.sendSignalActivationEvent()
        }
        .onChange(of: colorScheme) { newColor in
            DispatchQueue.main.async {
                AttributedStringTransformer
                    .convertRichTextHTMLIfExists(uiModel: layout,
                                                 config: config,
                                                 colorScheme: newColor)
            }
        }
        .environmentObject(globalScreenSize)
    }

    func notifyHeightChanged(_ newHeight: CGFloat) {
        if lastUpdatedHeight != newHeight {
            onSizeChange?(newHeight)
            lastUpdatedHeight = newHeight
        }
    }
}
