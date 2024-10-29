//
//  BNFPlaceholderValidatorTests.swift
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

final class BNFPlaceholderValidatorTests: XCTestCase {
    var sut: BNFPlaceholderValidator? = BNFPlaceholderValidator()

    override func setUp() {
        super.setUp()

        sut = BNFPlaceholderValidator()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test_isValid_withValidCreativeCopyPayload_returnsTrue() {
        let str = "DATA.creativeCopy.title"

        XCTAssertEqual(sut?.isValid(data: str), true)
    }

    func test_isValid_withValidCreativeResponsePayload_returnsTrue() {
        let str = "DATA.creativeResponse.title"

        XCTAssertEqual(sut?.isValid(data: str), true)
    }

    func test_isValid_withSingleValueNoNamespace_returnsFalse() {
        let str = "creative.title"

        XCTAssertEqual(sut?.isValid(data: str), false)
    }

    func test_isValid_withInvalidNamespace_returnsFalse() {
        let str = "DATAT.creative.title"

        XCTAssertEqual(sut?.isValid(data: str), false)
    }

    func test_isValid_withMultipleValidBindings_returnsTrue() {
        let str = "DATA.creativeResponse.title|DATA.creativeCopy.creative.copy"

        XCTAssertEqual(sut?.isValid(data: str), true)
    }

    func test_isValid_withMultipleValidBindingsAndDefaultValue_returnsTrue() {
        let str = "DATA.creativeResponse.title|DATA.creativeCopy.creative.copy|Are you ready to party"

        XCTAssertEqual(sut?.isValid(data: str), true)
    }
}
