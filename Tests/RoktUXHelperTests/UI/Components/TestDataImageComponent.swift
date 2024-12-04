//
//  TestDataImageComponent.swift
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
final class TestDataImageComponent: XCTestCase {
    func test_data_image() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model()))
        
        let image = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
            .inspect()
            .find(AsyncImageView.self)
        
        // test custom modifier class
        let paddingModifier = try image.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24))
        
        // test the effect of custom modifier
        let padding = try image.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 18.0, leading: 24.0, bottom: 0.0, trailing: 24.0))
    }
    
    func test_dataImage_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model()))
        
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
        
        let model = sut.model
        
        XCTAssertEqual(sut.dimensionStyle, model.defaultStyle?.first?.dimension)
        XCTAssertEqual(sut.flexStyle, model.defaultStyle?.first?.flexChild)
        XCTAssertEqual(sut.backgroundStyle, model.defaultStyle?.first?.background)
        XCTAssertEqual(sut.spacingStyle, model.defaultStyle?.first?.spacing)
        
        XCTAssertEqual(sut.verticalAlignment, .center)
        XCTAssertEqual(sut.horizontalAlignment, .center)
        
        let asyncImage = try sut.inspect().find(AsyncImageView.self).actualView()
        // nil url is converted to empty string
        XCTAssertEqual(asyncImage.imageUrl,
                       ThemeUrl(light: "https://docs.rokt.com/assets/images/embedded-placement-1-5ab04a718fe7dda94ac24aa7b89aac92.png",
                                dark: ""))
    }
    
    func get_model() throws -> DataImageViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: [get_slot()]))
        return try transformer.getDataImage(ModelTestData.DataImageData.dataImage(), context: .inner(.generic(get_slot().offer!)))
    }
    
    func get_slot() -> SlotModel {
        SlotModel(instanceGuid: "",
                  offer: .mock(
                    images: ["creativeImage" : CreativeImage(light: "https://docs.rokt.com/assets/images/embedded-placement-1-5ab04a718fe7dda94ac24aa7b89aac92.png",
                                                             dark: nil, alt: "", title: nil)],
                    token: "creative-token"
                  ),
                  layoutVariant: nil,
                  jwtToken: "slot-token")
    }
}
