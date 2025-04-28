//
//  TestBorderModifier.swift
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
import DcuiSchema

@available(iOS 15.0, *)
final class TestBorderModifier: XCTestCase {
#if compiler(>=6)
    func test_column_with_multi_dimension_border() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(try get_model()))
        
        let target = try view.inspect()
            .find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ColumnComponent.self)
        
        // test border modifier
        let borderModifier = try target
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)
            .modifier(BorderModifier.self)
            .actualView()
        XCTAssertEqual(borderModifier.borderWidth, FrameAlignmentProperty(top: 2, right: 1, bottom: 2, left: 1))
        XCTAssertEqual(borderModifier.borderColor, ThemeColor(light: "#000000", dark: "#000000"))
        XCTAssertEqual(borderModifier.borderRadius, 10)
        XCTAssertEqual(borderModifier.borderWidth.defaultWidth(), 1)
    }
#else
    func test_column_with_multi_dimension_border() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(try get_model()))
        
        let hstack = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ColumnComponent.self)
            .actualView()
            .inspect()
            .vStack()
        
        // test border modifier
        let borderModifier = try hstack.modifier(BorderModifier.self).actualView()
        XCTAssertEqual(borderModifier.borderWidth, FrameAlignmentProperty(top: 2, right: 1, bottom: 2, left: 1))
        XCTAssertEqual(borderModifier.borderColor, ThemeColor(light: "#000000", dark: "#000000"))
        XCTAssertEqual(borderModifier.borderRadius, 10)
        XCTAssertEqual(borderModifier.borderWidth.defaultWidth(), 1)
    }
#endif
    func get_model() throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let column = ModelTestData.ColumnData.columnWithOffset()
        return try transformer.getColumn(
            column.styles,
            children: transformer.transformChildren(column.children, context: .outer([]))
        )
    }

}
