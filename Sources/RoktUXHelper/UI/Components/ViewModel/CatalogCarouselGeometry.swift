import Foundation

struct CatalogCarouselGeometry: Equatable {
    let viewportWidth: CGFloat
    let itemCount: Int
    let viewableItems: Int
    let gap: CGFloat
    let peek: CGFloat
    let itemWidth: CGFloat

    init(viewportWidth: CGFloat, itemCount: Int, viewableItems: Int, gap: CGFloat, peek: CGFloat) {
        let width = viewportWidth.isFinite ? max(0, viewportWidth) : 0
        let count = max(0, itemCount)
        let visible = min(max(1, viewableItems), max(1, count))
        let hasPeek = count > visible && peek.isFinite && peek > 0
        let gaps = hasPeek ? visible + 1 : visible - 1
        let maximumGap = gaps > 0 ? max(0, (width - CGFloat(visible))/CGFloat(gaps)) : width
        let safeGap = min(gap.isFinite ? max(0, gap) : 0, maximumGap)
        let availableWidth = max(0, width - CGFloat(gaps) * safeGap)
        let safePeek = hasPeek ? min(peek, max(0, (availableWidth - CGFloat(visible))/2)) : 0

        self.viewportWidth = width
        self.itemCount = count
        self.viewableItems = visible
        self.gap = safeGap
        self.peek = safePeek
        self.itemWidth = count > 0 ? max(0, (availableWidth - 2 * safePeek)/CGFloat(visible)) : 0
    }

    var stride: CGFloat { itemWidth + gap }
    var contentWidth: CGFloat { CGFloat(itemCount) * itemWidth + CGFloat(max(0, itemCount - 1)) * gap }
    var maximumOffset: CGFloat { max(0, contentWidth - viewportWidth) }

    static func isHorizontalDrag(velocity: CGPoint) -> Bool {
        velocity.x.isFinite && velocity.y.isFinite && abs(velocity.x) > abs(velocity.y)
    }

    func clampedOffset(_ offset: CGFloat) -> CGFloat {
        min(max(0, offset.isFinite ? offset : 0), maximumOffset)
    }

    func offset(for itemIndex: Int) -> CGFloat {
        clampedOffset(CGFloat(max(0, itemIndex)) * stride - (peek > 0 ? peek + gap : 0))
    }

    func leadingIndex(at offset: CGFloat) -> Int {
        guard itemCount > 0, stride > 0 else { return 0 }
        let adjustedOffset = clampedOffset(offset) + (peek > 0 ? peek + gap : 0)
        return min(max(0, Int((adjustedOffset/stride).rounded())), itemCount - viewableItems)
    }

    func snappedOffset(proposedOffset: CGFloat) -> CGFloat {
        offset(for: leadingIndex(at: proposedOffset))
    }

    func visibleIndexes(at offset: CGFloat, threshold: CGFloat = 0.6) -> [Int] {
        guard itemWidth > 0, viewportWidth > 0 else { return [] }
        let start = clampedOffset(offset)
        let end = start + viewportWidth
        return (0..<itemCount).filter { index in
            let itemStart = CGFloat(index) * stride
            let overlap = max(0, min(end, itemStart + itemWidth) - max(start, itemStart))
            return overlap/itemWidth >= threshold
        }
    }
}

struct CatalogCarouselScrollTracker {
    private(set) var highestReachedIndex: Int?
    private(set) var isInteracting = false

    mutating func beginInteraction(visibleIndexes: [Int]) {
        if highestReachedIndex == nil { highestReachedIndex = visibleIndexes.max() ?? -1 }
        isInteracting = true
    }

    mutating func endInteraction() {
        isInteracting = false
    }

    mutating func layoutChanged(visibleIndexes: [Int]) {
        isInteracting = false
        if let highestReachedIndex {
            self.highestReachedIndex = max(highestReachedIndex, visibleIndexes.max() ?? -1)
        }
    }

    mutating func newlyReachedIndexes(visibleIndexes: [Int]) -> [Int] {
        guard isInteracting, let previousHighest = highestReachedIndex else { return [] }
        let reached = Set(visibleIndexes).filter { $0 > previousHighest }.sorted()
        if let highest = reached.last { highestReachedIndex = highest }
        return reached
    }
}
