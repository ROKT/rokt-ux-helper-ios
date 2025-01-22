//
//  TestAccessibilityGroupedModelInColumnComponent.swift
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
final class TestAccessibilityGroupedModelInColumnComponent: XCTestCase {
    
#if compiler(>=6)
    func test_column() throws {
        let model = try get_model()
        
        guard case .column(let columnUIModel) = model else {
            XCTFail()
            return
        }
        
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(columnUIModel))
        
        let sut = try view.inspect()
            .find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ColumnComponent.self)
        
        // test custom modifier class
        
        let modifierContent = try sut
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)
        
        let paddingModifier = try modifierContent.modifier(PaddingModifier.self).actualView().padding
        // test the effect of custom modifier
        XCTAssertEqual(
            paddingModifier,
            FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24)
        )
    
        // Test weight = 1 add maxHeight .infinity
        XCTAssertEqual(try modifierContent.flexFrame().maxHeight, .infinity)
        
        // background
        let backgroundModifier = try modifierContent.modifier((BackgroundModifier.self))
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
    
    func test_columnComponent_computedProperties_accessibility() throws {
        let model = try get_model()
        
        guard case .column(let columnUIModel) = model else {
            XCTFail()
            return
        }
        
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(columnUIModel))
        
        let sut = try view.inspect()
            .view(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ColumnComponent.self)
            .actualView()
        
        let defaultStyle = sut.model.defaultStyle?[0]
        
        XCTAssertEqual(sut.style, defaultStyle)
        
        XCTAssertEqual(sut.containerStyle, defaultStyle?.container)
        XCTAssertEqual(sut.dimensionStyle, defaultStyle?.dimension)
        XCTAssertEqual(sut.flexStyle, defaultStyle?.flexChild)
        XCTAssertEqual(sut.backgroundStyle, defaultStyle?.background)
        XCTAssertEqual(sut.spacingStyle, defaultStyle?.spacing)
        XCTAssertEqual(sut.borderStyle, defaultStyle?.border)
        
        XCTAssertEqual(sut.passableBackgroundStyle, defaultStyle?.background)
        
        XCTAssertEqual(sut.verticalAlignment, .center)
        XCTAssertEqual(sut.horizontalAlignment, .center)
        
        XCTAssertEqual(sut.accessibilityBehavior, .combine)
        
    }
#else
    func test_column() throws {
        let model = try get_model()
        
        guard case .column(let columnUIModel) = model else {
            XCTFail()
            return
        }
        
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(columnUIModel))
        
        let vstack = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
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
    
    func test_columnComponent_computedProperties_accessibility() throws {
        let model = try get_model()
        
        guard case .column(let columnUIModel) = model else {
            XCTFail()
            return
        }
        
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.column(columnUIModel))
        
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ColumnComponent.self)
            .actualView()
        
        let defaultStyle = sut.model.defaultStyle?[0]
        
        XCTAssertEqual(sut.style, defaultStyle)
        
        XCTAssertEqual(sut.containerStyle, defaultStyle?.container)
        XCTAssertEqual(sut.dimensionStyle, defaultStyle?.dimension)
        XCTAssertEqual(sut.flexStyle, defaultStyle?.flexChild)
        XCTAssertEqual(sut.backgroundStyle, defaultStyle?.background)
        XCTAssertEqual(sut.spacingStyle, defaultStyle?.spacing)
        XCTAssertEqual(sut.borderStyle, defaultStyle?.border)
        
        XCTAssertEqual(sut.passableBackgroundStyle, defaultStyle?.background)
        
        XCTAssertEqual(sut.verticalAlignment, .center)
        XCTAssertEqual(sut.horizontalAlignment, .center)
        
        XCTAssertEqual(sut.accessibilityBehavior, .combine)
        
    }
#endif
    func get_model() throws -> LayoutSchemaViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let accessibilityGroup = ModelTestData.ColumnData.accessibilityGroupedColumn()
        return try transformer.getAccessibilityGrouped(child: accessibilityGroup.child, slot: nil)
    }
}
