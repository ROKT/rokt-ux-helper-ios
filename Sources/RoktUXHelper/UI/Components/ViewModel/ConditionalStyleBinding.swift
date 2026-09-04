import Combine
import SwiftUI

/// Reuses the When predicate observer and shared style union for conditional styling.
final class ConditionalStyleBinding: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    let condition: WhenViewModel
    let animation: AnimationStyle
    private var boundState: BoundState
    private var subscription: AnyCancellable?

    init(condition: WhenViewModel, animation: AnimationStyle) {
        self.condition = condition
        self.animation = animation
        self.boundState = BoundState(condition: condition)
        subscription = condition.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in
            guard let self else { return }
            // Read saved bindings outside SwiftUI's body evaluation, where their cached values can be stale.
            let updatedState = BoundState(condition: self.condition)
            self.objectWillChange.send()
            self.boundState = updatedState
        }
    }

    func applies(position: Int?, width: CGFloat, colorScheme: ColorScheme) -> Bool {
        condition.shouldApply(WhenComponentUIState(
            currentProgress: boundState.currentProgress, totalOffers: boundState.totalOffers,
            position: position, width: width, isDarkMode: colorScheme == .dark,
            customStateMap: boundState.customStateMap,
            globalCustomStateMap: boundState.globalCustomStateMap
        ))
    }

    func resolve(_ base: BaseStyles?, position: Int?, width: CGFloat, colorScheme: ColorScheme) -> BaseStyles? {
        applies(position: position, width: width, colorScheme: colorScheme)
            ? BaseStyles.union(base, diff: animation.style) : base
    }

    private struct BoundState {
        let currentProgress: Int
        let totalOffers: Int
        let customStateMap: RoktUXCustomStateMap?
        let globalCustomStateMap: RoktUXCustomStateMap?

        init(condition: WhenViewModel) {
            currentProgress = condition.currentProgress.wrappedValue
            totalOffers = condition.totalItems
            customStateMap = condition.customStateMap.wrappedValue
            globalCustomStateMap = condition.globalCustomStateMap.wrappedValue
        }
    }
}
