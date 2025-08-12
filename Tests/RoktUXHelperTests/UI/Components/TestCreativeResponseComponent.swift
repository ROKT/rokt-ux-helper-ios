//
//  TestCreativeResponseComponent.swift
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
final class TestCreativeResponseComponent: XCTestCase {

    func test_creative_response() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.creativeResponse(try get_model()))
        
        let creativeResponse = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CreativeResponseComponent.self)
            .actualView()
            .inspect()
            .hStack()
        
        // test custom modifier class
        let paddingModifier = try creativeResponse.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 10, right: 10, bottom: 10, left: 10))
        
        // test the effect of custom modifier
        let padding = try creativeResponse.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0))
        
        // background
        let backgroundModifier = try creativeResponse.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#000000", dark: nil))
    }
    
    func test_creativeResponse_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.creativeResponse(try get_model()))
        
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CreativeResponseComponent.self)
            .actualView()
        
        let defaultStyle = sut.model.defaultStyle?[0]
        
        XCTAssertEqual(sut.style, defaultStyle)
        XCTAssertEqual(sut.containerStyle, defaultStyle?.container)
        XCTAssertEqual(sut.dimensionStyle, defaultStyle?.dimension)
        XCTAssertEqual(sut.flexStyle, defaultStyle?.flexChild)
        XCTAssertEqual(sut.borderStyle, defaultStyle?.border)
        XCTAssertEqual(sut.backgroundStyle, defaultStyle?.background)
        XCTAssertEqual(sut.passableBackgroundStyle, defaultStyle?.background)
        
        XCTAssertEqual(sut.verticalAlignment, .top)
        XCTAssertEqual(sut.horizontalAlignment, .center)
        
        XCTAssertEqual(sut.verticalAlignmentOverride, .center)
        XCTAssertEqual(sut.horizontalAlignment, .center)
    }
    
    func test_creative_response_external_response_action() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.creativeResponse(try get_model_with_external_response_action()))
        
        let creativeResponseComponent = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CreativeResponseComponent.self)
            .actualView()
        
        // Verify that external response action returns EmptyView
        let emptyView = try creativeResponseComponent.inspect().emptyView()
        XCTAssertNotNil(emptyView)
        
        // Test that the component correctly identifies as external response option
        XCTAssertTrue(creativeResponseComponent.isExternalResponseOption)
        
        // Test that the model has the correct external response option
        XCTAssertEqual(creativeResponseComponent.model.responseOptions?.action, .external)
        XCTAssertEqual(creativeResponseComponent.model.responseOptions?.shortLabel, "Yes please")
    }
    
    func test_creative_response_external_response_action_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.creativeResponse(try get_model_with_external_response_action()))
        
        let creativeResponse = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CreativeResponseComponent.self)
            .actualView()
        
        let defaultStyle = creativeResponse.model.defaultStyle?[0]
        
        XCTAssertEqual(creativeResponse.style, defaultStyle)
        XCTAssertEqual(creativeResponse.containerStyle, defaultStyle?.container)
        XCTAssertEqual(creativeResponse.dimensionStyle, defaultStyle?.dimension)
        XCTAssertEqual(creativeResponse.flexStyle, defaultStyle?.flexChild)
        XCTAssertEqual(creativeResponse.borderStyle, defaultStyle?.border)
        XCTAssertEqual(creativeResponse.backgroundStyle, defaultStyle?.background)
        XCTAssertEqual(creativeResponse.passableBackgroundStyle, defaultStyle?.background)
        
        XCTAssertEqual(creativeResponse.verticalAlignment, .top)
        XCTAssertEqual(creativeResponse.horizontalAlignment, .center)
        
        XCTAssertEqual(creativeResponse.verticalAlignmentOverride, .center)
        XCTAssertEqual(creativeResponse.horizontalAlignment, .center)
    }
    
    func get_model() throws -> CreativeResponseViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let creativeResponse = ModelTestData.CreativeResponseData.positive()
        return try transformer.getCreativeResponseUIModel(responseKey: creativeResponse?.responseKey ?? "",
                                                          openLinks: nil,
                                                          styles: creativeResponse?.styles,
                                                          children: transformer.transformChildren(creativeResponse?.children,
                                                                                                  context: .outer([])),
                                                          offer: .mock())
    }
    
    func get_model_with_external_response_action() throws -> CreativeResponseViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let creativeResponse = ModelTestData.CreativeResponseData.external()
        return try transformer.getCreativeResponseUIModel(responseKey: creativeResponse?.responseKey ?? "",
                                                          openLinks: nil,
                                                          styles: creativeResponse?.styles,
                                                          children: transformer.transformChildren(creativeResponse?.children,
                                                                                                  context: .outer([])),
                                                          offer: .mock())
    }
}
