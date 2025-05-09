//
//  RoktUXPlacementResponseTest.swift
//  RoktUXHelper
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

class RoktUXPlacementResponseTest: XCTestCase {

    let mockPlacementContext = RoktUXPlacementContext(name: "testContext", version: "1", type: "type", step: "step")
    let mockPlacement = RoktUXPlacement(placementGuid: "pGuid", creatives: [], selectedCreative: nil, views: [])

    func testDecoding_eventData_withMultipleEvents_succeeds() throws {
        let jsonString = """
        {
            "sessionId": "s1",
            "placementContext": { "roktTagId": "1234", "pageInstanceGuid": "1234", "token": "1234" },
            "placements": [], "token": "tkn",
            "eventData": {
                "guid1": {
                    "events": {
                        "SignalA": { "eventType": "TypeA", "payload": "PayloadA" },
                        "SignalB": { "eventType": "TypeB", "payload": "PayloadB" }
                    }
                },
                "guid2": {
                    "events": {
                        "SignalC": { "eventType": "TypeC", "payload": "PayloadC" }
                    }
                }
            }
        }
        """
        let jsonData = Data(jsonString.utf8)
        let response = try JSONDecoder().decode(RoktUXPlacementResponse.self, from: jsonData)

        XCTAssertEqual(response.eventData.count, 3)
        // Note: Order is not guaranteed in dictionary iteration, so we sort or check for presence
        XCTAssertTrue(response.eventData.contains { $0.triggerGuid == "guid1" && $0.triggerEvent == "SignalA" })
        XCTAssertTrue(response.eventData.contains { $0.triggerGuid == "guid1" && $0.triggerEvent == "SignalB" })
        XCTAssertTrue(response.eventData.contains { $0.triggerGuid == "guid2" && $0.triggerEvent == "SignalC" })
    }

    func testDecoding_eventData_entryWithNoEventsField_isSkipped() throws {
        let jsonString = """
        {
            "sessionId": "s1",
            "placementContext": { "roktTagId": "1234", "pageInstanceGuid": "1234", "token": "1234" },
            "placements": [], "token": "tkn",
            "eventData": {
                "guid1": {  },
                "guid2": {
                    "events": {
                        "SignalC": { "eventType": "TypeC", "payload": "PayloadC" }
                    }
                }
            }
        }
        """
        let jsonData = Data(jsonString.utf8)
        let response = try JSONDecoder().decode(RoktUXPlacementResponse.self, from: jsonData)

        XCTAssertEqual(response.eventData.count, 1)
        XCTAssertEqual(response.eventData.first?.triggerGuid, "guid2")
        XCTAssertEqual(response.eventData.first?.triggerEvent, "SignalC")
    }

    func testDecoding_eventData_entryWithEmptyEventsObject_isSkipped() throws {
        let jsonString = """
        {
            "sessionId": "s1",
            "placementContext": { "roktTagId": "1234", "pageInstanceGuid": "1234", "token": "1234" },
            "placements": [], "token": "tkn",
            "eventData": {
                "guid1": {
                    "events": {}
                },
                "guid2": {
                    "events": {
                        "SignalC": { "eventType": "TypeC", "payload": "PayloadC" }
                    }
                }
            }
        }
        """
        let jsonData = Data(jsonString.utf8)
        let response = try JSONDecoder().decode(RoktUXPlacementResponse.self, from: jsonData)

        XCTAssertEqual(response.eventData.count, 1)
        XCTAssertEqual(response.eventData.first?.triggerGuid, "guid2")
    }

    func testDecoding_eventData_completelyEmpty_resultsInEmptyEventDataArray() throws {
        let jsonString = """
        {
            "sessionId": "s1",
            "placementContext": { "roktTagId": "1234", "pageInstanceGuid": "1234", "token": "1234" },
            "placements": [],
            "token": "tkn",
            "eventData": {}
        }
        """
        let jsonData = Data(jsonString.utf8)
        let response = try JSONDecoder().decode(RoktUXPlacementResponse.self, from: jsonData)
        XCTAssertTrue(response.eventData.isEmpty)
    }
}

struct RoktUXPlacementContext: Decodable, Equatable {
    let name: String
    let version: String
    let type: String
    let step: String
}

struct RoktUXPlacement: Decodable, Equatable {
    let placementGuid: String
    let creatives: [String?]
    let selectedCreative: String?
    let views: [String?]
}
