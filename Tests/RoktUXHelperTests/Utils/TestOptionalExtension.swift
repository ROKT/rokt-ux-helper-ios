//
//  TestOptionalExtension.swift
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

class TestOptionalExtension: XCTestCase {

    enum TestError: Error {
        case unwrappingFailed
    }

    func testUnwrapSuccess() {
        let optionalValue: Int? = 42
        do {
            let value = try optionalValue.unwrap(orThrow: TestError.unwrappingFailed)
            XCTAssertEqual(value, 42)
        } catch {
            XCTFail("Expected to unwrap successfully, but threw an error: \(error)")
        }
    }

    func testUnwrapFailure() {
        let optionalValue: Int? = nil
        do {
            _ = try optionalValue.unwrap(orThrow: TestError.unwrappingFailed)
            XCTFail("Expected to throw an error, but unwrapped successfully")
        } catch {
            XCTAssertEqual(error as? TestError, TestError.unwrappingFailed)
        }
    }
}
