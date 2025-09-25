//
//  TestToggleButtonComponent.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
import SwiftUI
import ViewInspector
@testable import RoktUXHelper
import DcuiSchema
import Combine

@available(iOS 15.0, *)
final class TestTimerStateTriggerComponent: XCTestCase {

    func test_initialization() throws {
        let model = TimerStateTriggerViewModel(model: .init(customStateKey: "test", delay: 1.0, value: 1), actionCollection: nil)
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.timerStateTrigger(model))
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(TimerStateTriggerComponent.self)
            .actualView()

        XCTAssertNotNil(sut)
    }

    func test_modelConvertsEmptyValuesToDefaults() {
        let model = TimerStateTriggerViewModel(
            model: .init(customStateKey: "test", delay: nil, value: nil),
            actionCollection: nil
        )
        XCTAssertEqual(model.delay, 0.0)
        XCTAssertEqual(model.value, 0)
    }

    func test_modelConvertsMilisecondsToSeconds() {
        let model = TimerStateTriggerViewModel(
            model: .init(customStateKey: "test", delay: 1000.0, value: nil),
            actionCollection: nil
        )
        XCTAssertEqual(model.delay, 1.0)
        XCTAssertEqual(model.value, 0)
    }
    
    func test_modelSendEvent() {
        let expectation = XCTestExpectation()
        let mock = MockActionCollecting()
        mock.map[.triggerTimer] = { event in
            let timerEvent = event as? TimerEvent
            XCTAssertEqual(timerEvent?.key, "test")
            XCTAssertEqual(timerEvent?.value, 0)
            XCTAssertEqual(timerEvent?.position, 1)
            expectation.fulfill()
        }
        let model = TimerStateTriggerViewModel(
            model: .init(customStateKey: "test", delay: 1000.0, value: nil),
            actionCollection: mock
        )
        model.sendEvent(for: 1)
        wait(for: [expectation])
    }
}
