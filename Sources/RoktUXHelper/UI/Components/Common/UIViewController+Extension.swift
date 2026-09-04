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
        if let type = placementType,
           case .BottomSheet(let sheetType) = type,
           let bottomSheetUIModel,
           shouldUseFullBleedBottomSheet(layoutState: layoutState) {
            presentFullBleedBottomSheet(modal: modal,
                                        sheetType: sheetType,
                                        bottomSheetUIModel: bottomSheetUIModel,
                                        layoutState: layoutState,
                                        onLoad: onLoad,
                                        builder: builder)
        } else if #available(iOS 16.0, *),
           let type = placementType,
           type == .BottomSheet(.dynamic),
           let bottomSheetUIModel = bottomSheetUIModel {
            // Only for iOS 16+ dynamic bottomsheet
            var isOnLoadCalled = false
            let onSizeChange = { [weak modal] (size: CGFloat) in
                DispatchQueue.main.async {
                    let detentHeight = max(size, 1)
                    guard let sheet = modal?.sheetPresentationController else {
                        return
                    }
                    sheet.animateChanges {
                        sheet.detents = [.custom { _ in detentHeight }]
                    }
                    if !isOnLoadCalled {
                        isOnLoadCalled = true
                        onLoad()
                    }
                }
            }
            modal.rootView = AnyView(
                builder(onSizeChange)
                    .background(Color.clear)
            )

            applyBottomSheetStyles(modal: modal, bottomSheetUIModel: bottomSheetUIModel)
            applyInitialDynamicBottomSheetHeight(modal: modal)
            self.present(modal, animated: true, completion: {
                modal.view.setNeedsLayout()
                modal.view.layoutIfNeeded()
            })

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

    /// A layout opts into SDK-owned presentation by setting `bottomSheetPresentation` to
    /// `fullBleed`. Absent — every layout published before schema 2.10 — keeps UIKit's sheet.
    private func shouldUseFullBleedBottomSheet(layoutState: LayoutState) -> Bool {
        RoktBottomSheetPresentationController.shouldPresentFullBleed(
            presentation: layoutState.bottomSheetPresentation(),
            horizontalSizeClass: traitCollection.horizontalSizeClass
        )
    }

    private func presentFullBleedBottomSheet<Content: View>(
        modal: RoktUXSwiftUIViewController,
        sheetType: BottomSheetType,
        bottomSheetUIModel: BottomSheetViewModel,
        layoutState: LayoutState,
        onLoad: @escaping (() -> Void),
        @ViewBuilder builder: (((CGFloat) -> Void)?) -> Content
    ) {
        let isDynamic = sheetType == .dynamic
        var isOnLoadCalled = false

        // The wrap-content path reports its height from SwiftUI, exactly as it does when driving
        // custom detents. Starting at half the available height gives the hosted tree a non-zero
        // layout proposal to measure against, the same reason the detent path starts at .medium.
        let onSizeChange: ((CGFloat) -> Void)? = isDynamic
            ? { [weak modal] size in
                DispatchQueue.main.async {
                    guard let modal else { return }
                    let height = max(size, 1)
                    // The presentation controller only exists once presentation is under way.
                    // A size reported before then is held rather than dropped: dropping it would
                    // leave the sheet at its initial height and, because onLoad is chained to the
                    // first size, would stop the impression from ever being sent.
                    if let controller = modal.bottomSheetPresentationController {
                        controller.setSheetHeight(height, animated: isOnLoadCalled)
                    } else {
                        modal.pendingBottomSheetHeight = height
                    }
                    if !isOnLoadCalled {
                        isOnLoadCalled = true
                        onLoad()
                    }
                }
            }
            : nil

        modal.rootView = AnyView(builder(onSizeChange).background(Color.clear))

        let transitioningDelegate = RoktBottomSheetTransitioningDelegate(
            heightResolver: fullBleedHeightResolver(sheetType: sheetType,
                                                    bottomSheetUIModel: bottomSheetUIModel),
            cornerRadius: bottomSheetCornerRadius(bottomSheetUIModel) ?? 0,
            allowBackdropToClose: bottomSheetUIModel.allowBackdropToClose == true
        )
        modal.modalPresentationStyle = .custom
        modal.transitioningDelegate = transitioningDelegate
        // UIViewController holds transitioningDelegate weakly.
        modal.bottomSheetTransitioningDelegate = transitioningDelegate

        if !isDynamic, case .percentage = bottomSheetHeightDimension(bottomSheetUIModel) {
            observeExpandedState(modal: modal, layoutState: layoutState)
        }

        self.present(modal, animated: true, completion: { [weak modal] in
            if let modal, let pending = modal.pendingBottomSheetHeight {
                modal.pendingBottomSheetHeight = nil
                modal.bottomSheetPresentationController?.setSheetHeight(pending, animated: false)
            }
            if !isDynamic {
                onLoad()
            }
        })
    }

    /// Resolved against the height actually available to the sheet, rather than UIKit's
    /// safe-area-relative detent value. The dynamic sheet is sized by its content, so its height
    /// never comes from styling.
    private func fullBleedHeightResolver(sheetType: BottomSheetType,
                                         bottomSheetUIModel: BottomSheetViewModel) -> (CGFloat) -> CGFloat {
        let height = sheetType == .dynamic ? nil : bottomSheetHeightDimension(bottomSheetUIModel)
        return RoktBottomSheetPresentationController.heightResolver(for: height)
    }

    private func bottomSheetHeightDimension(
        _ bottomSheetUIModel: BottomSheetViewModel
    ) -> DimensionHeightValue? {
        bottomSheetUIModel.defaultStyle?.first?.dimension?.height
    }

    private func bottomSheetCornerRadius(_ bottomSheetUIModel: BottomSheetViewModel) -> CGFloat? {
        guard let defaultStyle = bottomSheetUIModel.defaultStyle,
              !defaultStyle.isEmpty,
              let borderRadius = defaultStyle[0].border?.borderRadius else {
            return nil
        }
        return CGFloat(borderRadius)
    }

    /// The percentage path is an expandable sheet: the layout toggles "BottomSheetExpandedState"
    /// and the sheet animates between its percentage height and the full available height. The
    /// detent path drives this through UIKit; here it is a direct resize.
    private func observeExpandedState(modal: RoktUXSwiftUIViewController, layoutState: LayoutState) {
        modal.detentObserverCancellable = layoutState.itemsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak modal] items in
                guard let controller = modal?.bottomSheetPresentationController else { return }
                let isExpanded = Self.isBottomSheetExpanded(in: items)
                let target = isExpanded ? controller.maximumSheetHeight : controller.collapsedHeight
                guard abs(controller.resolvedSheetHeight - target) > 0.5 else { return }
                controller.setExpanded(isExpanded, animated: true)
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
            sheet.detents = [medium]
            sheet.selectedDetentIdentifier = mediumId
            // Mirror user-drag detent changes back into BottomSheetExpandedState so the
            // layout's expanded-state Whens render in sync with the sheet height. With
            // only one detent registered at a time the user can't physically drag between
            // them, so this delegate effectively only fires for programmatic detent
            // changes — kept around as a safety net in case iOS ever surfaces a path
            // through dragging despite the single-detent configuration.
            let syncDelegate = BottomSheetDetentSyncDelegate(layoutState: layoutState, mediumId: mediumId)
            modal.sheetSyncDelegate = syncDelegate
            sheet.delegate = syncDelegate
            modal.detentObserverCancellable = layoutState.itemsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak sheet] items in
                    guard let sheet = sheet else { return }
                    let isExpanded = Self.isBottomSheetExpanded(in: items)
                    let targetIdentifier: UISheetPresentationController.Detent.Identifier = isExpanded ? .large : mediumId
                    // Lock the sheet by only ever registering a single detent for the
                    // current state. The transitions between medium and large therefore
                    // have to be driven programmatically (a ToggleButtonStateTrigger
                    // flipping BottomSheetExpandedState), which the SDK animates in
                    // both directions inside the animateChanges block below.
                    let desiredDetents: [UISheetPresentationController.Detent] = isExpanded ? [.large()] : [medium]
                    let currentlyExpanded = sheet.selectedDetentIdentifier == .large
                    let detentsNeedUpdate = sheet.detents.first?.identifier != desiredDetents.first?.identifier
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
        // A pure zero-height custom detent can prevent the hosted SwiftUI tree from receiving
        // a non-zero layout proposal on some OS versions. Geometry/readSize then never reaches
        // wrap-content height, onSizeChange never runs, and impression events never fire.
        // Start from the system medium detent so content can measure; onSizeChange then replaces
        // detents with an exact-height custom detent.
        guard let sheet = modal.sheetPresentationController else { return }
        sheet.detents = [.medium()]
        sheet.selectedDetentIdentifier = .medium
    }

    fileprivate static let expandedStateKey = "BottomSheetExpandedState"

    /// Whether the layout has toggled its expanded state on. Read by both the full-bleed and the
    /// custom-detent paths, so it lives here rather than being spelled out in each observer.
    static func isBottomSheetExpanded(in items: [String: Any]) -> Bool {
        let global = (items[LayoutState.globalCustomStateMapKey] as? Binding<RoktUXCustomStateMap?>)?.wrappedValue
        if let value = global?[CustomStateIdentifiable(position: nil, key: expandedStateKey)] {
            // An explicit global collapse must win over retained per-offer expansion state.
            return value == 1
        }
        let map = (items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>)?.wrappedValue
        return map?.contains { $0.key.key == expandedStateKey && $0.value == 1 } ?? false
    }
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
    // Strong reference to the full-bleed delegate (UIViewController holds transitioningDelegate weakly).
    var bottomSheetTransitioningDelegate: RoktBottomSheetTransitioningDelegate?

    // Height reported by the content before the presentation controller existed.
    var pendingBottomSheetHeight: CGFloat?

    var bottomSheetPresentationController: RoktBottomSheetPresentationController? {
        presentationController as? RoktBottomSheetPresentationController
    }

    override public func accessibilityPerformEscape() -> Bool {
        guard let controller = bottomSheetPresentationController else {
            return super.accessibilityPerformEscape()
        }
        return controller.performAccessibilityEscape()
    }

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
        guard let layoutState else { return }
        let key = UIViewController.expandedStateKey
        let newValue = sheet.selectedDetentIdentifier == .large ? 1 : 0
        if let globalValue = layoutState.globalCustomStateValue(for: key) {
            if globalValue != newValue {
                layoutState.setGlobalCustomState(key: key, value: newValue)
                layoutState.capturePluginViewState(offerIndex: nil, dismiss: false)
            }
            return
        }
        let position = (layoutState.items[LayoutState.currentProgressKey] as? Binding<Int>)?.wrappedValue ?? 0
        let identifier = CustomStateIdentifiable(position: position, key: key)
        guard let binding = layoutState.items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>,
              var map = binding.wrappedValue,
              map[identifier] != nil else {
            // A callback must not create expansion state for an offer that never set it.
            return
        }
        if map[identifier] != newValue {
            map[identifier] = newValue
            binding.wrappedValue = map
            layoutState.publishStateChange()
        }
    }
}
