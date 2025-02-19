//
//  TestBasicTextComponent.swift
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
final class TestBasicTextComponent: XCTestCase {
#if compiler(>=6)
    func test_basic_text() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.basicText(try get_model()))
        
        let sut = try view.inspect()
            .view(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(BasicTextComponent.self)
        
        let text = try sut.find(ViewType.Text.self)
        
        // test custom modifier class
        let modifierContent = try sut
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)

        let paddingModifier = try modifierContent.modifier(PaddingModifier.self).actualView().padding
        
        XCTAssertEqual(
            paddingModifier,
            FrameAlignmentProperty(top: 1, right: 0, bottom: 1, left: 8)
        )
        
        // test the effect of custom modifier
        XCTAssertEqual(
            try modifierContent.padding(),
            EdgeInsets(top: 1, leading: 8, bottom: 17, trailing: 0)
        )
        
        XCTAssertEqual(try text.attributes().foregroundColor(), Color(hex: "#AABBCC"))
        
        XCTAssertEqual(try text.string(), "ORDER Number: Uk171359906")
        
        // alignment self modifier
        let alignSelfModifier = try modifierContent.modifier((AlignSelfModifier.self))
        XCTAssertEqual(try alignSelfModifier.actualView().wrapperAlignment?.horizontal, .center)
        
        // frame
        let flexFrame = try modifierContent.flexFrame()
        XCTAssertEqual(flexFrame.minHeight, 24)
        XCTAssertEqual(flexFrame.maxHeight, 24)
        XCTAssertEqual(flexFrame.minWidth, 40)
        XCTAssertEqual(flexFrame.maxWidth, 40)
    }
    
    func test_basicText_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.basicText(try get_model()))
        
        let sut = try view.inspect().find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(BasicTextComponent.self)
            .actualView()
        
        let model = sut.model
        
        XCTAssertEqual(sut.style, model.currentStylingProperties)
        XCTAssertEqual(sut.dimensionStyle, model.currentStylingProperties?.dimension)
        XCTAssertEqual(sut.flexStyle, model.currentStylingProperties?.flexChild)
        XCTAssertEqual(sut.backgroundStyle, model.currentStylingProperties?.background)
        XCTAssertEqual(sut.spacingStyle, model.currentStylingProperties?.spacing)
        
        XCTAssertNil(sut.lineLimit)
        XCTAssertEqual(sut.lineHeight, 0)
        XCTAssertEqual(sut.lineHeightPadding, 0)
        
        XCTAssertEqual(sut.verticalAlignment, .top)
        XCTAssertEqual(sut.horizontalAlignment, .start)
        
        XCTAssertEqual(sut.stateReplacedValue, "ORDER Number: Uk171359906")
    }
#else
    func test_basic_text() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.basicText(try get_model()))
        
        let text = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(BasicTextComponent.self)
            .actualView()
            .inspect()
            .text()
        
        // test custom modifier class
        let paddingModifier = try text.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 1, right: 0, bottom: 1, left: 8))
        
        // test the effect of custom modifier
        let padding = try text.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 1.0, leading: 8.0, bottom: 17.0, trailing: 0.0))
        
        XCTAssertEqual(try text.attributes().foregroundColor(), Color(hex: "#AABBCC"))
        
        XCTAssertEqual(try text.string(), "ORDER Number: Uk171359906")
        
        // alignment self modifier
        let alignSelfModifier = try text.modifier(AlignSelfModifier.self)
        XCTAssertEqual(try alignSelfModifier.actualView().wrapperAlignment?.horizontal, .center)
        
        // frame
        let flexFrame = try text.flexFrame()
        XCTAssertEqual(flexFrame.minHeight, 24)
        XCTAssertEqual(flexFrame.maxHeight, 24)
        XCTAssertEqual(flexFrame.minWidth, 40)
        XCTAssertEqual(flexFrame.maxWidth, 40)
    }
    
    func test_basicText_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.basicText(try get_model()))
        
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(BasicTextComponent.self)
            .actualView()
        
        let model = sut.model
        
        XCTAssertEqual(sut.style, model.currentStylingProperties)
        XCTAssertEqual(sut.dimensionStyle, model.currentStylingProperties?.dimension)
        XCTAssertEqual(sut.flexStyle, model.currentStylingProperties?.flexChild)
        XCTAssertEqual(sut.backgroundStyle, model.currentStylingProperties?.background)
        XCTAssertEqual(sut.spacingStyle, model.currentStylingProperties?.spacing)
        
        XCTAssertNil(sut.lineLimit)
        XCTAssertEqual(sut.lineHeight, 0)
        XCTAssertEqual(sut.lineHeightPadding, 0)
        
        XCTAssertEqual(sut.verticalAlignment, .top)
        XCTAssertEqual(sut.horizontalAlignment, .start)
        
        XCTAssertEqual(sut.stateReplacedValue, "ORDER Number: Uk171359906")
    }
#endif
    func get_model() throws -> BasicTextViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        return try transformer.getBasicText(ModelTestData.TextData.basicText(), context: .outer([]))
    }
}
