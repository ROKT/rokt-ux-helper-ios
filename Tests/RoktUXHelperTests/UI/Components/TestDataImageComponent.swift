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
#if compiler(>=6)
    func test_data_image() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model()))
        
        let image = try view.inspect().find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(DataImageViewComponent.self)
        
        let modifierContent = try image
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)

        let paddingModifier = try modifierContent.modifier(PaddingModifier.self).actualView().padding
        XCTAssertEqual(paddingModifier, FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24))
    
        // test the effect of custom modifier
        XCTAssertEqual(try modifierContent.padding(), EdgeInsets(top: 18.0, leading: 24.0, bottom: 0.0, trailing: 24.0))
    }
    
    func test_dataImage_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model()))
        
        let sut = try view.inspect().find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(DataImageViewComponent.self)
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
#else
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
    
    func test_data_image_failed() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model(isValid: false)))
        
        let image = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
            .inspect()
        // Invalid Image should be removed from view
        XCTAssertNil(try? image.find(AsyncImageView.self))
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
#endif
    
    func get_model(isValid: Bool = true) throws -> DataImageViewModel {
        let validImage = "https://docs.rokt.com/assets/images/embedded-placement-1-5ab04a718fe7dda94ac24aa7b89aac92.png"
        let invalidImage = ""
        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(slots: [get_slot(image: isValid ? validImage : invalidImage)])
        )
        return try transformer.getDataImage(
            ModelTestData.DataImageData.dataImage(),
            context: .inner(.generic(get_slot(image: isValid ? validImage : invalidImage).offer!))
        )
    }

    func get_slot(image: String) -> SlotModel {
        return SlotModel(instanceGuid: "",
                         offer: OfferModel(campaignId: "", creative:
                                            CreativeModel(referralCreativeId: "",
                                                          instanceGuid: "",
                                                          copy: [:],
                                                          images: [
                                                            "creativeImage": CreativeImage(
                                                                light: image,
                                                                dark: nil, alt: "",
                                                                title: nil
                                                            )
                                                          ],
                                                          links: nil,
                                                          responseOptionsMap: nil,
                                                          jwtToken: "creative-token")),
                         layoutVariant: nil,
                         jwtToken: "slot-token")
    }
}
