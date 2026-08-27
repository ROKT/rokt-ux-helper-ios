import Foundation

extension CatalogCarouselCallbacks {
    init(eventService: EventDiagnosticServicing?) {
        self.init(onMount: { [weak eventService] contexts in
            for context in contexts { eventService?.sendCatalogItemImpression(context: context) }
        }, onReach: { [weak eventService] context, lastCardIndex in
            eventService?.sendCatalogCarouselScroll(context: context, lastCardIndex: lastCardIndex)
        })
    }
}
