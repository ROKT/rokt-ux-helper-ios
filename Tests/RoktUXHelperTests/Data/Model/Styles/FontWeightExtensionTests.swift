//
//  FontWeightExtensionTests.swift
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
import DcuiSchema

final class FontWeightExtensionTests: XCTestCase {
    func test_asUIFontWeight_shouldReturnDistinctWeight() {
        XCTAssertEqual(FontWeight.w100.asUIFontWeight, .thin)
        XCTAssertEqual(FontWeight.w200.asUIFontWeight, .ultraLight)
        XCTAssertEqual(FontWeight.w300.asUIFontWeight, .light)
        XCTAssertEqual(FontWeight.w400.asUIFontWeight, .regular)
        XCTAssertEqual(FontWeight.w500.asUIFontWeight, .medium)
        XCTAssertEqual(FontWeight.w600.asUIFontWeight, .semibold)
        XCTAssertEqual(FontWeight.w700.asUIFontWeight, .bold)
        XCTAssertEqual(FontWeight.w800.asUIFontWeight, .heavy)
        XCTAssertEqual(FontWeight.w900.asUIFontWeight, .black)
    }
}
