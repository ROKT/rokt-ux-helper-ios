//
//  TestImageCarouselIndicatorViewModel.swift
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
class TestImageCarouselIndicatorViewModel: XCTestCase {
    func testInit() {
        let sut = ImageCarouselIndicatorViewModel(
            positions: 4,
            duration: 1000,
            stylingProperties: [],
            indicatorStyle: [
                .init(
                    default: .init(
                        container: nil,
                        background: nil,
                        border: nil,
                        dimension: nil,
                        flexChild: nil,
                        spacing: nil
                    ),
                    pressed: nil,
                    hovered: nil,
                    disabled: nil
                )
            ],
            seenIndicatorStyle: [],
            activeIndicatorStyle: [
                .init(
                    default: .init(
                        container: nil,
                        background: nil,
                        border: nil,
                        dimension: nil,
                        flexChild: nil,
                        spacing: nil
                    ),
                    pressed: nil,
                    hovered: nil,
                    disabled: nil
                )
            ],
            layoutState: nil,
            shouldDisplayProgress: true
        )
        XCTAssertNotNil(sut)
        let rowViewModels = sut.rowViewModels
        
        XCTAssertEqual(rowViewModels.count, 4)
        
        XCTAssertEqual(rowViewModels[0].children?.count, 3)
        XCTAssertEqual(rowViewModels[1].children?.count, 3)
        XCTAssertEqual(rowViewModels[2].children?.count, 3)
        XCTAssertEqual(rowViewModels[3].children?.count, 3)
    }
    
}
