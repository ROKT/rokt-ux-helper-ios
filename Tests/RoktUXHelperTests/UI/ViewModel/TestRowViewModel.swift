//
//  TestRowViewModel.swift
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


import Foundation
import XCTest
import SwiftUI
@testable import RoktUXHelper
@testable import DcuiSchema

@available(iOS 15, *)
class TestRowViewModel: XCTestCase {

    func testShouldAnimateInBegining() {
        let layoutState = LayoutState()
        let sut = RowViewModel(
            children: nil,
            stylingProperties: nil,
            animatableStyle: nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: [WhenPredicate.progression(ProgressionPredicate(condition: .is, value: "0"))],
            globalBreakPoints: nil,
            offers: [])

        XCTAssertTrue(sut.animate)
    }

    func testShouldAnimate() {
        let layoutState = LayoutState()
        let sut = RowViewModel(
            children: nil,
            stylingProperties: nil,
            animatableStyle: nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: [WhenPredicate.progression(ProgressionPredicate(condition: .is, value: "1"))],
            globalBreakPoints: nil,
            offers: [])

        XCTAssertFalse(sut.animate)
        layoutState.items[LayoutState.currentProgressKey] = Binding.constant(1)
        var expectation: XCTestExpectation? = expectation(description: "test animate")
        let cancellable = sut.$animate.dropFirst().sink { newValue in
            XCTAssertTrue(newValue)
            expectation?.fulfill()
            expectation = nil
        }
        wait(for: [expectation!], timeout: 1)
    }
}
