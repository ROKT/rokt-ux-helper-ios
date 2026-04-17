import Foundation
import SwiftUI
import DcuiSchema

private enum PPUCreativeCopyKey {
    static let partnerManagedPurchase = "ppu.partnerManagedPurchase"
    static let partnerPaymentReference = "ppu.partnerPaymentReference"
}

@available(iOS 15, *)
class CatalogResponseButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    let catalogItem: CatalogItem?
    var children: [LayoutSchemaViewModel]?
    weak var eventService: EventDiagnosticServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    let defaultStyle: [CatalogResponseButtonStyles]?
    let pressedStyle: [CatalogResponseButtonStyles]?
    let hoveredStyle: [CatalogResponseButtonStyles]?
    let disabledStyle: [CatalogResponseButtonStyles]?

    let customStateKey = CustomStateIdentifiable.Keys.paymentResult.rawValue
    var position: Int?

    init(catalogItem: CatalogItem?,
         children: [LayoutSchemaViewModel]?,
         layoutState: (any LayoutStateRepresenting)?,
         eventService: EventDiagnosticServicing?,
         defaultStyle: [CatalogResponseButtonStyles]?,
         pressedStyle: [CatalogResponseButtonStyles]?,
         hoveredStyle: [CatalogResponseButtonStyles]?,
         disabledStyle: [CatalogResponseButtonStyles]?) {
        self.catalogItem = catalogItem
        self.children = children
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
        self.eventService = eventService
    }

    var isPartnerManagedPurchase: Bool {
        guard let raw = offerCreativeCopy?[PPUCreativeCopyKey.partnerManagedPurchase] else {
            return true
        }
        return (raw as NSString).boolValue
    }

    var partnerPaymentReference: String? {
        offerCreativeCopy?[PPUCreativeCopyKey.partnerPaymentReference]
    }

    private var offerCreativeCopy: [String: String]? {
        (layoutState?.items[LayoutState.fullOfferKey] as? OfferModel)?.creative.copy
    }

    func cartItemInstantPurchase() {
        guard let catalogItem else {
            sendCloseEvent()
            closeLayout()
            return
        }

        if isPartnerManagedPurchase {
            eventService?.cartItemInstantPurchase(catalogItem: catalogItem)
            sendCloseEvent()
            closeLayout()
        } else {
            eventService?.cartItemForwardPayment(
                catalogItem: catalogItem,
                partnerPaymentReference: partnerPaymentReference,
                completion: { [weak self] status in
                    self?.handleForwardPaymentCompletion(status: status)
                }
            )
        }
    }

    private func closeLayout() {
        layoutState?.actionCollection[.close](nil)
    }

    private func handleForwardPaymentCompletion(status: ForwardPaymentStatus) {
        let value: Int
        switch status {
        case .success:
            value = 1
        case .failure:
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

    private func sendCloseEvent() {
        eventService?.dismissOption = .defaultDismiss
        eventService?.sendDismissalEvent()
    }
}
