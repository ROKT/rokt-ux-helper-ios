//
//  TestEventProcessor.swift
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

import Foundation
import Combine
import XCTest
@testable import RoktUXHelper

@available(iOS 13.0, *)
final class TestEventProcessor: XCTestCase {
    
    func testEvents() {
        let expectation = expectation(description: "test event types")
        let allEventTypes = EventType.allCases
        let date = Date()
        
        let sut = EventProcessor(integrationType: .sdk) { [weak self] payload in
            guard let self,
            let processedPayload: EventsPayload = deserialize(payload) else {
                XCTFail("fail unwrapping")
                return
            }
            
            XCTAssertEqual(processedPayload.integration.name, "UX Helper iOS")
            XCTAssertEqual(processedPayload.integration.framework, "Swift")
            XCTAssertEqual(processedPayload.integration.platform, "iOS")
            
            let processedRequests = processedPayload.events
            XCTAssertEqual(processedRequests.count, 12)
                
            allEventTypes.forEach { eventType in
                
                guard let request = try? XCTUnwrap(processedRequests.first(where: { $0.eventType == eventType })) else {
                    XCTFail("fail with unwrapping EventRequest")
                    return
                }
                XCTAssertEqual(request.eventData, [.init(name: "key", value: "value \(request.eventType.rawValue)")])
                let metaData = [
                    RoktEventNameValue(name: BE_CLIENT_TIME_STAMP,
                                       value: EventDateFormatter.getDateString(date)),
                    RoktEventNameValue(name: BE_CAPTURE_METHOD,
                                       value: kClientProvided),
                    RoktEventNameValue(name: "name",
                                       value: "meta \(request.eventType.rawValue)")
                ]
                XCTAssertEqual(request.metadata, metaData)
            }
            expectation.fulfill()
        }
        
        allEventTypes.forEach {
            sut.handle(
                event: mockEvent(
                    eventType: $0,
                    date: date,
                    extraMetadata: [.init(name: "name", value: "meta \($0.rawValue)")],
                    eventData: ["key": "value \($0.rawValue)"]
                )
            )
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testS2SEvents() {
        let expectation = expectation(description: "test s2s event types")
        let allEventTypes = EventType.allCases
        let date = Date()
        
        let sut = EventProcessor(integrationType: .s2s) { [weak self] payload in
            guard let self,
                  let processedPayload: EventsPayload = deserialize(payload) else {
                XCTFail("fail unwrapping")
                return
            }
            
            XCTAssertEqual(processedPayload.integration.name, "UX Helper iOS")
            XCTAssertEqual(processedPayload.integration.framework, "Swift")
            XCTAssertEqual(processedPayload.integration.platform, "iOS")
            
            let processedRequests = processedPayload.events
            XCTAssertEqual(processedRequests.count, 10)
            expectation.fulfill()
        }
        allEventTypes.forEach {
            sut.handle(
                event: mockEvent(
                    eventType: $0,
                    date: date,
                    extraMetadata: [.init(name: "name", value: "meta \($0.rawValue)")],
                    eventData: ["key": "value \($0.rawValue)"]
                )
            )
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testEventDelayProcessing() {
        var expectation = expectation(description: "wait")
        var receivedPayload: [RoktEventRequest]?
        let sut = EventProcessor(delay: 0.5) { [weak self] payload in
            guard let self else {
                XCTFail("Fail self")
                return
            }
            receivedPayload = deserialize(payload)?.events
            expectation.fulfill()
        }
        
        sut.handle(event: mockEvent(eventType: .SignalActivation, date: Date()))
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(receivedPayload?.count, 1)
        XCTAssertEqual(receivedPayload?.first?.eventType, .SignalActivation)
        
        expectation = XCTestExpectation(description: "wait again")
        sut.handle(event: mockEvent(eventType: .SignalViewed, date: Date()))
        microSleep(0.1)
        sut.handle(event: mockEvent(eventType: .SignalImpression, date: Date()))
        microSleep(0.1)
        sut.handle(event: mockEvent(eventType: .SignalResponse, date: Date()))
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(receivedPayload?.count, 3)
        XCTAssertEqual(receivedPayload?[0].eventType, .SignalViewed)
        XCTAssertEqual(receivedPayload?[1].eventType, .SignalImpression)
        XCTAssertEqual(receivedPayload?[2].eventType, .SignalResponse)
    }
    
    func testEventRemoveDuplicates() {
        let expectation = expectation(description: "test duplicates")
        var receivedPayload: [RoktEventRequest]?
        let sut = EventProcessor() { [weak self] payload in
            guard let self else {
                XCTFail("Fail self")
                return
            }
            receivedPayload = deserialize(payload)?.events
            expectation.fulfill()
        }
        let date = Date()
        sut.handle(event: mockEvent(eventType: .SignalViewed, date: date))
        sut.handle(event: mockEvent(eventType: .SignalViewed, date: date))
        sut.handle(event: mockEvent(eventType: .SignalViewed, date: date + 10))
        
        sut.handle(event: mockEvent(eventType: .SignalActivation, date: date, eventData: ["key": "value"]))
        sut.handle(event: mockEvent(eventType: .SignalActivation, date: date, eventData: ["key": "value"]))
        sut.handle(event: mockEvent(eventType: .SignalActivation, date: date, eventData: ["key2": "value2"]))
        
        sut.handle(event: mockEvent(eventType: .SignalResponse, date: date, extraMetadata: [.init(name: "name", value: "value")]))
        sut.handle(event: mockEvent(
            eventType: .SignalResponse,
            date: date,
            extraMetadata: [.init(name: "name2", value: "value2")]
        ))
        
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(receivedPayload?.count, 4)
        XCTAssertEqual(receivedPayload?[0].eventType, .SignalViewed)
        XCTAssertEqual(receivedPayload?[1].eventType, .SignalActivation)
        XCTAssertEqual(receivedPayload?[2].eventType, .SignalActivation)
        XCTAssertEqual(receivedPayload?[2].eventData, [.init(name: "key2", value: "value2")])
        
        XCTAssertEqual(receivedPayload?[3].eventType, .SignalResponse)
    }
    
    private func microSleep(_ seconds: Double) {
        usleep(useconds_t(Int32(seconds * 1000000)))
    }
    
    private func deserialize(_ events: [String: Any]) -> EventsPayload? {
        let data = try? JSONSerialization.data(withJSONObject: events, options: [])
        return data.flatMap { try? JSONDecoder().decode(EventsPayload.self, from: $0) }
    }
    
    private func mockEvent(
        eventType: EventType,
        date: Date,
        extraMetadata: [RoktEventNameValue] = [],
        eventData: [String: String] = [:]
    ) -> RoktEventRequest {
        .init(
            sessionId: "sessionId",
            eventType: eventType,
            parentGuid: "parentGuid",
            eventTime: date,
            extraMetadata: extraMetadata,
            eventData: eventData,
            pageInstanceGuid: "pageInstanceGuid",
            jwtToken: "token"
        )
    }
}
