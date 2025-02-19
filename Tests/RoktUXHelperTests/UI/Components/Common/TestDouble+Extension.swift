//
//  TestDouble+Extension.swift
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

class TestDoubleExtension: XCTestCase {

    func testEqualWithoutPrecision() {
        XCTAssertTrue(Double.equal(1.0, 1.0))
        XCTAssertFalse(Double.equal(1.0, 2.0))
    }

    func testEqualWithPrecision() {
        XCTAssertTrue(Double.equal(1.12345, 1.12346, precise: 4))
        XCTAssertFalse(Double.equal(1.12345, 1.12346, precise: 5))
    }

    func testPrecised() {
        XCTAssertEqual(1.12345.precised(2), 1.12)
        XCTAssertEqual(1.12345.precised(3), 1.123)
        XCTAssertEqual(1.12345.precised(4), 1.1235)
    }
}
