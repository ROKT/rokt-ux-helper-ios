//
//  TestRowComponent.swift
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
final class TestRowComponent: XCTestCase {
    
    enum LayoutName {
        case basicText
        case children
    }
#if compiler(>=6)

    func test_row() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(try get_model(.basicText)))
        
        let rowComponent = try view.inspect().find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(RowComponent.self)
        
        let hstack = try rowComponent.find(ViewType.HStack.self)
        
        XCTAssertEqual(hstack.count, 1)
        
        let modifierContent = try rowComponent
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
        
        // background
        let backgroundModifier = try modifierContent.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#F5C1C4", dark: "#F5C1C4"))
        
        // border
        let borderModifier = try modifierContent.modifier(BorderModifier.self)
        let borderStyle = try borderModifier.actualView().borderStyle
        
        XCTAssertNil(borderStyle)
        
        // alignment
        let alignment = try hstack.alignment()
        XCTAssertEqual(alignment, .center)
        
        // frame
        let flexFrame = try modifierContent.flexFrame()
        XCTAssertEqual(flexFrame.minHeight, 24)
        XCTAssertEqual(flexFrame.maxHeight, 24)
        XCTAssertEqual(flexFrame.minWidth, 140)
        XCTAssertEqual(flexFrame.maxWidth, 140)
    }
    
    func test_rowComponent_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(try get_model(.basicText)))
        
        let sut = try view.inspect()
            .find(TestPlaceHolder.self)
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
        
        XCTAssertEqual(sut.accessibilityBehavior, .contain)
    }
    
    func test_row_children() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(try get_model(.children)))
        
        let children = try view
            .inspect()
            .find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(RowComponent.self)
            .find(ViewType.HStack.self)[0]
            .forEach(0)
        
        let basicText = try children
            .view(LayoutSchemaComponent.self, 0)
            .find(BasicTextComponent.self)
            .actualView()
        
        let richText = try children
            .view(LayoutSchemaComponent.self, 1)
            .find(RichTextComponent.self)
            .actualView()
        
        _ = try children
            .view(LayoutSchemaComponent.self, 2)
            .find(CloseButtonComponent.self)
            .actualView()
        
        XCTAssertEqual(basicText.model.value, "Jenny, thank you for your purchase:")
        XCTAssertEqual(richText.model.value, "Thanks! Your order # is")
        let richTextStyle = try XCTUnwrap(richText.model.defaultStyle?.first)
        XCTAssertEqual(richTextStyle.text?.fontSize, 15)
        XCTAssertEqual(richTextStyle.text?.fontFamily, "GorditaBold")
        XCTAssertEqual(richTextStyle.text?.textColor, .init(light: "#000000", dark: "#ffffff"))
        XCTAssertEqual(richTextStyle.spacing?.margin, "0 8 0 8")
        XCTAssertEqual(richTextStyle.spacing?.padding, nil)
        XCTAssertEqual(richTextStyle.spacing?.offset, nil)
    }
#else
    func test_row() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(try get_model(.basicText)))
        
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
    
    func test_rowComponent_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(try get_model(.basicText)))
        
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
        
        XCTAssertEqual(sut.accessibilityBehavior, .contain)
    }
    
    func test_row_children() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.row(try get_model(.children)))
        
        let children = try view
            .inspect()
            .view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RowComponent.self)
            .actualView()
            .inspect()
            .hStack()
            .forEach(0)
        
        let basicText = try children
            .view(LayoutSchemaComponent.self, 0)
            .view(BasicTextComponent.self)
            .actualView()
        
        let richText = try children
            .view(LayoutSchemaComponent.self, 1)
            .view(RichTextComponent.self)
            .actualView()
        
        _ = try children
            .view(LayoutSchemaComponent.self, 2)
            .view(CloseButtonComponent.self)
            .actualView()
        
        XCTAssertEqual(basicText.model.value, "Jenny, thank you for your purchase:")
        XCTAssertEqual(richText.model.value, "Thanks! Your order # is")
        let richTextStyle = try XCTUnwrap(richText.model.defaultStyle?.first)
        XCTAssertEqual(richTextStyle.text?.fontSize, 15)
        XCTAssertEqual(richTextStyle.text?.fontFamily, "GorditaBold")
        XCTAssertEqual(richTextStyle.text?.textColor, .init(light: "#000000", dark: "#ffffff"))
        XCTAssertEqual(richTextStyle.spacing?.margin, "0 8 0 8")
        XCTAssertEqual(richTextStyle.spacing?.padding, nil)
        XCTAssertEqual(richTextStyle.spacing?.offset, nil)
    }
#endif
    func get_model(_ layout: LayoutName) throws -> RowViewModel {
        let row: RowModel<LayoutSchemaModel, WhenPredicate>
        switch layout {
        case .basicText:
            row = ModelTestData.RowData.rowWithBasicText()
        case .children:
            row = ModelTestData.RowData.rowWithChildren()
        }
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        return try transformer.getRow(row.styles, children: transformer.transformChildren(row.children, context: .outer([])))
    }
}
