import Foundation
import SwiftUI
import DcuiSchema

private enum PPUCreativeCopyKey {
    static let partnerManagedPurchase = "ppu.partnerManagedPurchase"
    static let partnerPaymentReference = "ppu.partnerPaymentReference"
}

@available(iOS 15, *)
class CatalogResponseButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    // `paymentResult` is reused with the DevicePay flow — both record the outcome
    // of the most recent payment attempt so creative predicates can drive UI
    // transitions uniformly (1 = success, -1 = failure).
    // `paymentProcessing` is the orthogonal in-flight flag (1 = in flight, 0 =
    // idle) so predicates can surface a loading/disabled visual during the
    // window between tap and host finalization.
    private static let paymentResultKey = CustomStateIdentifiable.Keys.paymentResult.rawValue
    private static let paymentProcessingKey = CustomStateIdentifiable.Keys.paymentProcessing.rawValue

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
        // Only literal "true"/"false" opt out. Typos keep the safe default (true).
        return Bool(raw) ?? true
    }

    var partnerPaymentReference: String? {
        offerCreativeCopy?[PPUCreativeCopyKey.partnerPaymentReference]
    }

    private var offerCreativeCopy: [String: String]? {
        (layoutState?.items[LayoutState.fullOfferKey] as? OfferModel)?.creative.copy
    }

    func cartItemInstantPurchase(position: Int?) {
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
            setLayoutVariantCustomState(
                updates: [Self.paymentProcessingKey: 1],
                position: position
            )
            eventService?.cartItemForwardPayment(
                catalogItem: catalogItem,
                partnerPaymentReference: partnerPaymentReference,
                completion: { [weak self] status in
                    self?.handleForwardPaymentCompletion(status: status, position: position)
                }
            )
        }
    }

    private func closeLayout() {
        layoutState?.actionCollection[.close](nil)
    }

    private func handleForwardPaymentCompletion(status: ForwardPaymentStatus, position: Int?) {
        let result: Int
        switch status {
        case .success:
            result = 1
        case .failure:
            result = -1
        }
        setLayoutVariantCustomState(
            updates: [
                Self.paymentProcessingKey: 0,
                Self.paymentResultKey: result
            ],
            position: position
        )
    }

    private func setLayoutVariantCustomState(updates: [String: Int], position: Int?) {
        guard let layoutState,
              let binding = layoutState.items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>
        else { return }

        DispatchQueue.main.async {
            var map = binding.wrappedValue ?? [:]
            for (key, value) in updates {
                map[CustomStateIdentifiable(position: position, key: key)] = value
            }
            binding.wrappedValue = map
            layoutState.publishStateChange()
        }
    }

    private func sendCloseEvent() {
        eventService?.dismissOption = .defaultDismiss
        eventService?.sendDismissalEvent()
    }
}
