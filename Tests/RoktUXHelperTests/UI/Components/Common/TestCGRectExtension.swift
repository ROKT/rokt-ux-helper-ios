//
//  TestCGRectExtension.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import XCTest
import SwiftUI
@testable import RoktUXHelper

@available(iOS 15, *)
class TestCGRectExtension: XCTestCase {

    func testIntersectPercentWithFrame_NoIntersection() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 200, y: 200, width: 50, height: 50)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 0.0, "Should return 0 when rectangles don't intersect")
    }

    func testIntersectPercentWithFrame_FullIntersection() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 0, y: 0, width: 100, height: 100)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 1.0, "Should return 1.0 when rectangles fully overlap")
    }

    func testIntersectPercentWithFrame_PartialIntersection() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 0, y: 0, width: 50, height: 50)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 0.25, "Should return 0.25 when rect2 is 1/4 the size of rect1")
    }

    func testIntersectPercentWithFrame_QuarterIntersection() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 50, y: 50, width: 50, height: 50)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 0.25, "Should return 0.25 when rect2 overlaps in bottom-right quarter")
    }

    func testIntersectPercentWithFrame_EdgeCase_ZeroSize() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 0, y: 0, width: 0, height: 0)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 0.0, "Should return 0 when rect2 has zero size")
    }

    func testIntersectPercentWithFrame_EdgeCase_NegativeCoordinates() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: -50, y: -50, width: 100, height: 100)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 0.25, "Should return 0.25 when rect2 extends into negative coordinates")
    }

    func testIntersectPercentWithFrame_EdgeCase_ExactHalf() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 0, y: 0, width: 100, height: 50)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 0.5, "Should return 0.5 when rect2 covers exactly half of rect1")
    }

    func testIntersectPercentWithFrame_EdgeCase_ExactQuarter() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 0, y: 0, width: 50, height: 50)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 0.25, "Should return 0.25 when rect2 covers exactly quarter of rect1")
    }

    func testIntersectPercentWithFrame_EdgeCase_ExactEighth() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 0, y: 0, width: 25, height: 50)

        let result = rect1.intersectPercentWithFrame(rect2)
        XCTAssertEqual(result, 0.125, "Should return 0.125 when rect2 covers exactly 1/8 of rect1")
    }
}
