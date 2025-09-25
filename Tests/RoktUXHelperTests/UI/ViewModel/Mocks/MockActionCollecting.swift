//
//  MockActionCollecting.swift
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
import SwiftUI
import ViewInspector
@testable import RoktUXHelper
import DcuiSchema
import Combine

class MockActionCollecting: ActionCollecting {
    var map = [RoktActionType: ShareFunction]()
    
    subscript(actionType: RoktUXHelper.RoktActionType) -> ShareFunction {
        get {
            map[actionType] ?? { _ in }
        }
        set(newValue) {
            map[actionType] = newValue
        }
    }
    
    func reset() {
    }
}
