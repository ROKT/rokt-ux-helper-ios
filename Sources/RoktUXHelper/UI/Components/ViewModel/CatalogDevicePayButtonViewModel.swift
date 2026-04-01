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
        self.customStateKey = customStateKey
    }

    func handleTap() {
        guard let catalogItem else { return }
        eventService?.cartItemDevicePay(
            catalogItem: catalogItem,
            paymentProvider: provider,
            completion: { [weak self] status in
                guard let self else { return }
                self.handleDevicePayCompletion(status: status)
            }
        )
    }

    private func handleDevicePayCompletion(status: DevicePayStatus) {
        guard let customStateKey, !customStateKey.isEmpty else {
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
        guard let layoutState,
              let binding = layoutState.items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>
        else { return }

        let identifier = CustomStateIdentifiable(position: position, key: key)

        DispatchQueue.main.async {
            var map = binding.wrappedValue ?? [:]
            map[identifier] = value
            binding.wrappedValue = map
            layoutState.publishStateChange()
        }
    }

    static func == (lhs: CatalogDevicePayButtonViewModel, rhs: CatalogDevicePayButtonViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
