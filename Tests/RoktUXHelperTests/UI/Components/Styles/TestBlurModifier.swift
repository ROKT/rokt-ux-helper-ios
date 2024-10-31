//
//  TestBlurModifier.swift
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
final class TestBlurModifier: XCTestCase {

    func test_column_with_offset() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(try get_model()))
        
        let sut = try view.inspect()
            .find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ColumnComponent.self)
        
        let modifier = try sut
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)
        // test blur modifier
        let blurModifier = try modifier.modifier(BlurModifier.self).actualView()
        XCTAssertEqual(blurModifier.blur, 5)
        
        // test blur
        let blur = try modifier.blur()
        XCTAssertEqual(blur.radius, 5)
    }
    
    func get_model() throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let column = ModelTestData.ColumnData.columnWithOffset()
        return try transformer.getColumn(column.styles, children: transformer.transformChildren(column.children, slot: nil))
    }

}
