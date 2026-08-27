import Combine
import SwiftUI

@available(iOS 15, *)
final class CatalogProductResponseViewModel {
    let context: CatalogItemContext
    let responseKey: String?
    weak var eventService: EventDiagnosticServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    private let progression: CatalogProductProgression

    init(context: CatalogItemContext,
         responseKey: String? = nil,
         eventService: EventDiagnosticServicing?,
         layoutState: (any LayoutStateRepresenting)?) {
        self.context = context
        self.responseKey = responseKey
        self.eventService = eventService
        self.layoutState = layoutState
        self.progression = CatalogProductProgression.shared(in: layoutState)
    }

    func handleResponse() {
        guard isCurrentOffer,
              let response = CatalogProductResponse(context: context, responseKey: responseKey),
              let eventService else { return }

        let generation = progression.generation
        eventService.sendCatalogProductResponse(response)
        var completed = false
        eventService.openURL(
            url: response.url,
            type: response.openURLType(sessionId: (eventService as? EventService)?.sessionId)
        ) { [weak self] in
            guard !completed else { return }
            completed = true
            guard let self, self.isCurrentOffer else { return }
            self.progression.complete(offerIndex: self.context.offerIndex, generation: generation)
        }
    }

    private var isCurrentOffer: Bool {
        progression.isVisible(offerIndex: context.offerIndex)
    }
}

@available(iOS 15, *)
private final class CatalogProductProgression {
    private weak var layoutState: (any LayoutStateRepresenting)?
    private var visibleOfferIndexes: [Int]?
    private var pendingOfferIndex: Int?
    private var subscription: AnyCancellable?
    private(set) var generation = 0

    private init(layoutState: (any LayoutStateRepresenting)?) {
        self.layoutState = layoutState
        self.visibleOfferIndexes = Self.offerIndexes(in: layoutState?.items ?? [:])
        subscription = layoutState?.itemsPublisher.sink { [weak self] items in
            guard let self, let indexes = Self.offerIndexes(in: items), self.visibleOfferIndexes != indexes else { return }
            self.visibleOfferIndexes = indexes
            self.pendingOfferIndex = nil
            self.generation += 1
        }
    }

    func isVisible(offerIndex: Int) -> Bool {
        Self.offerIndexes(in: layoutState?.items ?? [:])?.contains(offerIndex) ?? true
    }

    private static func offerIndexes(in items: [String: Any]) -> [Int]? {
        if let indexes = items[LayoutState.visibleOfferIndexesKey] as? [Int] { return indexes }
        let viewableItems = (items[LayoutState.viewableItemsKey] as? Binding<Int>)?.wrappedValue
            ?? items[LayoutState.viewableItemsKey] as? Int ?? 1
        guard viewableItems == 1,
              let progress = items[LayoutState.currentProgressKey] as? Binding<Int> else { return nil }
        return [progress.wrappedValue]
    }

    static func shared(in layoutState: (any LayoutStateRepresenting)?) -> CatalogProductProgression {
        if let existing = layoutState?.items[LayoutState.catalogProductProgressionKey] as? CatalogProductProgression {
            return existing
        }
        let progression = CatalogProductProgression(layoutState: layoutState)
        layoutState?.items[LayoutState.catalogProductProgressionKey] = progression
        return progression
    }

    func complete(offerIndex: Int, generation: Int) {
        guard self.generation == generation, pendingOfferIndex != offerIndex else { return }
        // A fade-out delays the actual index change, so all cards share this pending guard.
        pendingOfferIndex = offerIndex
        layoutState?.actionCollection[.nextOffer](nil)
    }
}
