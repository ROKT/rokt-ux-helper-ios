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
    private func displayMinimizableBottomSheet<Content: View>(
        modal: RoktUXSwiftUIViewController,
        bottomSheetUIModel: BottomSheetViewModel,
        layoutState: LayoutState,
        onLoad: @escaping (() -> Void),
        @ViewBuilder builder: (((CGFloat) -> Void)?) -> Content
    ) {
        var isOnLoadCalled = false

        self.addChild(modal)
        let contentView = modal.view!
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(contentView)

        // Set up constraints first
        let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        bottomConstraint.isActive = true
        contentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

        contentView.backgroundColor = .clear

        let onSizeChange = { [weak self] (size: CGFloat) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.view.backgroundColor = .red

                let window = UIApplication.shared.keyWindow

                if !isOnLoadCalled {
                    heightConstraint.constant = size
                    self.view.layoutIfNeeded()

                    // We need to migrate the animation to ResizableBottomSheetComponent due to the faded background
                    UIView.animate(withDuration: 0.3) {
                        self.view.layoutIfNeeded()
                    } completion: { _ in
                        isOnLoadCalled = true
                        onLoad()
                    }
                } else {
                    UIView.animate(withDuration: 0.3) {
                        heightConstraint.constant = size
                        self.view.layoutIfNeeded()
                    }
                }
            }
        }

        modal.rootView = AnyView(
            builder(onSizeChange)
                .background(Color.clear)
        )

        bottomSheetUIModel.onCleanup = { [weak self, weak modal, weak layoutState] in
            guard let self = self, let contentView = modal?.view else { return }
            // Clean up the child view controller
            contentView.removeFromSuperview()
            modal?.willMove(toParent: nil)
            modal?.removeFromParent()
            layoutState?.capturePluginViewState(offerIndex: nil, dismiss: true)
        }
    }

    @available(iOS 16.0, *)
    private func displayExistingBottomSheetImplementation<Content: View>(
        modal: RoktUXSwiftUIViewController,
        bottomSheetUIModel: BottomSheetViewModel,
        layoutState: LayoutState,
        onLoad: @escaping (() -> Void),
        @ViewBuilder builder: (((CGFloat) -> Void)?) -> Content
    ) {
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
        modal.sheetPresentationController?.prefersGrabberVisible = true

        layoutState.actionCollection[.close] = { [weak modal, weak layoutState] _ in
            modal?.dismiss(animated: true, completion: nil)
            layoutState?.capturePluginViewState(offerIndex: nil, dismiss: true)
        }
        self.present(modal, animated: true)
    }

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

            if bottomSheetUIModel.minimizable {
                displayMinimizableBottomSheet(
                    modal: modal,
                    bottomSheetUIModel: bottomSheetUIModel,
                    layoutState: layoutState,
                    onLoad: onLoad,
                    builder: builder
                )
            } else {
                displayExistingBottomSheetImplementation(
                    modal: modal,
                    bottomSheetUIModel: bottomSheetUIModel,
                    layoutState: layoutState,
                    onLoad: onLoad,
                    builder: builder
                )
            }
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

            layoutState.actionCollection[.close] = { [weak modal, weak layoutState] _ in
                modal?.dismiss(animated: true, completion: nil)
                layoutState?.capturePluginViewState(offerIndex: nil, dismiss: true)
            }
        }

        modal.view.isOpaque = false
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
public final class RoktUXSwiftUIViewController: UIHostingController<AnyView> {
    let onUnload: (() -> Void)?
    weak var eventService: EventService?
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

    public func closeModal() {

        if let eventService {
            eventService.dismissOption = .partnerTriggered
            eventService.sendDismissalEvent()
        }
        dismiss(animated: true)
    }
}
