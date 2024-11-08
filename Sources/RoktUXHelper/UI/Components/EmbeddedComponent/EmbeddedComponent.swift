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
    @StateObject var globalScreenSize = GlobalScreenSize()

    @StateObject private var viewModel: EmbeddedComponentViewModel
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?

    init(
        layout: LayoutSchemaViewModel,
        layoutState: LayoutState?,
        eventService: EventServicing?,
        onLoad: (() -> Void)?,
        onSizeChange: ((CGFloat) -> Void)?
    ) {
        self._viewModel = .init(
            wrappedValue: .init(
                layout: layout,
                layoutState: layoutState,
                eventService: eventService,
                onLoad: onLoad,
                onSizeChange: onSizeChange
            )
        )
    }

    var body: some View {
        VStack {
            LayoutSchemaComponent(config: ComponentConfig(parent: .column, position: nil),
                                  layout: viewModel.layout,
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
            viewModel.onLoad()
        }
        .onFirstTouch {
            viewModel.onFirstTouch()
        }
        .onChange(of: colorScheme) { newColor in
            viewModel.updateColorScheme(newColor)
        }
        .environmentObject(globalScreenSize)
    }

    func notifyHeightChanged(_ newHeight: CGFloat) {
        viewModel.updateHeight(newHeight)
    }
}
