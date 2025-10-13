//
//  TestImageCarouselIndicatorItemViewModel.swift
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
class TestImageCarouselIndicatorItemViewModel: XCTestCase {

    func testWhenNode(node: LayoutSchemaViewModel, _ block: (WhenViewModel) -> Void) {
        switch node {
        case let .when(whenModel):
            block(whenModel)
        
        default:
            XCTFail("Should be .when")
        }
    }
    
    func testRowNode(node: LayoutSchemaViewModel, _ block: (RowViewModel) -> Void) {
        switch node {
        case let .row(rowModel):
            block(rowModel)
        default:
            XCTFail("Should be .row")
        }
    }
    
    func testInit() {
        let sut = ImageCarouselIndicatorItemViewModel(
            index: 0,
            duration: 1000,
            progressStyle: [.init(default: .init(), pressed: nil, hovered: nil, disabled: nil)],
            activeStyle: nil,
            animatableStyle: nil,
            indicatorStyle: nil,
            seenStyle: nil,
            layoutState: nil,
            shouldDisplayProgress: false
        )

        XCTAssertNotNil(sut)
        guard let children = sut.children else {
            XCTFail("Should have children")
            return
        }
        
        XCTAssertEqual(children.count, 3)
        
        testWhenNode(node: children[0]) { whenModel in
            guard let children = whenModel.children else {
                XCTFail("Should have children")
                return
            }
            XCTAssertEqual(children.count, 1)
            testRowNode(node: children[0]) { activeRowItem in
                XCTAssertEqual(activeRowItem.children?.count, 0)
            }
        }
        
        testWhenNode(node: children[1]) { whenModel in
            guard let children = whenModel.children else {
                XCTFail("Should have children")
                return
            }
            XCTAssertEqual(children.count, 1)
            
            testRowNode(node: children[0]) { inactiveRowItem in
                XCTAssertEqual(inactiveRowItem.children?.count, 1)
            }
        }
        
        testWhenNode(node: children[2]) { whenModel in
            guard let children = whenModel.children else {
                XCTFail("Should have children")
                return
            }
            XCTAssertEqual(children.count, 1)
            
            testRowNode(node: children[0]) { notSeenRowItem in
                XCTAssertEqual(notSeenRowItem.children?.count, 0)
            }
        }
    }
}
