import Foundation
import DcuiSchema

@available(iOS 15, *)
class CloseButtonViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()
    let children: [LayoutSchemaViewModel]?
    let defaultStyle: [CloseButtonStyles]?
    let pressedStyle: [CloseButtonStyles]?
    let hoveredStyle: [CloseButtonStyles]?
    let disabledStyle: [CloseButtonStyles]?
    weak var eventService: EventServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         defaultStyle: [CloseButtonStyles]?,
         pressedStyle: [CloseButtonStyles]?,
         hoveredStyle: [CloseButtonStyles]?,
         disabledStyle: [CloseButtonStyles]?,
         layoutState: (any LayoutStateRepresenting)?,
         eventService: EventServicing?) {
        self.children = children
        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle
        self.layoutState = layoutState
        self.eventService = eventService
    }

    func sendCloseEvent() {
        eventService?.dismissOption = .closeButton
        eventService?.sendDismissalEvent()
    }
}
