import Foundation
import DcuiSchema

@available(iOS 15, *)
class ToggleButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let customStateKey: String
    let accessibilityLabel: String?
    let defaultStyle: [ToggleButtonStateTriggerStyle]?
    let pressedStyle: [ToggleButtonStateTriggerStyle]?
    let hoveredStyle: [ToggleButtonStateTriggerStyle]?
    let disabledStyle: [ToggleButtonStateTriggerStyle]?
    weak var eventService: EventDiagnosticServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         customStateKey: String,
         defaultStyle: [ToggleButtonStateTriggerStyle]?,
         pressedStyle: [ToggleButtonStateTriggerStyle]?,
         hoveredStyle: [ToggleButtonStateTriggerStyle]?,
         disabledStyle: [ToggleButtonStateTriggerStyle]?,
         eventService: EventDiagnosticServicing? = nil,
         layoutState: (any LayoutStateRepresenting)?,
         accessibilityLabel: String? = nil) {
        self.children = children
        self.customStateKey = customStateKey
        self.accessibilityLabel = accessibilityLabel
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.eventService = eventService
        self.layoutState = layoutState
    }

    func handleToggle(position: Int?) {
        if position == nil {
            let current = layoutState?.globalCustomStateValue(for: customStateKey) ?? 0
            layoutState?.setGlobalCustomState(key: customStateKey, value: current == 1 ? 0 : 1)
            layoutState?.capturePluginViewState(offerIndex: nil, dismiss: false)
        } else {
            layoutState?.actionCollection[.toggleCustomState](
                CustomStateIdentifiable(position: position, key: customStateKey)
            )
        }
        eventService?.sendUserInteraction(action: .ToggleButtonStateTriggerClick,
                                          context: .ToggleButtonStateTrigger)
    }

}
