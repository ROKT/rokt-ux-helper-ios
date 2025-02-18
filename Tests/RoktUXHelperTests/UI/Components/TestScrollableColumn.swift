//
//  TestScrollableColumn.swift
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
final class TestScrollableColumn: XCTestCase {
#if compiler(>=6)
    func test_column() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_model()))
        
        let sut = try view.inspect()
            .find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ScrollableColumnComponent.self)
            .find(ViewType.ScrollView.self)
            .find(ColumnComponent.self)
        
        let modifierContent = try sut
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)
        
        // test custom modifier class
        let paddingModifier = try modifierContent.modifier(PaddingModifier.self)
        XCTAssertEqual(
            try paddingModifier.actualView().padding,
            FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24)
        )
        
        // test the effect of custom modifier
        let padding = try modifierContent.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 18.0, leading: 24.0, bottom: 0.0, trailing: 24.0))
        
        // Test weight = 1 add maxHeight .infinity
        let flexFrame = try modifierContent.flexFrame()
        XCTAssertEqual(flexFrame.maxHeight, .infinity)
        
        // background
        let backgroundModifier = try modifierContent.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))
        
        // border
        let borderModifier = try modifierContent.modifier(BorderModifier.self)
        let borderStyle = try borderModifier.actualView().borderStyle
        
        XCTAssertNil(borderStyle)
        
        // alignment
        let alignment = try sut.find(ViewType.VStack.self).alignment()
        XCTAssertEqual(alignment, .center)
    }
#else
    func test_column() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.scrollableColumn(try get_model()))
        
        let vstack = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ScrollableColumnComponent.self)
            .scrollView()
            .view(ColumnComponent.self)
            .actualView()
            .inspect()
            .vStack()
        
        // test custom modifier class
        let paddingModifier = try vstack.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24))
        
        // test the effect of custom modifier
        let padding = try vstack.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 18.0, leading: 24.0, bottom: 0.0, trailing: 24.0))
        
        // Test weight = 1 add maxHeight .infinity
        let flexFrame = try vstack.flexFrame()
        XCTAssertEqual(flexFrame.maxHeight, .infinity)
        
        // background
        let backgroundModifier = try vstack.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))
        
        // border
        let borderModifier = try vstack.modifier(BorderModifier.self)
        let borderStyle = try borderModifier.actualView().borderStyle
        
        XCTAssertNil(borderStyle)
        
        // alignment
        let alignment = try vstack.alignment()
        XCTAssertEqual(alignment, .center)
    }
#endif
    func get_model() throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let column = ModelTestData.ColumnData.columnWithBasicText()
        return try transformer.getColumn(column.styles, children: transformer.transformChildren(column.children, context: .outer([])))
    }
    
}
