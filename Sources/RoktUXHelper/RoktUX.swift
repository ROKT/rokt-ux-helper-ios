//
//  OverlayComponent.swift
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
import Combine
import DcuiSchema

/// An object that is responsible for handling UX events and loading user experience layouts provided by Rokt.
@available(iOS 15, *)
public class RoktUX: UXEventsDelegate {
    /**
     * Get the Rokt SDK configuration. Data to be included in the Rokt API request.
     */
    public static var integrationInfo: RoktIntegrationInfo { RoktIntegrationInfo.shared }

    private(set) var onRoktEvent: ((RoktUXEvent) -> Void)?
    private var eventServices: [String: EventService] = [:]

    public init() {}

    /**
     Loads and displays the layout based on the given experience response and configuration.
     
     - Parameters:
       - experienceResponse: The response string containing the experience data.
       - layoutLoaders: A dictionary mapping layout element selectors to their loaders.
       - config: Configuration for the RoktUX.
       - onRoktUXEvent: Closure to handle RoktUX events.
       - onRoktPlatformEvent: Closure to handle platform events. Platform events are an essential part of integration and it has to be sent to Rokt via your backend.
        For ease of use, platformEvent is defined as [String: Any]
       - onEmbeddedSizeChange: Closure to handle changes in embedded layout size.
     */
    public func loadLayout(
        experienceResponse: String,
        layoutLoaders: [String: LayoutLoader?]? = nil,
        config: RoktUXConfig? = nil,
        onRoktUXEvent: @escaping (RoktUXEvent) -> Void,
        onRoktPlatformEvent: @escaping ([String: Any]) -> Void,
        onEmbeddedSizeChange: @escaping (String, CGFloat) -> Void
    ) {
        let integrationType: HelperIntegrationType = .s2s
        let processor = EventProcessor(integrationType: integrationType, onRoktPlatformEvent: onRoktPlatformEvent)
        do {
            let layoutPage = try initiatePageModel(integrationType: integrationType,
                                                   startDate: Date(),
                                                   experienceResponse: experienceResponse,
                                                   processor: processor)

            if let layoutPlugins = layoutPage.layoutPlugins {
                for layoutPlugin in layoutPlugins {
                    let layoutLoader = layoutLoaders?.first { $0.key == layoutPlugin.targetElementSelector }?
                        .value
                    displayLayout(
                        page: layoutPage,
                        layoutPlugin: layoutPlugin,
                        startDate: Date(),
                        responseReceivedDate: layoutPage.responseReceivedDate,
                        layoutLoader: layoutLoader,
                        config: config,
                        onLoad: {},
                        onUnload: {},
                        onEmbeddedSizeChange: onEmbeddedSizeChange,
                        onRoktUXEvent: onRoktUXEvent,
                        processor: processor
                    )
                }
            } else {
                sendDiagnostics(code: kAPIExecuteErrorCode,
                                callStack: kEmptyResponse,
                                processor: processor)
                config?.debugLog("Rokt: No Layouts")
                onRoktUXEvent(RoktUXEvent.LayoutFailure(layoutId: nil))
            }
        } catch {
            sendDiagnostics(code: kValidationErrorCode,
                            callStack: error.localizedDescription,
                            processor: processor)
            config?.debugLog("Rokt: Invalid schema")
            onRoktUXEvent(RoktUXEvent.LayoutFailure(layoutId: nil))
        }
    }

    /**
     Loads and displays the layout based on the given experience response and configuration with additional parameters.
     
     - Parameters:
       - startDate: The start date for the process. Default is current date.
       - experienceResponse: The response string containing the experience data.
       - layoutPluginViewStates: Plugin view states ([RoktPluginViewState]) to be restored.
       - defaultLayoutLoader: Default loader for the layout.
       - layoutLoaders: A dictionary mapping layout element selectors to their loaders.
       - config: Configuration for the RoktUX.
       - onLoad: Closure to handle the loading process.
       - onUnload: Closure to handle the unloading process.
       - onEmbeddedSizeChange: Closure to handle changes in embedded layout size.
       - onRoktUXEvent: Closure to handle RoktUX events.
       - onRoktPlatformEvent: Closure to handle platform events. Platform events are an essential part of integration and it has to be sent to Rokt via your backend.
            For ease of use, platformEvent is defined as [String: Any]
       - onPluginViewStateChange: Closure to handle changes to the RoktPluginViewState.
     */
    public func loadLayout(
        startDate: Date = Date(),
        experienceResponse: String,
        layoutPluginViewStates: [RoktPluginViewState]? = nil,
        defaultLayoutLoader: LayoutLoader? = nil,
        layoutLoaders: [String: LayoutLoader?]? = nil,
        config: RoktUXConfig? = nil,
        onLoad: @escaping (() -> Void),
        onUnload: @escaping (() -> Void),
        onEmbeddedSizeChange: @escaping (String, CGFloat) -> Void,
        onRoktUXEvent: @escaping (RoktUXEvent) -> Void,
        onRoktPlatformEvent: @escaping ([String: Any]) -> Void,
        onPluginViewStateChange: @escaping (RoktPluginViewState) -> Void
    ) {
        let integrationType: HelperIntegrationType = .sdk
        let processor = EventProcessor(integrationType: integrationType,
                                       onRoktPlatformEvent: onRoktPlatformEvent)
        do {
            let layoutPage = try initiatePageModel(integrationType: integrationType,
                                                   startDate: startDate,
                                                   experienceResponse: experienceResponse,
                                                   processor: processor)

            if let layoutPlugins = layoutPage.layoutPlugins {
                for layoutPlugin in layoutPlugins {
                    let layoutLoader = defaultLayoutLoader ?? layoutLoaders?
                        .first { $0.key == layoutPlugin.targetElementSelector }?
                        .value
                    let layoutPluginViewState = layoutPluginViewStates?
                        .first { viewState in viewState.pluginId == layoutPlugin.pluginId }
                    displayLayout(
                        page: layoutPage,
                        layoutPlugin: layoutPlugin,
                        layoutPluginViewState: layoutPluginViewState,
                        startDate: startDate,
                        responseReceivedDate: layoutPage.responseReceivedDate,
                        layoutLoader: layoutLoader,
                        config: config,
                        onLoad: onLoad,
                        onUnload: onUnload,
                        onEmbeddedSizeChange: onEmbeddedSizeChange,
                        onRoktUXEvent: onRoktUXEvent,
                        onPluginViewStateChange: onPluginViewStateChange,
                        processor: processor
                    )
                }
            } else {
                sendDiagnostics(code: kAPIExecuteErrorCode,
                                callStack: kEmptyResponse,
                                processor: processor)
                config?.debugLog("Rokt: No Layouts")
                onRoktUXEvent(RoktUXEvent.LayoutFailure(layoutId: nil))
            }
        } catch {
            sendDiagnostics(code: kValidationErrorCode,
                            callStack: error.localizedDescription,
                            processor: processor)
            config?.debugLog("Rokt: Invalid schema")
            onRoktUXEvent(RoktUXEvent.LayoutFailure(layoutId: nil))
        }
    }

    /**
     Call when instant purchase has succeeded or failed.

     - Parameters:
       - layoutId: layout Id for the relevant displayed catalog item.
       - catalogItemId: Id of the catalog item that was selected.
       - success: whether the purchase succeeded or failed.
     */
    public func instantPurchaseFinalized(layoutId: String, catalogItemId: String, success: Bool) {
        if success {
            eventServices[layoutId]?.cartItemInstantPurchaseSuccess(itemId: catalogItemId)
        } else {
            eventServices[layoutId]?.cartItemInstantPurchaseFailure(itemId: catalogItemId)
        }
    }

    private func initiatePageModel(integrationType: HelperIntegrationType = .s2s,
                                   startDate: Date,
                                   experienceResponse: String,
                                   processor: EventProcessing) throws -> RoktUXPageModel {
        var layoutPage: RoktUXPageModel
        switch integrationType {
        case .sdk:
            layoutPage = try RoktDecoder()
                .decode(RoktUXExperienceResponse.self, experienceResponse)
                .getPageModel()
                .unwrap(orThrow: RoktUXError.experienceResponseMapping)
        default:
            layoutPage = try RoktDecoder()
                .decode(RoktUXS2SExperienceResponse.self, experienceResponse)
                .getPageModel()
                .unwrap(orThrow: RoktUXError.experienceResponseMapping)
        }

        sendPageIntialEvents(
            pageModel: layoutPage,
            startDate: startDate,
            responseReceivedDate: Date(),
            processor: processor
        )
        return layoutPage
    }

    private func displayLayout(
        page: RoktUXPageModel,
        layoutPlugin: LayoutPlugin,
        layoutPluginViewState: RoktPluginViewState? = nil,
        startDate: Date,
        responseReceivedDate: Date,
        layoutLoader: LayoutLoader?,
        config: RoktUXConfig? = nil,
        onLoad: @escaping (() -> Void),
        onUnload: @escaping (() -> Void),
        onEmbeddedSizeChange: @escaping (String, CGFloat) -> Void,
        onRoktUXEvent: @escaping (RoktUXEvent) -> Void,
        onPluginViewStateChange: ((RoktPluginViewState) -> Void)? = nil,
        processor: EventProcessing
    ) {
        onRoktEvent = onRoktUXEvent

        if let isPluginDismissed = layoutPluginViewState?.isPluginDismissed,
           isPluginDismissed {
            onPlacementCompleted(layoutPlugin.pluginId)
            onUnload()
            return
        }

        let actionCollection = ActionCollection()

        let catalogItems = layoutPlugin.slots
            .compactMap(\.offer)
            .map(\.catalogItems)
            .compactMap { $0 }
            .flatMap { $0 }
        let layoutState = LayoutState(actionCollection: actionCollection,
                                      config: config,
                                      pluginId: layoutPlugin.pluginId,
                                      initialPluginViewState: layoutPluginViewState,
                                      onPluginViewStateChange: onPluginViewStateChange)

        let eventService = EventService(
            pageId: page.pageId,
            pageInstanceGuid: page.pageInstanceGuid,
            sessionId: page.sessionId,
            pluginInstanceGuid: layoutPlugin.pluginInstanceGuid,
            pluginId: layoutPlugin.pluginId,
            pluginName: layoutPlugin.pluginName,
            startDate: startDate,
            catalogItems: catalogItems,
            uxEventDelegate: self,
            processor: processor,
            responseReceivedDate: responseReceivedDate,
            pluginConfigJWTToken: layoutPlugin.pluginConfigJWTToken,
            useDiagnosticEvents: page.options?.useDiagnosticEvents == true
        )
        eventServices[layoutPlugin.pluginId] = eventService
        layoutState.items[LayoutState.breakPointsSharedKey] = layoutPlugin.breakpoints
        layoutState.items[LayoutState.layoutSettingsKey] = layoutPlugin.settings

        eventService.sendSignalLoadStartEvent()
        layoutState.setLayoutType(.unknown)

        let layoutTransformer = LayoutTransformer(layoutPlugin: layoutPlugin,
                                                  layoutState: layoutState,
                                                  eventService: eventService)
        do {
            if let layoutUIModel = try layoutTransformer.transform() {
                switch layoutUIModel {
                case .overlay(let model):
                    layoutState.setLayoutType(.overlayLayout)

                    showOverlay(placementType: .Overlay,
                                layoutState: layoutState,
                                eventService: eventService,
                                onLoad: onLoad,
                                onUnload: onUnload) {_ in
                        OverlayComponent(model: model)
                            .customColorMode(colorMode: config?.colorMode)
                    }
                case .bottomSheet(let model):
                    setupBottomSheet(layoutState, model, eventService, onLoad, onUnload, config)
                default:
                    layoutState.setLayoutType(.embeddedLayout)

                    showEmbedded(
                        layoutLoader: layoutLoader,
                        layoutState: layoutState,
                        layoutPlugin: layoutPlugin,
                        layoutUIModel: layoutUIModel,
                        config: config,
                        eventService: eventService,
                        onLoad: onLoad,
                        onUnload: onUnload,
                        onEmbeddedSizeChange: onEmbeddedSizeChange
                    )

                }
            }
            eventService.sendEventsOnTransformerSuccess()
        } catch LayoutTransformerError.InvalidColor(color: let color) {
            // invalid color error
            eventService.sendDiagnostics(message: kValidationErrorCode,
                                         callStack: kColorInvalid + color)
            config?.debugLog("Rokt: Invalid color in schema")
            onRoktUXEvent(RoktUXEvent.LayoutFailure(layoutId: layoutPlugin.pluginId))
        } catch {
            // generic validation error
            eventService.sendDiagnostics(message: kValidationErrorCode,
                                         callStack: kLayoutInvalid)
            config?.debugLog("Rokt: Invalid schema")
            onRoktUXEvent(RoktUXEvent.LayoutFailure(layoutId: layoutPlugin.pluginId))
        }
    }

    fileprivate func setupBottomSheet(
        _ layoutState: LayoutState,
        _ model: BottomSheetViewModel,
        _ eventService: EventService,
        _ onLoad: @escaping (() -> Void),
        _ onUnload: @escaping (() -> Void),
        _ config: RoktUXConfig?
    ) {
        layoutState.setLayoutType(.bottomSheetLayout)

        let bottomSheetHeightDimension = model.defaultStyle?.first?.dimension?.height

        if canShowResizableBottomSheet(bottomSheetHeightDimension) {
            showOverlay(placementType: .BottomSheet(.dynamic),
                        bottomSheetUIModel: model,
                        layoutState: layoutState,
                        eventService: eventService,
                        onLoad: onLoad,
                        onUnload: onUnload) { onSizeChange in
                ResizableBottomSheetComponent(model: model,
                                              onSizeChange: onSizeChange)
                .customColorMode(colorMode: config?.colorMode)
            }
        } else {
            showOverlay(placementType: .BottomSheet(.fixed),
                        bottomSheetUIModel: model,
                        layoutState: layoutState,
                        eventService: eventService,
                        onLoad: onLoad,
                        onUnload: onUnload) { _ in
                BottomSheetComponent(model: model)
                    .customColorMode(colorMode: config?.colorMode)
            }
        }
    }

    /// Resizable bottom sheet requires iOS 16 due to the usage of [custom detents](https://developer.apple.com/documentation/swiftui/custompresentationdetent)
    private func canShowResizableBottomSheet(_ bottomSheetHeightDimension: DimensionHeightValue?) -> Bool {
        if #available(iOS 16.0, *) {
            return bottomSheetHeightDimension == nil || bottomSheetHeightDimension == .fit(.wrapContent)
        }
        return false
    }

    private func showEmbedded(
        layoutLoader: LayoutLoader?,
        layoutState: LayoutState,
        layoutPlugin: LayoutPlugin,
        layoutUIModel: LayoutSchemaViewModel,
        config: RoktUXConfig?,
        eventService: EventDiagnosticServicing?,
        onLoad: @escaping (() -> Void),
        onUnload: @escaping (() -> Void),
        onEmbeddedSizeChange: @escaping (String, CGFloat) -> Void
    ) {
        DispatchQueue.main.async { [weak layoutLoader] in
            if let targetElement = layoutPlugin.targetElementSelector {
                if let layoutLoader {

                    let onSizeChange = { [weak layoutLoader] (size: CGFloat) in
                        layoutLoader?.updateEmbeddedSize(size)
                        onEmbeddedSizeChange(targetElement, size)
                    }

                    layoutLoader.load(onSizeChanged: onSizeChange,
                                      injectedView: {
                        EmbeddedComponent(
                            layout: layoutUIModel,
                            layoutState: layoutState,
                            eventService: eventService,
                            onLoad: onLoad,
                            onSizeChange: onSizeChange
                        )
                        .customColorMode(colorMode: config?.colorMode)
                    })
                    layoutState.actionCollection[.close] = { [weak layoutLoader, weak layoutState] _ in
                        layoutLoader?.closeEmbedded()
                        onUnload()
                        layoutState?.capturePluginViewState(offerIndex: nil, dismiss: true)
                    }
                } else {
                    eventService?.sendDiagnostics(message: kAPIExecuteErrorCode,
                                                  callStack: kEmbeddedLayoutDoesntExistMessage
                                                    + targetElement + kLocationDoesNotExist)
                    config?.debugLog("Rokt: Embedded layout doesn't exist")
                    onUnload()
                    self.onRoktEvent?(RoktUXEvent.LayoutFailure(layoutId: layoutPlugin.pluginId))
                }
            }
        }
    }

    private func showOverlay<Content: View>(placementType: PlacementType?,
                                            bottomSheetUIModel: BottomSheetViewModel? = nil,
                                            layoutState: LayoutState,
                                            eventService: EventService?,
                                            onLoad: @escaping (() -> Void),
                                            onUnload: @escaping (() -> Void),
                                            @ViewBuilder builder: @escaping (((CGFloat) -> Void)?) -> Content) {
        DispatchQueue.main.async {
            if let viewController = self.getTopViewController() {
                viewController.present(placementType: placementType,
                                       bottomSheetUIModel: bottomSheetUIModel,
                                       layoutState: layoutState,
                                       eventService: eventService,
                                       onLoad: onLoad,
                                       onUnLoad: onUnload,
                                       builder: builder)
            }
        }
    }

    private func getTopViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }

    private func sendPageIntialEvents(
        pageModel: RoktUXPageModel,
        startDate: Date,
        responseReceivedDate: Date,
        processor: EventProcessing
    ) {
        processor.handle(
            event: RoktEventRequest(
                sessionId: pageModel.sessionId,
                eventType: RoktUXEventType.SignalInitialize,
                parentGuid: pageModel.pageInstanceGuid,
                eventTime: startDate,
                jwtToken: pageModel.token
            )
        )
        processor.handle(
            event: RoktEventRequest(
                sessionId: pageModel.sessionId,
                eventType: RoktUXEventType.SignalLoadStart,
                parentGuid: pageModel.pageInstanceGuid,
                eventTime: startDate,
                jwtToken: pageModel.token
            )
        )
        processor.handle(
            event: RoktEventRequest(
                sessionId: pageModel.sessionId,
                eventType: RoktUXEventType.SignalLoadComplete,
                parentGuid: pageModel.pageInstanceGuid,
                eventTime: responseReceivedDate,
                jwtToken: pageModel.token
            )
        )
    }

    private func sendDiagnostics(sessionId: String? = nil,
                                 code: String?,
                                 callStack: String?,
                                 severity: Severity = .error,
                                 processor: EventProcessing) {
        processor.handle(
            event: RoktEventRequest(
                sessionId: sessionId ?? "",
                eventType: .SignalSdkDiagnostic,
                parentGuid: "",
                eventData: [
                    kErrorCode: code ?? "",
                    kErrorStackTrace: callStack ?? "",
                    kErrorSeverity: severity.rawValue
                ],
                jwtToken: ""
            )
        )
    }

    func onOfferEngagement(_ pluginId: String) {
        onRoktEvent?(RoktUXEvent.OfferEngagement(layoutId: pluginId))
    }

    func onFirstPositiveEngagement(
        sessionId: String,
        pluginInstanceGuid: String,
        jwtToken: String,
        layoutId: String
    ) {
        onRoktEvent?(
            .FirstPositiveEngagement(
                sessionId: sessionId,
                pageInstanceGuid: pluginInstanceGuid,
                jwtToken: jwtToken,
                layoutId: layoutId
            )
        )
    }

    func onPositiveEngagement(_ layoutId: String) {
        onRoktEvent?(RoktUXEvent.PositiveEngagement(layoutId: layoutId))
    }

    func onPlacementInteractive(_ layoutId: String) {
        onRoktEvent?(RoktUXEvent.LayoutInteractive(layoutId: layoutId))
    }

    func onPlacementReady(_ layoutId: String) {
        onRoktEvent?(RoktUXEvent.LayoutReady(layoutId: layoutId))
    }

    func onPlacementClosed(_ layoutId: String) {
        onRoktEvent?(RoktUXEvent.LayoutClosed(layoutId: layoutId))
    }

    func onPlacementCompleted(_ layoutId: String) {
        onRoktEvent?(RoktUXEvent.LayoutCompleted(layoutId: layoutId))
    }

    func onPlacementFailure(_ layoutId: String) {
        onRoktEvent?(RoktUXEvent.LayoutFailure(layoutId: layoutId))
    }

    func openURL(url: String,
                 id: String,
                 layoutId: String,
                 type: RoktUXOpenURLType,
                 onClose: @escaping (String) -> Void,
                 onError: @escaping (String, Error?) -> Void) {
        onRoktEvent?(RoktUXEvent.OpenUrl(url: url, id: id, layoutId: layoutId, type: type, onClose: onClose, onError: onError))
    }

    func onCartItemInstantPurchase(_ layoutId: String, catalogItem: CatalogItem) {
        onRoktEvent?(RoktUXEvent.CartItemInstantPurchase(
            layoutId: layoutId,
            name: catalogItem.title,
            cartItemId: catalogItem.cartItemId,
            catalogItemId: catalogItem.catalogItemId,
            currency: catalogItem.currency,
            description: catalogItem.description,
            linkedProductId: catalogItem.linkedProductId,
            providerData: catalogItem.providerData,
            quantity: 1,
            totalPrice: catalogItem.originalPrice,
            unitPrice: catalogItem.originalPrice
        ))
    }
}
