import Foundation

/// Binds a card's content and responses to the same item and parent slot.
struct CatalogItemContext {
    let slot: SlotModel
    let offer: OfferModel
    let offers: [OfferModel?]
    let catalogItem: CatalogItem
    let offerIndex: Int
    let itemIndex: Int

    var moduleName: String? { slot.layoutVariant?.moduleName }

    init?(slots: [SlotModel], offerIndex: Int, itemIndex: Int) {
        guard slots.indices.contains(offerIndex),
              let offer = slots[offerIndex].offer,
              let catalogItems = offer.catalogItems,
              catalogItems.indices.contains(itemIndex) else { return nil }

        self.slot = slots[offerIndex]
        self.offer = offer
        self.offers = slots.map(\.offer)
        self.catalogItem = catalogItems[itemIndex]
        self.offerIndex = offerIndex
        self.itemIndex = itemIndex
    }

    func responseOption(for responseKey: String? = nil) -> RoktUXResponseOption? {
        let key = responseKey.flatMap { $0.isEmpty ? nil : $0 } ?? "positive"
        return catalogItem.responseOptionsMap?[key]
    }
}
