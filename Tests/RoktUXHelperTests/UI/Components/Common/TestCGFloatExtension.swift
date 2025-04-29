//
//  TestCGFloatExtension.swift
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

class TestCGFloatExtension: XCTestCase {

    func testPrecisionAddition() {
        let a: CGFloat = 1.923, b: CGFloat = 59.240, c: CGFloat = 61.163
        XCTAssertEqual((a + b).precised(), c.precised())
    }

    func testPrecised() {
        XCTAssertEqual(CGFloat(1.12345).precised(2), 1.12)
        XCTAssertEqual(CGFloat(1.12345).precised(3), 1.123)
        XCTAssertEqual(CGFloat(1.12345).precised(4), 1.1235)
    }
}
