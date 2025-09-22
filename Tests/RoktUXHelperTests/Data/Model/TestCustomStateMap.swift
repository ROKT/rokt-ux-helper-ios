//
//  TestCustomStateMap.swift
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

class CustomStateMapTests: XCTestCase {

    func testToggleValueFor_existingKey() {
        var customStateMap: RoktUXCustomStateMap = [CustomStateIdentifiable(position: 1, key: "testKey"): 1]
        let customStateId = CustomStateIdentifiable(position: 1, key: "testKey")
        
        customStateMap = customStateMap.toggleValueFor(customStateId)
        
        XCTAssertEqual(customStateMap[customStateId], 0)
    }
    
    func testToggleValueFor_nonExistingKey() {
        var customStateMap: RoktUXCustomStateMap = [:]
        let customStateId = CustomStateIdentifiable(position: 1, key: "testKey")
        
        customStateMap = customStateMap.toggleValueFor(customStateId)
        
        XCTAssertEqual(customStateMap[customStateId], 1)
    }
    
    func testToggleValueFor_invalidKey() {
        var customStateMap: RoktUXCustomStateMap = [CustomStateIdentifiable(position: 1, key: "testKey"): 1]
        
        customStateMap = customStateMap.toggleValueFor(nil)
        
        XCTAssertEqual(customStateMap[CustomStateIdentifiable(position: 1, key: "testKey")], 1)
    }
    
    func testProcessTimerEvent_existingKey() {
        let key = CustomStateIdentifiable(position: 1, key: "testKey")
        var customStateMap: RoktUXCustomStateMap = [key: 0]
        
        let event = TimerEvent(position: 1, value: 1, key: "testKey")
        customStateMap = customStateMap.processTimerEvent(event)
        
        XCTAssertEqual(customStateMap[key], 1)
    }
    
    func testProcessTimerEvent_nonExistingKey() {
        let key = CustomStateIdentifiable(position: 1, key: "testKey")
        var customStateMap: RoktUXCustomStateMap = [key: 0]
        
        let event = TimerEvent(position: 1, value: 1, key: "testKey1")
        customStateMap = customStateMap.processTimerEvent(event)
        
        XCTAssertEqual(customStateMap[key], 0)
    }
    
    func testProcessTimerEvent_notTimerEvent() {
        let key = CustomStateIdentifiable(position: 1, key: "testKey")
        var customStateMap: RoktUXCustomStateMap = [key: 0]
        
        customStateMap = customStateMap.processTimerEvent("event")
        
        XCTAssertEqual(customStateMap[key], 0)
    }
    
    func testProcessTimerEvent_timerEventHasNoValue() {
        let key = CustomStateIdentifiable(position: 1, key: "testKey")
        var customStateMap: RoktUXCustomStateMap = [key: 1]
        
        let event = TimerEvent(position: 1, value: nil, key: "testKey")
        customStateMap = customStateMap.processTimerEvent(event)
        
        XCTAssertEqual(customStateMap[key], 0)
    }
}
