//
//  TestRoktUXLogger.swift
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

class RoktUXLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        RoktUXLogger.shared.logLevel = .none
    }

    override func tearDown() {
        RoktUXLogger.shared.logLevel = .none
        super.tearDown()
    }

    func testDefaultLogLevelIsNone() {
        let logger = RoktUXLogger.shared
        logger.logLevel = .none
        XCTAssertEqual(logger.logLevel, .none)
    }

    func testLogLevelCanBeSet() {
        let logger = RoktUXLogger.shared
        logger.logLevel = .debug
        XCTAssertEqual(logger.logLevel, .debug)

        logger.logLevel = .verbose
        XCTAssertEqual(logger.logLevel, .verbose)

        logger.logLevel = .error
        XCTAssertEqual(logger.logLevel, .error)
    }

    func testSharedInstanceIsSingleton() {
        let logger1 = RoktUXLogger.shared
        let logger2 = RoktUXLogger.shared
        XCTAssertTrue(logger1 === logger2)
    }

    @available(iOS 15, *)
    func testSetLogLevelViaPublicAPI() {
        RoktUX.setLogLevel(.warning)
        XCTAssertEqual(RoktUXLogger.shared.logLevel, .warning)
    }
}

class RoktUXLogLevelTests: XCTestCase {

    func testLogLevelOrdering() {
        XCTAssertTrue(RoktUXLogLevel.verbose < RoktUXLogLevel.debug)
        XCTAssertTrue(RoktUXLogLevel.debug < RoktUXLogLevel.info)
        XCTAssertTrue(RoktUXLogLevel.info < RoktUXLogLevel.warning)
        XCTAssertTrue(RoktUXLogLevel.warning < RoktUXLogLevel.error)
        XCTAssertTrue(RoktUXLogLevel.error < RoktUXLogLevel.none)
    }

    func testLogLevelRawValues() {
        XCTAssertEqual(RoktUXLogLevel.verbose.rawValue, 0)
        XCTAssertEqual(RoktUXLogLevel.debug.rawValue, 1)
        XCTAssertEqual(RoktUXLogLevel.info.rawValue, 2)
        XCTAssertEqual(RoktUXLogLevel.warning.rawValue, 3)
        XCTAssertEqual(RoktUXLogLevel.error.rawValue, 4)
        XCTAssertEqual(RoktUXLogLevel.none.rawValue, 5)
    }

    func testLogLevelLabels() {
        XCTAssertEqual(RoktUXLogLevel.verbose.label, "VERBOSE")
        XCTAssertEqual(RoktUXLogLevel.debug.label, "DEBUG")
        XCTAssertEqual(RoktUXLogLevel.info.label, "INFO")
        XCTAssertEqual(RoktUXLogLevel.warning.label, "WARNING")
        XCTAssertEqual(RoktUXLogLevel.error.label, "ERROR")
        XCTAssertEqual(RoktUXLogLevel.none.label, "NONE")
    }

    func testLogLevelComparable() {
        XCTAssertTrue(RoktUXLogLevel.verbose <= RoktUXLogLevel.verbose)
        XCTAssertTrue(RoktUXLogLevel.verbose <= RoktUXLogLevel.debug)
        XCTAssertFalse(RoktUXLogLevel.error <= RoktUXLogLevel.debug)
    }

    func testLogLevelEquality() {
        XCTAssertEqual(RoktUXLogLevel.debug, RoktUXLogLevel.debug)
        XCTAssertNotEqual(RoktUXLogLevel.debug, RoktUXLogLevel.info)
    }
}
