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
        let model = TimerStateTriggerViewModel(model: .init(customStateKey: "test", delay: 1.0, value: 1), layoutState: nil)
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
        let model = TimerStateTriggerViewModel(model: .init(customStateKey: "test", delay: nil, value: nil), layoutState: nil)
        XCTAssertEqual(model.delay, 0.0)
        XCTAssertEqual(model.value, 0)
    }

    func test_modelConvertsMilisecondsToSeconds() {
        let model = TimerStateTriggerViewModel(model: .init(customStateKey: "test", delay: 1000.0, value: nil), layoutState: nil)
        XCTAssertEqual(model.delay, 1.0)
        XCTAssertEqual(model.value, 0)
    }
}
