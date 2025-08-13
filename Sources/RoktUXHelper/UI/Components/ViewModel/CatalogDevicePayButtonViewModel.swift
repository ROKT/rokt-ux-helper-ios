//
//  CatalogDevicePayButtonViewModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import DcuiSchema
import Foundation

@available(iOS 15, *)
class CatalogDevicePayButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    let catalogItem: CatalogItem?
    var children: [LayoutSchemaViewModel]?
    var provider: PaymentProvider
    weak var eventService: EventDiagnosticServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    let defaultStyle: [CatalogDevicePayButtonStyles]?
    let pressedStyle: [CatalogDevicePayButtonStyles]?
    let hoveredStyle: [CatalogDevicePayButtonStyles]?
    let disabledStyle: [CatalogDevicePayButtonStyles]?

    init(
        catalogItem: CatalogItem?,
        children: [LayoutSchemaViewModel]?,
        provider: PaymentProvider,
        layoutState: (any LayoutStateRepresenting)?,
        eventService: EventDiagnosticServicing?,
        defaultStyle: [CatalogDevicePayButtonStyles]?,
        pressedStyle: [CatalogDevicePayButtonStyles]?,
        hoveredStyle: [CatalogDevicePayButtonStyles]?,
        disabledStyle: [CatalogDevicePayButtonStyles]?
    ) {
        self.catalogItem = catalogItem
        self.children = children
        self.provider = provider
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
        self.eventService = eventService
    }

    func cartItemDevicePay() {
        print("before cartItemDevicePay in view model")
        if let catalogItem {
            print("before provider switch in view model")
            switch provider {
            case .stripe:
                print("before cartItemStripePay in view model")
                eventService?.cartItemStripePay(catalogItem: catalogItem)
            default:
                break
            }
        }
    }
}
