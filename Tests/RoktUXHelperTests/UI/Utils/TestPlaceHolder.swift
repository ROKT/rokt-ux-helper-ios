//
//  TestPlaceHolder.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15.0, *)
struct TestPlaceHolder: View {
    let layout: LayoutSchemaViewModel
    var layoutState: LayoutState

    init(layout: LayoutSchemaViewModel, layoutSettings: LayoutSettings? = nil) {
        self.layout = layout
        self.layoutState = LayoutState()
        layoutState.items[LayoutState.layoutSettingsKey] = layoutSettings
        expandLayoutAndInjectState(layout)
    }

    private func expandLayoutAndInjectState(_ layout: LayoutSchemaViewModel) {
        var children: [LayoutSchemaViewModel]?
        switch layout {
        case let .basicText(viewModel):
            viewModel.layoutState = layoutState
        case let .richText(viewModel):
            viewModel.layoutState = layoutState
        case let .staticImage(viewModel):
            viewModel.layoutState = layoutState
        case let .dataImage(viewModel):
            viewModel.layoutState = layoutState
        case let .progressIndicator(viewModel):
            viewModel.layoutState = layoutState
        case let .overlay(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .bottomSheet(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .row(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .column(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .zStack(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .scrollableRow(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .scrollableColumn(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .when(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .oneByOne(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .carousel(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .groupDistribution(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .creativeResponse(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .closeButton(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .staticLink(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .progressControl(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case let .toggleButton(viewModel):
            viewModel.layoutState = layoutState
            children = viewModel.children
        case .empty:
            break
        }
        children?.forEach(expandLayoutAndInjectState(_:))
    }

    var body: some View {
        EmbeddedComponent(layout: layout, layoutState: layoutState, eventService: nil, onLoad: nil, onSizeChange: nil)
    }
}
