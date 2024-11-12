//
//  TestDistributionViewModel.swift
//  RoktUXHelperTests
//
//  Copyright 2020 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
@testable import RoktUXHelper

@available(iOS 13, *)
final class TestDistributionViewModel: XCTestCase {
    
    var events = [EventRequest]()
    var eventService: EventService!
    var stubUXHelper: MockUXHelper!
    var layoutState: LayoutState = LayoutState()
    override func setUpWithError() throws {
        events = [EventRequest]()
        eventService = get_mock_event_processor { [weak self] event in
            self?.events.append(event)
        }
        stubUXHelper = MockUXHelper()
    }
    
    func test_slot_impression_event() throws {
        // Arrange
        let viewModel = getDistributionViewModel(eventService: eventService, layoutState: layoutState)

        // Act
        viewModel.sendSlotImpressionEvent(currentOffer: 0)

        // Assert
        XCTAssertNotNil(viewModel.layoutState)
        XCTAssertEqual(events.first?.eventType, .SignalImpression)
        XCTAssertEqual(events.first?.parentGuid, "Slot1")
        XCTAssertEqual(events.first?.jwtToken, "JwtToken0")
    }
    
    func test_creative_impression_event() throws {
        // Arrange
        let viewModel = getDistributionViewModel(eventService: eventService, layoutState: layoutState)

        // Act
        viewModel.sendCreativeImpressionEvent(currentOffer: 0)

        // Assert
        XCTAssertEqual(events.first?.eventType, .SignalImpression)
        XCTAssertEqual(events.first?.parentGuid, "instanceGuid")
        XCTAssertEqual(events.first?.jwtToken, "jwtToken1")
    }
    
    func test_dismissal_no_more_offer_event() throws {
        // Arrange
        let viewModel = getDistributionViewModel(eventService: eventService, layoutState: layoutState)

        // Act
        viewModel.sendDismissalNoMoreOfferEvent()

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalDismissal)
        XCTAssertEqual(event?.parentGuid, "pluginInstanceGuid")
        XCTAssertEqual(event?.jwtToken, "plugin-config-token")
        XCTAssertNotNil(event?.metadata.first{$0.name == kInitiator})
        XCTAssertNotNil(event?.metadata.first{$0.value == kNoMoreOfferToShow})
    }
    
    func test_dismissal_collapsed_event() throws {
        // Arrange
        let viewModel = getDistributionViewModel(eventService: eventService, layoutState: layoutState)

        // Act
        viewModel.sendDismissalCollapsedEvent()

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalDismissal)
        XCTAssertEqual(event?.parentGuid, "pluginInstanceGuid")
        XCTAssertEqual(event?.jwtToken, "plugin-config-token")
        XCTAssertNotNil(event?.metadata.first{$0.name == kInitiator})
        XCTAssertNotNil(event?.metadata.first{$0.value == kCollapsed})
    }

    private func getDistributionViewModel(
        eventService: EventService,
        layoutState: LayoutState = LayoutState()
    ) -> DistributionViewModel {
        DistributionViewModel(
            eventService: eventService,
            slots: [getSlot()],
            layoutState: layoutState
        )
    }
    
    private func getSlot() -> SlotModel {
        SlotModel(
            instanceGuid: "Slot1",
            offer: OfferModel(
                campaignId: "Campaign1",
                creative: CreativeModel(
                    referralCreativeId: "referralCreativeId1",
                    instanceGuid: "instanceGuid",
                    copy: [String: String](),
                    images: nil,
                    links: nil,
                    responseOptionsMap: nil,
                    jwtToken: "jwtToken1"
                )
            ),
            layoutVariant: nil,
            jwtToken: "JwtToken0"
        )
    }
}
