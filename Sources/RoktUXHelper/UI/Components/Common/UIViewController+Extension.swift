//
//  UIViewController+Extension.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import UIKit
import SwiftUI
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

        let modal = SwiftUIViewController(rootView: AnyView(EmptyView().background(Color.clear)),
                                          eventService: eventService,
                                          layoutState: layoutState,
                                          onUnload: onUnLoad)

        if #available(iOS 16.0, *),
           let type = placementType,
           type == .BottomSheet(.dynamic),
           let bottomSheetUIModel = bottomSheetUIModel {
            // Only for iOS 16+ dynamic bottomsheet
            var isOnLoadCalled = false
            var onSizeChange = { [weak self, weak modal] size in
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
                    applyFixedBottomSheetHeight(modal: modal, bottomSheetUIModel: bottomSheetUIModel)
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
        layoutState.actionCollection[.close] = { [weak self, weak modal] _ in
            modal?.dismiss(animated: true, completion: nil)
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
    private func applyFixedBottomSheetHeight(modal: UIHostingController<AnyView>,
                                             bottomSheetUIModel: BottomSheetViewModel) {
        if let defaultStyle = bottomSheetUIModel.defaultStyle,
           !defaultStyle.isEmpty,
           let dimensionType = defaultStyle[0].dimension?.height,
           let customDetents = getFixedBottomSheetDetents(dimensionType: dimensionType) {
            modal.sheetPresentationController?.detents = customDetents
        }
    }

    @available(iOS 16.0, *)
    private func applyInitialDynamicBottomSheetHeight(modal: UIHostingController<AnyView>) {
        let zeroDetents: [UISheetPresentationController.Detent] = [.custom { _ in
            return CGFloat(0)
        }]
        modal.sheetPresentationController?.detents = zeroDetents
    }

    @available(iOS 16.0, *)
    private func getFixedBottomSheetDetents(dimensionType: DimensionHeightValue)
    -> [UISheetPresentationController.Detent]? {
        switch dimensionType {
        case .fixed(let value):
            return [.custom { _ in
                return CGFloat(value)
            }]
        case .percentage(let value):
            return [.custom { context in
                return context.maximumDetentValue * CGFloat(value/100)
            }]
        case .fit(let type):
            if type == .fitHeight {
                return [.large()]
            } else {
                return nil
            }
        }
    }

}

@available(iOS 15.0, *)
public final class SwiftUIViewController: UIHostingController<AnyView> {
    let onUnload: (() -> Void)?
    let eventService: EventService?
    let layoutState: LayoutState?

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
        // The viewcontroller is dismissed by touching outside of swipe down
        if eventService?.dismissOption == nil {
            eventService?.sendDismissalEvent()
        }
        onUnload?()
    }

    func closeModal() {
        if let eventService {
            eventService.dismissOption = .partnerTriggered
            eventService.sendDismissalEvent()
        }
        dismiss(animated: true)
    }
}
