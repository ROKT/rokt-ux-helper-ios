//
//  TestOffsetModifier.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
import SwiftUI
import ViewInspector
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestOffsetModifier: XCTestCase {

    func test_column_with_offset() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(try get_model()))
        
        let hstack = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ColumnComponent.self)
            .actualView()
            .inspect()
            .vStack()
        
        // test offset modifier
        let offsetModifier = try hstack.modifier(OffsetModifier.self).actualView()
        XCTAssertEqual(offsetModifier.offset?.x, 30)
        XCTAssertEqual(offsetModifier.offset?.y, 20)
        
        // test offset
        let offset = try hstack.offset()
        XCTAssertEqual(offset.width, 30)
        XCTAssertEqual(offset.height, 20)
        
    }
    
    func get_model() throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let column = ModelTestData.ColumnData.columnWithOffset()
        return try transformer.getColumn(column.styles, children: transformer.transformChildren(column.children, slot: nil))
    }
    
}
