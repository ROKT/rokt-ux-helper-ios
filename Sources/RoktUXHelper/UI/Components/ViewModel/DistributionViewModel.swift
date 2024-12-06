//
//  DistributionViewModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

@available(iOS 13.0, *)
class DistributionViewModel: Hashable {
    let slots: [SlotModel]
    weak var eventService: EventServicing?
    weak var layoutState: (any LayoutStateRepresenting)?
    var config: RoktUXConfig? {
        layoutState?.config
    }
    var initialCurrentIndex: Int? {
        layoutState?.initialPluginViewState?.offerIndex
    }
    var initialCustomStateMap: CustomStateMap? {
        layoutState?.initialPluginViewState?.customStateMap
    }

    init(
        eventService: EventServicing?,
        slots: [SlotModel],
        layoutState: (any LayoutStateRepresenting)?
    ) {
        self.eventService = eventService
        self.slots = slots
        self.layoutState = layoutState
    }

    func sendImpressionEvents(currentOffer: Int) {
        sendSlotImpressionEvent(currentOffer: currentOffer)
        sendCreativeImpressionEvent(currentOffer: currentOffer)
    }

    func sendSlotImpressionEvent(currentOffer: Int) {
        guard let slotJWTToken = getSlotJWTToken(currentOffer: currentOffer) else { return }

        if let instanceGuid = getSlotInstance(currentOffer: currentOffer) {
            eventService?.sendSlotImpressionEvent(
                instanceGuid: instanceGuid,
                jwtToken: slotJWTToken
            )
        }
    }

    func sendCreativeImpressionEvent(currentOffer: Int) {
        guard let creativeJWTToken = getCreativeJWTToken(currentOffer: currentOffer) else { return }

        if let instanceGuid = getCreativeInstance(currentOffer: currentOffer) {
            eventService?.sendSlotImpressionEvent(
                instanceGuid: instanceGuid,
                jwtToken: creativeJWTToken
            )
        }
    }

    func sendCreativeViewedEvent(currentOffer: Int) {
        guard let creativeJWTToken = getCreativeJWTToken(currentOffer: currentOffer) else { return }

        if let instanceGuid = getCreativeInstance(currentOffer: currentOffer) {
            eventService?.sendSignalViewedEvent(
                instanceGuid: instanceGuid,
                jwtToken: creativeJWTToken
            )
        }
    }

    func sendDismissalNoMoreOfferEvent() {
        eventService?.dismissOption = .noMoreOffer
        eventService?.sendDismissalEvent()
    }

    func sendDismissalCollapsedEvent() {
        eventService?.dismissOption = .collapsed
        eventService?.sendDismissalEvent()
    }

    func getSlotInstance(currentOffer: Int) -> String? {
        guard slots.count > currentOffer else { return nil }
        return slots[currentOffer].instanceGuid
    }

    func getSlotJWTToken(currentOffer: Int) -> String? {
        guard slots.count > currentOffer else { return nil }
        return slots[currentOffer].jwtToken
    }

    func getCreativeInstance(currentOffer: Int) -> String? {
        guard slots.count > currentOffer,
              let offer = slots[currentOffer].offer
        else { return nil }

        return offer.creative.instanceGuid
    }

    func getCreativeJWTToken(currentOffer: Int) -> String? {
        guard slots.count > currentOffer,
              let offer = slots[currentOffer].offer
        else { return nil }

        return offer.creative.jwtToken
    }
}
