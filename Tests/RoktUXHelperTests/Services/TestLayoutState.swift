//
//  TestLayoutState.swift
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


import Foundation
import XCTest
@testable import RoktUXHelper
import DcuiSchema

class TestLayoutState: XCTestCase {

    private var layoutState: LayoutState!

    func testReceiveUpdateWhenItemsChange() {
        layoutState = LayoutState()
        let expectation = expectation(description: "Test publisher")
        let _ = layoutState.itemsPublisher
            .dropFirst()
            .sink { newItems in
                XCTAssertEqual(newItems["test"] as? Int, 1)
                expectation.fulfill()
            }
        layoutState.items["test"] = 1
        wait(for: [expectation], timeout: 1)
    }

    func testUpdateLayoutType() {
        layoutState = LayoutState()
        let expectation = expectation(description: "Test layout type")
        let _ = layoutState.itemsPublisher
            .dropFirst()
            .sink { newItems in
                XCTAssertEqual(newItems[LayoutState.layoutType] as? RoktUXPlacementLayoutCode, .overlayLayout)
                expectation.fulfill()
            }
        layoutState.items[LayoutState.layoutType] = RoktUXPlacementLayoutCode.overlayLayout
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(layoutState.layoutType(), .overlayLayout)
    }

    func testCloseOnComplete() {
        layoutState = LayoutState()

        XCTAssertEqual(layoutState.closeOnComplete(), true)

        layoutState.items[LayoutState.layoutSettingsKey] = LayoutSettings(closeOnComplete: nil)
        XCTAssertEqual(layoutState.closeOnComplete(), true)

        layoutState.items[LayoutState.layoutSettingsKey] = LayoutSettings(closeOnComplete: false)
        XCTAssertEqual(layoutState.closeOnComplete(), false)

        layoutState.items[LayoutState.layoutSettingsKey] = LayoutSettings(closeOnComplete: true)
        XCTAssertEqual(layoutState.closeOnComplete(), true)
    }

    func testGlobalBreakpointIndex() {
        layoutState = LayoutState()
        layoutState.items[LayoutState.breakPointsSharedKey] = ["0": Float(100.0), "1": Float(200.0), "2": Float(300.0)]
        XCTAssertEqual(layoutState.getGlobalBreakpointIndex(50.0), 0)
        XCTAssertEqual(layoutState.getGlobalBreakpointIndex(150.0), 1)
        XCTAssertEqual(layoutState.getGlobalBreakpointIndex(250.0), 2)
        XCTAssertEqual(layoutState.getGlobalBreakpointIndex(350.0), 3)
        XCTAssertEqual(layoutState.getGlobalBreakpointIndex(450.0), 3)
    }
}
