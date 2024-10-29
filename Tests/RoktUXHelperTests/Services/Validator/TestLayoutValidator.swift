//
//  TestLayoutValidator.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
@testable import RoktUXHelper

final class TestLayoutValidator: XCTestCase {

    func test_isValidColor() throws {
        XCTAssertTrue(LayoutValidator.isValidColor("#111111"))
        XCTAssertTrue(LayoutValidator.isValidColor("#AA123123"))
        XCTAssertTrue(LayoutValidator.isValidColor("#FBC"))

        XCTAssertFalse(LayoutValidator.isValidColor("123123"))
        XCTAssertFalse(LayoutValidator.isValidColor("#MMMMMM"))
        XCTAssertFalse(LayoutValidator.isValidColor("234"))
        XCTAssertFalse(LayoutValidator.isValidColor("#Colors"))
    }
}
