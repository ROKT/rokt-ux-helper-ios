//
//  TestColumnComponent.swift
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
final class TestColumnComponent: XCTestCase {
    func test_column() throws {
        
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(try get_model()))
        
        let sut = try view.inspect()
            .find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(LayoutSchemaComponent.self)
            .find(ColumnComponent.self)
        
        // test custom modifier class
        let modifier = try sut.modifierIgnoreAny(LayoutSchemaModifier.self)
        XCTAssertEqual(try modifier.actualView().spacing?.padding, "18 24 0 24")
        
        let modifierContent = try modifier.ignoreAny(ViewType.ViewModifierContent.self)
        // test the effect of custom modifier
        XCTAssertEqual(
            try modifierContent.modifier(PaddingModifier.self).actualView().padding,
            FrameAlignmentProperty(top: 18.0, right: 24.0, bottom: 0.0, left: 24.0)
        )
    
        // Test weight = 1 add maxHeight .infinity
        XCTAssertEqual(try modifierContent.flexFrame().maxHeight, .infinity)
        
        // background
        let backgroundModifier = try modifierContent.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))
        
        // border
        let borderModifier = try modifierContent.modifier((BorderModifier.self))
        let borderStyle = try borderModifier.actualView().borderStyle
        
        XCTAssertNil(borderStyle)
        
        // alignment
        let alignment = try sut
            .find(ViewType.VStack.self)
            .alignment()
        XCTAssertEqual(alignment, .center)
    }
    
    func get_model() throws -> ColumnViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let column = ModelTestData.ColumnData.columnWithBasicText()
        return try transformer.getColumn(column.styles, children: transformer.transformChildren(column.children, slot: nil))
    }
    
}
