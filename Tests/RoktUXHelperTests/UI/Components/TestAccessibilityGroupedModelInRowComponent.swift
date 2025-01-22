//
//  TestAccessibilityGroupedModelInRowComponent.swift
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
final class TestAccessibilityGroupedModelInRowComponent: XCTestCase {
    
#if compiler(>=6)
    func test_row() throws {
        let model = try get_model()
        
        guard case .row(let rowUIModel) = model else {
            XCTFail()
            return
        }

        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(rowUIModel))
        
        let target = try view.inspect()
            .view(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(RowComponent.self)
        
        // test custom modifier class
        let modifierContent = try target
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)
        let paddingModifier = try modifierContent.modifier(PaddingModifier.self).actualView().padding
        
        // test the effect of custom modifier
        XCTAssertEqual(
            paddingModifier,
            FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24)
        )
        
        // background
        let backgroundModifier = try modifierContent.modifier((BackgroundModifier.self))
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))
        
        // border
        let borderModifier = try modifierContent.modifier((BorderModifier.self))
        let borderStyle = try borderModifier.actualView().borderStyle
        
        XCTAssertNil(borderStyle)
        
        // alignment
        let hStack = try target
            .find(ViewType.HStack.self)

        XCTAssertEqual(hStack.count, 1)
        XCTAssertEqual(try hStack.alignment(), .center)
        
        // frame
        let flexFrame = try modifierContent.flexFrame()
        XCTAssertEqual(flexFrame.minHeight, 24)
        XCTAssertEqual(flexFrame.maxHeight, 24)
        XCTAssertEqual(flexFrame.minWidth, 140)
        XCTAssertEqual(flexFrame.maxWidth, 140)
    }
    
    func test_rowComponent_computedProperties_accessibility() throws {
        let model = try get_model()
        
        guard case .row(let rowUIModel) = model else {
            XCTFail()
            return
        }

        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(rowUIModel))
        
        let sut = try view.inspect()
            .view(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(RowComponent.self)
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
    func test_row() throws {
        let model = try get_model()
        
        guard case .row(let rowUIModel) = model else {
            XCTFail()
            return
        }

        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(rowUIModel))
        
        let hstack = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RowComponent.self)
            .actualView()
            .inspect()
            .hStack()
        
        XCTAssertEqual(hstack.count, 1)
        
        // test custom modifier class
        let paddingModifier = try hstack.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24))
        
        // test the effect of custom modifier
        let padding = try hstack.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 18.0, leading: 24.0, bottom: 0.0, trailing: 24.0))
        
        // background
        let backgroundModifier = try hstack.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))
        
        // border
        let borderModifier = try hstack.modifier(BorderModifier.self)
        let borderStyle = try borderModifier.actualView().borderStyle
        
        XCTAssertNil(borderStyle)
        
        // alignment
        let alignment = try hstack.alignment()
        XCTAssertEqual(alignment, .center)
        
        // frame
        let flexFrame = try hstack.flexFrame()
        XCTAssertEqual(flexFrame.minHeight, 24)
        XCTAssertEqual(flexFrame.maxHeight, 24)
        XCTAssertEqual(flexFrame.minWidth, 140)
        XCTAssertEqual(flexFrame.maxWidth, 140)

    }
    
    func test_rowComponent_computedProperties_accessibility() throws {
        let model = try get_model()
        
        guard case .row(let rowUIModel) = model else {
            XCTFail()
            return
        }

        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(rowUIModel))
        
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RowComponent.self)
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
        let accessibilityGroup = ModelTestData.RowData.accessibilityGroupedRow()
        return try transformer.getAccessibilityGrouped(child: accessibilityGroup.child, slot: nil)
    }
}
