import Combine
import SwiftUI

/// Reuses the When predicate observer and shared style union for conditional styling.
final class ConditionalStyleBinding: ObservableObject {
    let condition: WhenViewModel
    let animation: AnimationStyle
    private var subscription: AnyCancellable?

    init(condition: WhenViewModel, animation: AnimationStyle) {
        self.condition = condition
        self.animation = animation
        subscription = condition.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    func applies(position: Int?, width: CGFloat, colorScheme: ColorScheme) -> Bool {
        condition.shouldApply(WhenComponentUIState(
            currentProgress: condition.currentProgress.wrappedValue, totalOffers: condition.totalItems,
            position: position, width: width, isDarkMode: colorScheme == .dark,
            customStateMap: condition.customStateMap.wrappedValue,
            globalCustomStateMap: condition.globalCustomStateMap.wrappedValue
        ))
    }

    func resolve(_ base: BaseStyles?, position: Int?, width: CGFloat, colorScheme: ColorScheme) -> BaseStyles? {
        applies(position: position, width: width, colorScheme: colorScheme)
            ? BaseStyles.union(base, diff: animation.style) : base
    }
}
