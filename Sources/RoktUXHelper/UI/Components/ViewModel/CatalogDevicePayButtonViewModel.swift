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
        eventService?.cartItemInstantPurchase(catalogItem: catalogItem)
    }

    static func == (lhs: CatalogDevicePayButtonViewModel, rhs: CatalogDevicePayButtonViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
