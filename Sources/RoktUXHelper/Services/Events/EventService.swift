//
//  EventService.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import SwiftUI
import Combine

enum LayoutDismissOptions {
    case closeButton, noMoreOffer, endMessage, collapsed, defaultDismiss, partnerTriggered
}

typealias EventDiagnosticServicing = EventServicing & DiagnosticServicing

@available(iOS 13.0, *)
class EventService: Hashable, EventDiagnosticServicing {
    let pageId: String?
    let pageInstanceGuid: String
    let sessionId: String
    let pluginInstanceGuid: String
    let pluginId: String
    let pluginName: String?
    let startDate: Date
    let pluginConfigJWTToken: String
    let useDiagnosticEvents: Bool
    let processor: EventProcessing
    let catalogItems: [CatalogItem]

    weak var uxEventDelegate: UXEventsDelegate?
    var responseReceivedDate: Date
    var isFirstPositiveEngagementSend = false
    var dismissOption: LayoutDismissOptions?

    init(pageId: String?,
         pageInstanceGuid: String,
         sessionId: String,
         pluginInstanceGuid: String,
         pluginId: String,
         pluginName: String?,
         startDate: Date,
         catalogItems: [CatalogItem] = [],
         uxEventDelegate: UXEventsDelegate,
         processor: EventProcessing,
         responseReceivedDate: Date,
         isFirstPositiveEngagementSend: Bool = false,
         pluginConfigJWTToken: String,
         dismissOption: LayoutDismissOptions? = nil,
         useDiagnosticEvents: Bool) {
        self.pageId = pageId
        self.pageInstanceGuid = pageInstanceGuid
        self.sessionId = sessionId
        self.pluginInstanceGuid = pluginInstanceGuid
        self.pluginId = pluginId
        self.pluginName = pluginName
        self.startDate = startDate
        self.uxEventDelegate = uxEventDelegate
        self.responseReceivedDate = responseReceivedDate
        self.isFirstPositiveEngagementSend = isFirstPositiveEngagementSend
        self.pluginConfigJWTToken = pluginConfigJWTToken
        self.dismissOption = dismissOption
        self.useDiagnosticEvents = useDiagnosticEvents
        self.processor = processor
        self.catalogItems = catalogItems
    }

    func sendSignalLoadStartEvent() {
        sendEvent(.SignalLoadStart, parentGuid: pluginInstanceGuid, jwtToken: pluginConfigJWTToken)
    }

    func sendEventsOnTransformerSuccess() {
        sendPlacementReadyEventCallback()
        sendSignalLoadCompleteEvent()
    }

    private func sendPlacementReadyEventCallback() {
        uxEventDelegate?.onPlacementReady(pluginId)
    }

    private func sendSignalLoadCompleteEvent() {
        sendEvent(.SignalLoadComplete, parentGuid: pluginInstanceGuid, jwtToken: pluginConfigJWTToken)
    }

    func sendSignalActivationEvent() {
        sendEvent(.SignalActivation, parentGuid: pluginInstanceGuid, jwtToken: pluginConfigJWTToken)
    }

    func sendEventsOnLoad() {
        sendPlacementInteractiveEventCallback()
        sendPluginImpressionEvent()
    }

    func sendSlotImpressionEvent(instanceGuid: String, jwtToken: String) {
        sendEvent(.SignalImpression, parentGuid: instanceGuid, jwtToken: jwtToken)
    }

    func sendSignalViewedEvent(instanceGuid: String, jwtToken: String) {
        sendEvent(.SignalViewed, parentGuid: instanceGuid, jwtToken: jwtToken)
    }

    func sendSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool) {
        sendEngagementEventCallback(isPositive: isPositive)
        sendEvent(
            .SignalResponse,
            parentGuid: instanceGuid,
            jwtToken: jwtToken
        )
    }
    func sendGatedSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool) {
        sendEngagementEventCallback(isPositive: isPositive)
        sendEvent(.SignalGatedResponse,
                  parentGuid: instanceGuid,
                  jwtToken: jwtToken)
    }

    func sendDismissalEvent() {
        sendDismissalEventCallback()
        switch dismissOption {
        case .noMoreOffer:
            sendDismissalNoMoreOfferEvent()
        case .closeButton:
            sendDismissalCloseEvent()
        case .endMessage:
            sendDismissalEndMessageEvent()
        case .collapsed:
            sendDismissalCollapsedEvent()
        case .partnerTriggered:
            sendDismissalPartnerTriggeredEvent()
        default:
            sendDefaultDismissEvent()
        }
    }

    func sendEvent(
        _ eventType: RoktUXEventType,
        parentGuid: String,
        extraMetadata: [RoktEventNameValue] = [RoktEventNameValue](),
        eventData: [String: String] = [:],
        jwtToken: String
    ) {
        processor.handle(
            event: RoktEventRequest(
                sessionId: sessionId,
                eventType: eventType,
                parentGuid: parentGuid,
                extraMetadata: extraMetadata,
                eventData: eventData,
                pageInstanceGuid: pageInstanceGuid,
                jwtToken: jwtToken
            )
        )
    }

    func openURL(url: URL, type: RoktUXOpenURLType, completionHandler: @escaping () -> Void) {
        canOpenUrl(url)
        let id = UUID().uuidString
        uxEventDelegate?.openURL(url: url.absoluteString, id: id, layoutId: pluginId, type: type, onClose: { incomingId in
            if id == incomingId {
                completionHandler()
            }
        }, onError: { [weak self] incomingId, error in
            if id == incomingId {
                self?.sendDiagnostics(message: kWebViewErrorCode,
                                      callStack: error?.localizedDescription ?? kStaticPageError)
            }
        })
    }

    func cartItemInstantPurchase(catalogItem: CatalogItem) {
        sendCartItemEvent(eventType: .SignalCartItemInstantPurchaseInitiated, catalogItem: catalogItem)
        uxEventDelegate?.onCartItemInstantPurchase(pluginId, catalogItem: catalogItem)
    }

    func cartItemInstantPurchaseSuccess(itemId: String) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }
        sendCartItemEvent(eventType: .SignalCartItemInstantPurchase, catalogItem: catalogItem)
    }

    func cartItemInstantPurchaseFailure(itemId: String) {
        guard let catalogItem = catalogItems.first(where: { $0.catalogItemId == itemId }) else { return }
        sendCartItemEvent(eventType: .SignalCartItemInstantPurchaseFailure, catalogItem: catalogItem)
    }

    private func sendCartItemEvent(eventType: RoktUXEventType, catalogItem: CatalogItem) {
        sendEvent(
            eventType,
            parentGuid: catalogItem.instanceGuid,
            eventData: [
                kCartItemId: catalogItem.cartItemId,
                kCatalogItemId: catalogItem.catalogItemId,
                kCurrency: catalogItem.currency,
                kDescription: catalogItem.description,
                kLinkedProductId: catalogItem.linkedProductId ?? "",
                kTotalPrice: "\(catalogItem.originalPrice ?? 0.0)",
                kQuantity: "1",
                kUnitPrice: "\(catalogItem.originalPrice ?? 0.0)"
            ],
            jwtToken: catalogItem.token
        )
    }

    private func canOpenUrl(_ url: URL) {
        if !UIApplication.shared.canOpenURL(url) {
            sendDiagnostics(message: kUrlErrorCode,
                            callStack: url.absoluteString)
        }
    }

    private func sendPlacementInteractiveEventCallback() {
        uxEventDelegate?.onPlacementInteractive(pluginId)
    }

    private func sendPluginImpressionEvent() {
        var metaData = [
            RoktEventNameValue(name: BE_PAGE_SIGNAL_LOAD,
                               value: EventDateFormatter.getDateString(startDate)),
            RoktEventNameValue(name: BE_PAGE_RENDER_ENGINE,
                               value: BE_RENDER_ENGINE_LAYOUTS),
            RoktEventNameValue(name: BE_PAGE_SIGNAL_COMPLETE,
                               value: EventDateFormatter.getDateString(responseReceivedDate)),
            RoktEventNameValue(name: BE_TIMINGS_EVENT_TIME_KEY,
                               value: EventDateFormatter.getDateString(DateHandler.currentDate())),
            RoktEventNameValue(name: BE_HEADER_PAGE_INSTANCE_GUID_KEY,
                               value: pageInstanceGuid),
            RoktEventNameValue(name: BE_TIMINGS_PLUGIN_ID_KEY,
                               value: pluginId)
        ]
        pageId.map {
            metaData.append(
                RoktEventNameValue(name: BE_VIEW_NAME_KEY, value: $0)
            )
        }
        pluginName.map {
            metaData.append(
                RoktEventNameValue(name: BE_TIMINGS_PLUGIN_NAME_KEY,
                                   value: $0)
            )
        }
        sendEvent(.SignalImpression,
                  parentGuid: pluginInstanceGuid,
                  extraMetadata: metaData,
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDismissalEndMessageEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kEndMessage)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDismissalCollapsedEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kCollapsed)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDismissalCloseEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kCloseButton)],
                  jwtToken: pluginConfigJWTToken)
    }
    private func sendDismissalPartnerTriggeredEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kPartnerTriggered)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDismissalNoMoreOfferEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kNoMoreOfferToShow)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendDefaultDismissEvent() {
        sendEvent(.SignalDismissal, parentGuid: pluginInstanceGuid,
                  extraMetadata: [RoktEventNameValue(name: kInitiator, value: kDismissed)],
                  jwtToken: pluginConfigJWTToken)
    }

    private func sendEngagementEventCallback(isPositive: Bool) {
        uxEventDelegate?.onOfferEngagement(pluginId)

        if isPositive {
            uxEventDelegate?.onPositiveEngagement(pluginId)

            if !isFirstPositiveEngagementSend {
                uxEventDelegate?.onFirstPositiveEngagement(
                    sessionId: sessionId,
                    pluginInstanceGuid: pluginInstanceGuid,
                    jwtToken: pluginConfigJWTToken,
                    layoutId: pluginId
                )
                isFirstPositiveEngagementSend = true
            }
        }
    }

    private func sendDismissalEventCallback() {
        switch dismissOption {
        case .noMoreOffer, .endMessage, .collapsed:
            uxEventDelegate?.onPlacementCompleted(pluginId)
        case .closeButton, .partnerTriggered:
            uxEventDelegate?.onPlacementClosed(pluginId)
        default:
            uxEventDelegate?.onPlacementClosed(pluginId)
        }
    }
}

class DateHandler {
    static var customDate: Date?

    static func currentDate() -> Date {
        return self.customDate ?? Date()
    }
}

class EventDateFormatter {

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: kBaseLocale)
        dateFormatter.dateFormat = kEventTimeStamp
        dateFormatter.timeZone = TimeZone(abbreviation: kUTCTimeStamp)
        return dateFormatter
    }()

    static func getDateString(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
