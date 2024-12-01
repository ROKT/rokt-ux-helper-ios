//
//  TestEventRequest.swift
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

class TestEventRequest: XCTestCase {

    func test_event_with_correct_session_id_and_parenet_guid_and_event_type_and_jwt_token() {
        let eventRequest = RoktEventRequest(
            sessionId: "sessionID",
            eventType: EventType.SignalImpression,
            parentGuid: "parentGuid",
            pageInstanceGuid: "page",
            jwtToken: "jwt-token"
        )
        
        XCTAssertEqual(eventRequest.sessionId, "sessionID")
        XCTAssertEqual(eventRequest.eventType, EventType.SignalImpression)
        XCTAssertEqual(eventRequest.parentGuid, "parentGuid")
        XCTAssertEqual(eventRequest.pageInstanceGuid, "page")
        XCTAssertEqual(eventRequest.jwtToken, "jwt-token")
    }
    
    func test_event_withoutJWTToken_returnsNil() {
        let eventRequest = RoktEventRequest(
            sessionId: "sessionID",
            eventType: EventType.SignalImpression,
            parentGuid: "parentGuid",
            pageInstanceGuid: "page",
            jwtToken: "jwt-token"
        )

        XCTAssertEqual(eventRequest.sessionId, "sessionID")
        XCTAssertEqual(eventRequest.eventType, EventType.SignalImpression)
        XCTAssertEqual(eventRequest.parentGuid, "parentGuid")
        XCTAssertEqual(eventRequest.pageInstanceGuid, "page")
    }

    func test_event_create_date() {
        let eventTime = Date()
        let eventRequest = RoktEventRequest(
            sessionId: "",
            eventType: EventType.SignalImpression,
            parentGuid: "",
            eventTime: eventTime,
            jwtToken: "jwt"
        )

        XCTAssertNotNil(eventRequest.metadata)
        XCTAssertNotNil(eventRequest.metadata[0])
        XCTAssertEqual(eventRequest.metadata[0].name, BE_CLIENT_TIME_STAMP)
        XCTAssertEqual(eventRequest.metadata[0].value, EventDateFormatter.getDateString(eventTime))
        XCTAssertNotNil(eventRequest.metadata[0].value)
    }

    func test_event_create_capture_method() {
        let eventRequest = RoktEventRequest(sessionId: "", eventType: EventType.SignalImpression, parentGuid: "", jwtToken: "jwt")

        XCTAssertNotNil(eventRequest.metadata[1])
        XCTAssertEqual(eventRequest.metadata[1].name, BE_CAPTURE_METHOD)
        XCTAssertEqual(eventRequest.metadata[1].value, kClientProvided)
    }

    func test_event_create_currect_time_stamp() {
        let eventRequest = RoktEventRequest(sessionId: "", eventType: EventType.SignalImpression, parentGuid: "", jwtToken: "jwt")
        let timeStampRegex = "^[0-9]{4}-[0-9]{2}-[0-9]{2}T([0-9]{2}:){2}[0-9]{2}.[0-9]{3}Z$"

        XCTAssertNotNil(eventRequest.metadata[0].value)
        XCTAssertTrue(matchesRegex(eventRequest.metadata[0].value, regex: timeStampRegex))
    }

    func test_event_get_params() {
        let eventRequest = RoktEventRequest(
            sessionId: "sessionID",
            eventType: EventType.SignalImpression,
            parentGuid: "parentGuid",
            pageInstanceGuid: "page",
            jwtToken: "jwt"
        )

        let params = eventRequest.getParams

        XCTAssertEqual(params[BE_SESSION_ID_KEY] as! String, "sessionID")
        XCTAssertEqual(params[BE_PARENT_GUID_KEY] as! String, "parentGuid")
        XCTAssertEqual(params[BE_PAGE_INSTANCE_GUID_KEY] as! String, "page")
        XCTAssertEqual(params[BE_EVENT_TYPE_KEY] as! String, EventType.SignalImpression.rawValue)
        XCTAssertNotNil(params[BE_EVENT_DATA_KEY])
        XCTAssertNotNil(params[BE_INSTANCE_GUID])
        XCTAssertNotNil(params[BE_METADATA_KEY])
    }

    func matchesRegex(_ text: String, regex: String) -> Bool {
        return text.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}
