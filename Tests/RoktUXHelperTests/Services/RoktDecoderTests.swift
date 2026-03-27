//
//  RoktDecoderTests.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
@testable import RoktUXHelper

@available(iOS 13, *)
final class RoktDecoderTests: XCTestCase {

    func test_decode_withValidJSONString_returnsDecodedModel() throws {
        struct Fixture: Codable, Equatable {
            let name: String
            let count: Int
        }

        let sut = RoktDecoder()

        let decoded = try sut.decode(Fixture.self, #"{"name":"catalog","count":2}"#)

        XCTAssertEqual(decoded, Fixture(name: "catalog", count: 2))
    }

    func test_decode_withInvalidJSONString_throws() {
        struct Fixture: Codable {
            let name: String
        }

        let sut = RoktDecoder()

        XCTAssertThrowsError(try sut.decode(Fixture.self, #"{"name":}"#))
    }
}
