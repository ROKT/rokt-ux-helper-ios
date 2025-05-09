//
//  RoktUXRealTimeEventResponseTest.swift
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

class RoktUXRealTimeEventResponseTest: XCTestCase {

    func testInitialization_withAllValidParameters_succeeds() {
        let event = RoktUXRealTimeEventResponse(
            triggerGuid: "guid",
            triggerEvent: "event",
            eventType: "type",
            payload: "payload"
        )
        XCTAssertNotNil(event)
        XCTAssertEqual(event.triggerGuid, "guid")
        XCTAssertEqual(event.triggerEvent, "event")
        XCTAssertEqual(event.eventType, "type")
        XCTAssertEqual(event.payload, "payload")
    }

    func testIsValid_whenAllPropertiesAreNonNil_returnsTrue() {
        let event = RoktUXRealTimeEventResponse(
            triggerGuid: "guid",
            triggerEvent: "event",
            eventType: "type",
            payload: "payload"
        )
        XCTAssertTrue(event.isValid())
    }

    func testIsValid_whenTriggerGuidIsNil_returnsFalse() {
        let event = RoktUXRealTimeEventResponse(
            triggerGuid: nil,
            triggerEvent: "event",
            eventType: "type",
            payload: "payload"
        )
        XCTAssertFalse(event.isValid())
    }

    func testIsValid_whenTriggerEventIsNil_returnsFalse() {
        let event = RoktUXRealTimeEventResponse(
            triggerGuid: "guid",
            triggerEvent: nil,
            eventType: "type",
            payload: "payload"
        )
        XCTAssertFalse(event.isValid())
    }

    func testIsValid_whenEventTypeIsNil_returnsFalse() {
        let event = RoktUXRealTimeEventResponse(
            triggerGuid: "guid",
            triggerEvent: "event",
            eventType: nil,
            payload: "payload"
        )
        XCTAssertFalse(event.isValid())
    }

    func testIsValid_whenPayloadIsNil_returnsFalse() {
        let event = RoktUXRealTimeEventResponse(
            triggerGuid: "guid",
            triggerEvent: "event",
            eventType: "type",
            payload: nil
        )
        XCTAssertFalse(event.isValid())
    }

    func testIsValid_whenMultiplePropertiesAreNil_returnsFalse() {
        let event = RoktUXRealTimeEventResponse(
            triggerGuid: nil,
            triggerEvent: "event",
            eventType: nil,
            payload: "payload"
        )
        XCTAssertFalse(event.isValid())
    }
}
