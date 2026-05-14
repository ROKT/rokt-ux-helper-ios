import UIKit
import SwiftUI
import Combine
import DcuiSchema

@available(iOS 15, *)
struct ViewControllerKey: EnvironmentKey {
    static var defaultValue: ViewControllerHolder {
        return ViewControllerHolder(value: UIApplication.shared.windows.first?.rootViewController)
    }
}

@available(iOS 15, *)
struct ViewControllerHolder {
    weak var value: UIViewController?
}

@available(iOS 15, *)
extension UIViewController {
    func present<Content: View>(placementType: PlacementType?,
                                bottomSheetUIModel: BottomSheetViewModel?,
                                layoutState: LayoutState,
                                eventService: EventService?,
                                onLoad: @escaping (() -> Void),
                                onUnLoad: @escaping (() -> Void),
                                @ViewBuilder builder: (((CGFloat) -> Void)?) -> Content) {

        let modal = RoktUXSwiftUIViewController(rootView: AnyView(EmptyView().background(Color.clear)),
                                                eventService: eventService,
                                                layoutState: layoutState,
                                                onUnload: onUnLoad)
        if #available(iOS 16.0, *),
           let type = placementType,
           type == .BottomSheet(.dynamic),
           let bottomSheetUIModel = bottomSheetUIModel {
            // Only for iOS 16+ dynamic bottomsheet
            var isOnLoadCalled = false
            let onSizeChange = { [weak modal] size in
                DispatchQueue.main.async {
                    if let sheet = modal?.sheetPresentationController {
                        sheet.animateChanges {
                            sheet.detents = [.custom { _ in
                                return size
                            }]
                        }
                        if !isOnLoadCalled {
                            isOnLoadCalled = true
                            onLoad()
                        }
                    }
                }
            }
            modal.rootView = AnyView(
                builder(onSizeChange)
                    .background(Color.clear)
            )

            applyBottomSheetStyles(modal: modal, bottomSheetUIModel: bottomSheetUIModel)
            applyInitialDynamicBottomSheetHeight(modal: modal)
            self.present(modal, animated: true)

        } else {
            modal.rootView = AnyView(
                builder(nil)
                    .background(Color.clear)
            )

            if let type = placementType,
               case .BottomSheet = type,
               let bottomSheetUIModel = bottomSheetUIModel {
                applyBottomSheetStyles(modal: modal, bottomSheetUIModel: bottomSheetUIModel)
                if #available(iOS 16.0, *) {
                    applyFixedBottomSheetHeight(modal: modal,
                                                bottomSheetUIModel: bottomSheetUIModel,
                                                layoutState: layoutState)
                } else {
                    modal.sheetPresentationController?.detents = [.medium()]
                }
            } else {
                modal.modalPresentationStyle = .overFullScreen
                modal.view.backgroundColor = .clear
            }

            self.present(modal, animated: true, completion: {
                onLoad()
            })
        }

        modal.view.isOpaque = false
        layoutState.actionCollection[.close] = { [weak modal, weak layoutState] _ in
            modal?.dismiss(animated: true, completion: nil)
            layoutState?.capturePluginViewState(offerIndex: nil, dismiss: true)
        }
    }

    private func applyBottomSheetStyles(modal: UIHostingController<AnyView>,
                                        bottomSheetUIModel: BottomSheetViewModel) {
        modal.modalPresentationStyle = .pageSheet
        if bottomSheetUIModel.allowBackdropToClose != true {
            modal.isModalInPresentation = true
        }
        // update borderRadius if there is a default style
        if let defaultStyle = bottomSheetUIModel.defaultStyle,
           !defaultStyle.isEmpty,
           let borderRadius = defaultStyle[0].border?.borderRadius {
            modal.sheetPresentationController?.preferredCornerRadius = CGFloat(borderRadius)
        }
    }

    @available(iOS 16.0, *)
    private func applyFixedBottomSheetHeight(modal: RoktUXSwiftUIViewController,
                                             bottomSheetUIModel: BottomSheetViewModel,
                                             layoutState: LayoutState) {
        guard let defaultStyle = bottomSheetUIModel.defaultStyle,
              !defaultStyle.isEmpty,
              let dimensionType = defaultStyle[0].dimension?.height,
              let sheet = modal.sheetPresentationController else {
            return
        }

        switch dimensionType {
        case .fixed(let value):
            sheet.detents = [.custom { _ in CGFloat(value) }]
        case .percentage(let value):
            // Percentage height becomes the medium detent of an expandable sheet.
            // The layout opts into expansion by toggling a "BottomSheetExpandedState" custom state to 1
            // (typically via a See Details button). The SDK animates between [medium, large]
            // detents in response. If the layout never toggles BottomSheetExpandedState, the sheet
            // stays at medium and the only visible change is that the user can drag it up.
            let mediumId = UISheetPresentationController.Detent.Identifier(Self.roktMediumDetentId)
            let medium: UISheetPresentationController.Detent = .custom(identifier: mediumId) { context in
                context.maximumDetentValue * CGFloat(value/100)
            }
            sheet.detents = [medium, .large()]
            sheet.selectedDetentIdentifier = mediumId
            // Mirror user-drag detent changes back into ExpandedState so the
            // layout's expanded-state Whens render in sync with the sheet height.
            let syncDelegate = BottomSheetDetentSyncDelegate(layoutState: layoutState, mediumId: mediumId)
            modal.sheetSyncDelegate = syncDelegate
            sheet.delegate = syncDelegate
            modal.detentObserverCancellable = layoutState.itemsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak sheet] items in
                    guard let sheet = sheet else { return }
                    let map = (items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>)?.wrappedValue
                    let isExpanded = map?.contains(where: { entry in
                        entry.key.key == Self.expandedStateKey && entry.value == 1
                    }) ?? false
                    let targetIdentifier: UISheetPresentationController.Detent.Identifier = isExpanded ? .large : mediumId
                    // Once expanded we narrow the detents to [.large()] only so the user can't
                    // drag the sheet back down to medium — exiting the expanded state has to be
                    // driven programmatically (e.g. by a See-less ToggleButton flipping
                    // ExpandedState back to 0, which lands us in this sink with both detents
                    // re-registered and selectedDetentIdentifier set back to medium).
                    let desiredDetents: [UISheetPresentationController.Detent] = isExpanded ? [.large()] : [medium, .large()]
                    let currentlyExpanded = sheet.selectedDetentIdentifier == .large
                    let detentsNeedUpdate = sheet.detents.count != desiredDetents.count
                    if currentlyExpanded != isExpanded || detentsNeedUpdate {
                        sheet.animateChanges {
                            sheet.detents = desiredDetents
                            sheet.selectedDetentIdentifier = targetIdentifier
                        }
                    }
                }
        case .fit(let type):
            if type == .fitHeight {
                sheet.detents = [.large()]
            }
        }
    }

    @available(iOS 16.0, *)
    private func applyInitialDynamicBottomSheetHeight(modal: UIHostingController<AnyView>) {
        let zeroDetents: [UISheetPresentationController.Detent] = [.custom { _ in
            return CGFloat(0)
        }]
        modal.sheetPresentationController?.detents = zeroDetents
    }

    fileprivate static let expandedStateKey = "BottomSheetExpandedState"
    fileprivate static let roktMediumDetentId = "roktMediumPercentage"

}

@available(iOS 15.0, *)
public final class RoktUXSwiftUIViewController: UIHostingController<AnyView> {
    let onUnload: (() -> Void)?
    weak var eventService: EventService?
    let layoutState: LayoutState?
    // Subscription that mirrors layout state ExpandedState into the sheet's selected detent.
    var detentObserverCancellable: AnyCancellable?
    // Strong reference to the sheet delegate (UISheetPresentationController holds delegate weakly).
    var sheetSyncDelegate: NSObject?

    required init?(coder: NSCoder) {
        self.onUnload = nil
        self.eventService = nil
        self.layoutState = nil
        super.init(coder: coder, rootView: AnyView(EmptyView()))
    }

    init(rootView: AnyView, eventService: EventService?, layoutState: LayoutState, onUnload: @escaping (() -> Void)) {
        self.onUnload = onUnload
        self.eventService = eventService
        self.layoutState = layoutState
        super.init(rootView: rootView)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        // Skip when temporarily covered by a presented modal — the placement isn't dismissed.
        if presentedViewController != nil {
            return
        }
        if eventService?.dismissOption == nil {
            eventService?.sendDismissalEvent()
        }
        onUnload?()
    }

    public func closeModal() {

        if let eventService {
            eventService.dismissOption = .partnerTriggered
            eventService.sendDismissalEvent()
        }
        dismiss(animated: true)
    }
}

// Mirrors user-initiated detent changes back into the layout's "BottomSheetExpandedState"
// custom state so the layout re-renders to match the sheet size. The reverse
// direction (state -> detent) is handled by the Combine subscription on
// layoutState.itemsPublisher inside applyFixedBottomSheetHeight.
@available(iOS 16.0, *)
final class BottomSheetDetentSyncDelegate: NSObject, UISheetPresentationControllerDelegate {
    weak var layoutState: LayoutState?
    let mediumId: UISheetPresentationController.Detent.Identifier

    init(layoutState: LayoutState, mediumId: UISheetPresentationController.Detent.Identifier) {
        self.layoutState = layoutState
        self.mediumId = mediumId
    }

    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheet: UISheetPresentationController) {
        guard let layoutState,
              let binding = layoutState.items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?> else {
            return
        }
        let isLarge = sheet.selectedDetentIdentifier == .large
        let position = (layoutState.items[LayoutState.currentProgressKey] as? Binding<Int>)?.wrappedValue ?? 0
        let identifier = CustomStateIdentifiable(position: position, key: "BottomSheetExpandedState")
        var map = binding.wrappedValue ?? RoktUXCustomStateMap()
        let newValue = isLarge ? 1 : 0
        if map[identifier] != newValue {
            map[identifier] = newValue
            binding.wrappedValue = map
            layoutState.publishStateChange()
        }
    }
}
