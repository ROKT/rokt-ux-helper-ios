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
        XCTAssertFalse(config.loggingEnabled)
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

    func testEnableLogging() {
        let config = RoktUXConfig.Builder()
            .enableLogging(true)
            .build()
        XCTAssertTrue(config.loggingEnabled)
    }
}

class MockImageLoader: RoktUXImageLoader {
    func loadImage(urlString: String, completion: @escaping (Result<UIImage?, Error>) -> Void) {
        completion(.success(nil))
    }
}
