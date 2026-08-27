import Foundation
import Combine
import DcuiSchema

struct CatalogCarouselCallbacks {
    var onMount: (([CatalogItemContext]) -> Void)?
    var onReach: ((CatalogItemContext, Int) -> Void)?
}

@available(iOS 15, *)
struct CatalogCarouselCard: Identifiable {
    struct ID: Hashable {
        let offerIndex: Int
        let itemIndex: Int
    }

    let context: CatalogItemContext
    let layout: LayoutSchemaViewModel
    var id: ID { ID(offerIndex: context.offerIndex, itemIndex: context.itemIndex) }
}

@available(iOS 15, *)
final class CatalogCarouselCollectionViewModel: Identifiable, Hashable, ObservableObject, ScreenSizeAdaptive {
    let id = UUID()
    let cards: [CatalogCarouselCard]
    let defaultStyle: [BaseStyles]?
    let viewableItems: [UInt8]
    let peekThroughSize: [PeekThroughSize]
    weak var layoutState: (any LayoutStateRepresenting)?

    @Published private(set) var currentItemIndex = 0
    @Published private(set) var contentHeight: CGFloat?

    private let callbacks: CatalogCarouselCallbacks
    private var hasMounted = false
    private var scrollTracker = CatalogCarouselScrollTracker()
    private var measuredWidth: CGFloat?
    private var itemHeights: [Int: CGFloat] = [:]

    var imageLoader: RoktUXImageLoader? { layoutState?.imageLoader }

    init(slots: [SlotModel],
         offerIndex: Int,
         viewableItems: [UInt8],
         peekThroughSize: [PeekThroughSize],
         defaultStyle: [BaseStyles]? = nil,
         layoutState: any LayoutStateRepresenting,
         callbacks: CatalogCarouselCallbacks = .init(),
         buildCard: (CatalogItemContext) throws -> LayoutSchemaViewModel) rethrows {
        let count = slots[safe: offerIndex]?.offer?.catalogItems?.count ?? 0
        self.cards = try (0..<count).compactMap { index in
            guard let context = CatalogItemContext(slots: slots, offerIndex: offerIndex, itemIndex: index) else { return nil }
            return CatalogCarouselCard(context: context, layout: try buildCard(context))
        }
        self.viewableItems = viewableItems
        self.peekThroughSize = peekThroughSize
        self.defaultStyle = defaultStyle
        self.layoutState = layoutState
        self.callbacks = callbacks
    }

    func geometry(viewportWidth: CGFloat, breakpointIndex: Int) -> CatalogCarouselGeometry {
        let visible = viewableItems[safe: max(0, min(breakpointIndex, viewableItems.count - 1))] ?? 1
        let peekSize = peekThroughSize[safe: max(0, min(breakpointIndex, peekThroughSize.count - 1))]
        let peek: CGFloat
        switch peekSize {
        case .fixed(let value): peek = CGFloat(value)
        case .percentage(let value): peek = viewportWidth * CGFloat(value)/100
        case nil: peek = 0
        }
        let style = defaultStyle?[safe: max(0, min(breakpointIndex, (defaultStyle?.count ?? 0) - 1))]
        return CatalogCarouselGeometry(viewportWidth: viewportWidth, itemCount: cards.count,
                                       viewableItems: Int(visible), gap: CGFloat(style?.container?.gap ?? 0), peek: peek)
    }

    func mounted() {
        guard !hasMounted, !cards.isEmpty else { return }
        hasMounted = true
        callbacks.onMount?(cards.map(\.context))
    }

    func beginInteraction(offset: CGFloat, geometry: CatalogCarouselGeometry) {
        scrollTracker.beginInteraction(visibleIndexes: geometry.visibleIndexes(at: offset))
    }

    func endInteraction() {
        scrollTracker.endInteraction()
    }

    func layoutChanged(geometry: CatalogCarouselGeometry) {
        if measuredWidth != geometry.itemWidth {
            measuredWidth = geometry.itemWidth
            itemHeights.removeAll()
        }
        scrollTracker.layoutChanged(visibleIndexes: geometry.visibleIndexes(at: geometry.offset(for: currentItemIndex)))
    }

    func scrolled(offset: CGFloat, geometry: CatalogCarouselGeometry) {
        let index = geometry.leadingIndex(at: offset)
        if currentItemIndex != index { currentItemIndex = index }
        for reached in scrollTracker.newlyReachedIndexes(visibleIndexes: geometry.visibleIndexes(at: offset)) {
            guard let card = cards[safe: reached] else { continue }
            callbacks.onReach?(card.context, cards.count - 1)
        }
    }

    func recordHeight(_ height: CGFloat, itemIndex: Int, itemWidth: CGFloat) {
        guard cards.indices.contains(itemIndex), height.isFinite, height >= 0, itemWidth.isFinite, itemWidth > 0 else { return }
        guard measuredWidth == itemWidth else { return }
        itemHeights[itemIndex] = height
        let maximumHeight = itemHeights.values.max() ?? 0
        if itemHeights.count == cards.count || maximumHeight > (contentHeight ?? 0) {
            if contentHeight != maximumHeight { contentHeight = maximumHeight }
        }
    }

    static func == (lhs: CatalogCarouselCollectionViewModel, rhs: CatalogCarouselCollectionViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
