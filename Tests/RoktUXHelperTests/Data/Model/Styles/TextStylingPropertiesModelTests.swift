//
//  TextStylingPropertiesModelTests.swift
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

@available(iOS 13, *)
final class TestTextStyleModel: XCTestCase {

    func test_get_baseline_offset_form_superscript() {
        // Arrang
        guard let font = UIFont(name: "Arial", size: 18) else {
            XCTFail()
            return
        }
        let textStylingProperties = TextStylingProperties(textColor: nil, fontSize: 18, fontFamily: "Arial", fontWeight: .w100, lineHeight: nil, horizontalTextAlign: nil, baselineTextAlign: .super, fontStyle: nil, textTransform: nil, letterSpacing: nil, textDecoration: nil, lineLimit: nil)
        // Act
        let baseline = textStylingProperties.baselineOffset
        // Assert
        XCTAssertEqual(baseline, font.ascender * 0.5)
    }

    func test_get_baseline_offset_form_subscript() {
        // Arrang
        guard let font = UIFont(name: "Arial", size: 18) else {
            XCTFail()
            return
        }
        let textStylingProperties = TextStylingProperties(textColor: nil, fontSize: 18, fontFamily: "Arial", fontWeight: nil, lineHeight: nil, horizontalTextAlign: nil, baselineTextAlign: .sub, fontStyle: nil, textTransform: nil, letterSpacing: nil, textDecoration: nil, lineLimit: nil)
        // Act
        let baseline = textStylingProperties.baselineOffset
        // Assert
        XCTAssertEqual(baseline, font.ascender * -0.5)
    }

}
