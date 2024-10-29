//
//  BNFSeparatorTests.swift
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

final class BNFSeparatorTests: XCTestCase {
    func test_charCount_shouldReturnPerDelimiter() {
        XCTAssertEqual(BNFSeparator.startDelimiter.charCount, 2)
        XCTAssertEqual(BNFSeparator.endDelimiter.charCount, 2)
        XCTAssertEqual(BNFSeparator.namespace.charCount, 1)
        XCTAssertEqual(BNFSeparator.alternative.charCount, 1)
    }
}
