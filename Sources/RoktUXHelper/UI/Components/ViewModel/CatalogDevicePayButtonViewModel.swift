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
import SwiftUI

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
    let validatorTriggerConfig: ValidationTriggerConfig?
    let customStateKey: String?
    var position: Int?

    init(
        catalogItem: CatalogItem?,
        children: [LayoutSchemaViewModel]?,
        provider: PaymentProvider,
        layoutState: (any LayoutStateRepresenting)?,
        eventService: EventDiagnosticServicing?,
        defaultStyle: [CatalogDevicePayButtonStyles]?,
        pressedStyle: [CatalogDevicePayButtonStyles]?,
        hoveredStyle: [CatalogDevicePayButtonStyles]?,
        disabledStyle: [CatalogDevicePayButtonStyles]?,
        validatorTriggerConfig: ValidationTriggerConfig?,
        customStateKey: String?
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
        self.validatorTriggerConfig = validatorTriggerConfig
        self.customStateKey = customStateKey
    }

    func cartItemDevicePay() {
        if let catalogItem {
            eventService?.cartItemDevicePay(
                catalogItem: catalogItem,
                paymentProvider: provider,
                completion: { [weak self] status in
                    guard let self else { return }
                    self.handleDevicePayCompletion(status: status)
                }
            )
        }
    }

    func handleTap() {
        guard shouldProceedAfterValidation() else {
            if let catalogItem {
                eventService?.cartItemUserInteraction(
                    itemId: catalogItem.catalogItemId,
                    action: UserInteraction.ValidationTriggerFailed,
                    context: UserInteractionContext.CustomStateValidationTriggerButton
                )
            }
            return
        }
        cartItemDevicePay()
    }

    private func shouldProceedAfterValidation() -> Bool {
        guard let triggerConfig = validatorTriggerConfig,
              !triggerConfig.validatorFieldKeys.isEmpty,
              let coordinator = layoutState?.validationCoordinator else {
            return true
        }
        return coordinator.validate(fields: triggerConfig.validatorFieldKeys)
    }

    private func handleDevicePayCompletion(status: DevicePayStatus) {
        guard let customStateKey = customStateKey, !customStateKey.isEmpty else {
            layoutState?.actionCollection[.close](nil)
            return
        }

        let value: Int
        switch status {
        case .success:
            value = 1
        case .failure, .retry:
            value = -1
        }

        setLayoutVariantCustomState(key: customStateKey, value: value)
    }

    private func setLayoutVariantCustomState(key: String, value: Int) {
        guard
            let layoutState,
            let binding = layoutState.items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>
        else {
            return
        }

        let identifier = CustomStateIdentifiable(position: position, key: key)

        DispatchQueue.main.async {
            var map = binding.wrappedValue ?? [:]
            map[identifier] = value
            binding.wrappedValue = map
            layoutState.publishStateChange()
        }
    }
}
