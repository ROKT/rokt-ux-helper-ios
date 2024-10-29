//
//  TestCreativeResponseViewModel.swift
//  RoktUXHelperTests
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
final class TestCreativeResponseViewModel: XCTestCase {
    var events = [EventRequest]()
    var stubUXHelper: MockUXHelper!
    
    override func setUpWithError() throws {
        events = [EventRequest]()
        self.stubUXHelper = MockUXHelper()
    }
    
    func test_send_signal_impression_event() throws {
        // Arrange
        let viewModel = get_model(eventHandler: { event in
            self.events.append(event)
        })

        // Act
        viewModel.sendSignalResponseEvent()
        
        // Assert
        XCTAssertEqual(events.first?.eventType, .SignalResponse)
        XCTAssertEqual(events.first?.parentGuid, "creativeInstance")
        XCTAssertEqual(events.first?.jwtToken, "response-jwt")
    }
    
    func test_send_signal_gated_impression_event() throws {
        // Arrange
        let viewModel = get_model(signalType: .signalGatedResponse,
                                  eventHandler: { event in
            self.events.append(event)
        })
        
        // Act
        viewModel.sendSignalResponseEvent()
        
        // Assert
        XCTAssertEqual(events.first?.eventType, .SignalGatedResponse)
        XCTAssertEqual(events.first?.parentGuid, "creativeInstance")
        XCTAssertEqual(events.first?.jwtToken, "response-jwt")
    }
    
    func test_get_valid_url() throws {
        // Arrange
        let viewModel = get_model(url: "https://www.rokt.com",
                                  eventHandler: { event in
            self.events.append(event)
        })
        // Act
        let url = viewModel.getOfferUrl()
        // Assert
        XCTAssertEqual(url, URL(string: "https://www.rokt.com"))
    }
    
    func test_get_inavlid_url_nil() throws {
        // Arrange
        let viewModel = get_model(signalType: .signalGatedResponse,
                                  eventHandler: { event in
            self.events.append(event)
        })
        // Act
        let url = viewModel.getOfferUrl()
        // Assert
        XCTAssertNil(url)
    }
    
    func test_get_inavlid_url_nil_when_action_is_not_url() throws {
        // Arrange
        let viewModel = get_model(action: .captureOnly,
                                  eventHandler: { event in
            self.events.append(event)
        })
        // Act
        let url = viewModel.getOfferUrl()
        // Assert
        XCTAssertNil(url)
    }
    
    func get_model(signalType: SignalType = .signalResponse,
                   url: String? = nil,
                   action: Action = .url,
                   eventHandler: @escaping (EventRequest) -> Void) -> CreativeResponseViewModel {
        let eventService = EventService(
            pageId: nil,
            pageInstanceGuid: "",
            sessionId: "",
            pluginInstanceGuid: "",
            pluginId: nil,
            pluginName: nil,
            startDate: Date(),
            uxEventDelegate: MockUXHelper(),
            processor: MockEventProcessor(handler: eventHandler),
            responseReceivedDate: Date(),
            pluginConfigJWTToken: "",
            useDiagnosticEvents: false
        )
        return CreativeResponseViewModel(
            children: [],
            responseKey: .positive,
            responseOptions:
                ResponseOption(id: "",
                               action: action,
                               instanceGuid: "creativeInstance",
                               signalType: signalType,
                               shortLabel: "",
                               longLabel: "",
                               shortSuccessLabel: "",
                               isPositive: nil,
                               url: url,
                               responseJWTToken: "response-jwt"),
            openLinks: nil,
            layoutState: LayoutState(),
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil
        )
        
    }
}


