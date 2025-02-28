//
//  TestCollectionExtension.swift
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

class TestCollectionExtension: XCTestCase {

    func testSafeAccess() {
        var array = [0]
        XCTAssertEqual(array[safe: 0], 0)
        XCTAssertEqual(array.count, 1)

        array = [1, 2]
        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertEqual(array[safe: 1], 2)
        XCTAssertEqual(array.count, 2)

        array = [3, 4, 5]
        XCTAssertEqual(array[safe: 0], 3)
        XCTAssertEqual(array[safe: 2], 5)
        XCTAssertEqual(array.count, 3)
    }

    func testOutOfBounds() {
        var array: [Int] = []
        XCTAssertNil(array[safe: 0])

        array = [1]
        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertNil(array[safe: 1])
        XCTAssertNil(array[safe: 5])

        array = [2, 3]
        XCTAssertEqual(array[safe: 1], 3)
        XCTAssertNil(array[safe: 2])
        XCTAssertNil(array[safe: -1])
    }
}
