//
//  TestRoktEmbeddedViewModel.swift
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

@available(iOS 15, *)
final class TestRoktEmbeddedViewModel: XCTestCase {
    var events = [EventRequest]()
    var stubUXHelper: MockUXHelper!
    let startDate = Date()
    
    override func setUpWithError() throws {
        events = [EventRequest]()
        self.stubUXHelper = MockUXHelper()
    }
    
    func test_plugin_impression_event() throws {
        // Arrange
        let viewModel = get_model(eventHandler: { event in
            self.events.append(event)
        })
        
        // Act
        viewModel.sendOnLoadEvents()
        
        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalImpression)
        XCTAssertNotNil(event?.metadata.first{$0.name == BE_PAGE_SIGNAL_LOAD})
        XCTAssertNotNil(event?.metadata.first{$0.value == EventDateFormatter.getDateString(startDate)})
        XCTAssertNotNil(event?.metadata.first{$0.name == BE_PAGE_RENDER_ENGINE})
        XCTAssertNotNil(event?.metadata.first{$0.value == BE_RENDER_ENGINE_LAYOUTS})
        
    }
    
    func test_plugin_activation_event() throws {
        // Arrange
        let viewModel = get_model(eventHandler: { event in
            self.events.append(event)
        })
        // Act
        viewModel.sendSignalActivationEvent()
        
        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalActivation)
        XCTAssertEqual(event?.parentGuid, mockPluginInstanceGuid)
        XCTAssertEqual(event?.jwtToken, mockPluginConfigJWTToken)
    }
    
    func get_model(eventHandler: @escaping (EventRequest) -> Void) -> RoktEmbeddedViewModel {
        let eventService = EventService(
            pageId: nil,
            pageInstanceGuid: mockPageInstanceGuid,
            sessionId: "",
            pluginInstanceGuid: mockPluginInstanceGuid,
            pluginId: nil,
            pluginName: nil,
            startDate: startDate,
            uxEventDelegate: MockUXHelper(),
            processor: MockEventProcessor(handler: eventHandler),
            responseReceivedDate: Date(),
            pluginConfigJWTToken: mockPluginConfigJWTToken,
            useDiagnosticEvents: false
        )
        return RoktEmbeddedViewModel(layouts: [],
                                     eventService: eventService,
                                     layoutState: LayoutState())
    }
}
