//
//  BNFDataSanitiserTests.swift
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

final class BNFDataSanitiserTests: XCTestCase {
    var sut: BNFDataSanitiser!

    override func setUp() {
        super.setUp()

        sut = BNFDataSanitiser()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test_sanitiseDelimiters_withDelimiters_returnsSanitisedString() {
        XCTAssertEqual(sut.sanitiseDelimiters(data: "%^hElLO WORLD!^%"), "hElLO WORLD!")
    }

    func test_sanitiseDelimiters_withoutDelimiters_returnsUnchangedInput() {
        XCTAssertEqual(sut.sanitiseDelimiters(data: "hElLO WORLD!"), "hElLO WORLD!")
    }

    func test_sanitiseNamespace_withNamespace_returnsSanitisedString() {
        XCTAssertEqual(sut.sanitiseNamespace(data: "DATA.creativeCopy.creative.copy", namespace: .dataCreativeCopy), "creative.copy")
        XCTAssertEqual(sut.sanitiseNamespace(data: "DATA.creativeResponse.creative.copy", namespace: .dataCreativeResponse), "creative.copy")
        XCTAssertEqual(sut.sanitiseNamespace(data: "STATE.creative.title", namespace: .state), "creative.title")
    }

    func test_sanitiseNamespace_withoutNamespace_returnsUnchangedInput() {
        XCTAssertEqual(sut.sanitiseNamespace(data: "rokt.creative.copy", namespace: .dataCreativeCopy), "rokt.creative.copy")
        XCTAssertEqual(sut.sanitiseNamespace(data: "rokt.creative.title", namespace: .state), "rokt.creative.title")
    }
}
