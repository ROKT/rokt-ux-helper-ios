//
//  TestHeightModifier.swift
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

@available(iOS 15, *)
final class TestHeightModifier: XCTestCase {
    
    func test_height_set_wrap_content() {
        // Verifies that frameMaxHeight set to nil when fit = wrapContent & defaultHeight = fitHeight
        let heightProperty = DimensionHeightValue.fit(.wrapContent)
        
        let heightModifier = HeightModifier(heightProperty: heightProperty,
                                            minimum: nil,
                                            maximum: nil,
                                            alignment: nil,
                                            defaultHeight: .fitHeight,
                                            parentHeight: CGFloat(100))
        XCTAssertEqual(heightModifier.frameMinHeight, CGFloat.zero)
        XCTAssertNil(heightModifier.frameMaxHeight)
    }
    
    func test_height_set_fit_height() {
        let heightProperty = DimensionHeightValue.fit(.fitHeight)
        
        let heightModifier = HeightModifier(heightProperty: heightProperty,
                                            minimum: nil,
                                            maximum: nil,
                                            alignment: nil,
                                            defaultHeight: .fitHeight,
                                            parentHeight: CGFloat(100))
        XCTAssertNil(heightModifier.frameMinHeight)
        XCTAssertEqual(heightModifier.frameMaxHeight, CGFloat(100))
    }
    
    func test_height_default_fit_height() {
        
        let heightModifier = HeightModifier(heightProperty: nil,
                                            minimum: nil,
                                            maximum: nil,
                                            alignment: nil,
                                            defaultHeight: .fitHeight,
                                            parentHeight: CGFloat(100))
        XCTAssertNil(heightModifier.frameMinHeight)
        XCTAssertEqual(heightModifier.frameMaxHeight, CGFloat(100))
    }

}
