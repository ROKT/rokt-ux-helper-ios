//
//  TestToggleButtonComponent.swift
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
final class TestToggleButtonComponent: XCTestCase {
    
    func test_toggleButton_styles() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.toggleButton(try get_model()))
        
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ToggleButtonComponent.self)
            .actualView()
        
        let model = sut.model
        
        XCTAssertEqual(sut.style, model.defaultStyle?[0])
        XCTAssertEqual(sut.dimensionStyle, model.defaultStyle?[0].dimension)
        XCTAssertEqual(sut.flexStyle, model.defaultStyle?[0].flexChild)
        XCTAssertEqual(sut.backgroundStyle, model.defaultStyle?[0].background)
        XCTAssertEqual(sut.spacingStyle, model.defaultStyle?[0].spacing)
        
        XCTAssertEqual(sut.verticalAlignment, .top)
        XCTAssertEqual(sut.horizontalAlignment, .center)
        
        let toggleButton = try sut.inspect().hStack()
        
        // test the effect of custom modifier
        let backgroundModifier = try toggleButton.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#FFFFFF", dark: "#000000"))
    }
    
    func get_model() throws -> ToggleButtonViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let model = ModelTestData.ToggleButtonData.basicToggleButton()
        return try transformer.getToggleButton(customStateKey: model.customStateKey,
                                               styles: model.styles,
                                               children: transformer.transformChildren(model.children, context: .outer([])))
    }
    
}
