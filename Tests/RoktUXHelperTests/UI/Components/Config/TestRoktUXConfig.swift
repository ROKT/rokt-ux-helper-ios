//
//  TestRoktUXConfig.swift
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

class RoktUXConfigTests: XCTestCase {

    func testDefaultConfig() {
        let config = RoktUXConfig.Builder().build()
        XCTAssertEqual(config.colorMode, .system)
        XCTAssertNil(config.imageLoader)
        XCTAssertEqual(config.logLevel, .none)
    }

    func testCustomColorMode() {
        let config = RoktUXConfig.Builder()
            .colorMode(.dark)
            .build()
        XCTAssertEqual(config.colorMode, .dark)
    }

    func testCustomImageLoader() {
        let mockImageLoader = MockImageLoader()
        let config = RoktUXConfig.Builder()
            .imageLoader(mockImageLoader)
            .build()
        XCTAssertNotNil(config.imageLoader)
        XCTAssertTrue(config.imageLoader === mockImageLoader)
    }

    func testLogLevel() {
        let config = RoktUXConfig.Builder()
            .logLevel(.debug)
            .build()
        XCTAssertEqual(config.logLevel, .debug)
    }

    func testLogLevelVerbose() {
        let config = RoktUXConfig.Builder()
            .logLevel(.verbose)
            .build()
        XCTAssertEqual(config.logLevel, .verbose)
    }

    func testDeprecatedEnableLogging() {
        let config = RoktUXConfig.Builder()
            .enableLogging(true)
            .build()
        XCTAssertEqual(config.logLevel, .debug)
    }

    func testDeprecatedEnableLoggingFalse() {
        let config = RoktUXConfig.Builder()
            .enableLogging(false)
            .build()
        XCTAssertEqual(config.logLevel, .none)
    }
}

class MockImageLoader: RoktUXImageLoader {
    func loadImage(urlString: String, completion: @escaping (Result<UIImage?, Error>) -> Void) {
        completion(.success(nil))
    }
}
