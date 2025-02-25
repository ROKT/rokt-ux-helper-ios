//
//  TestImageCarouselComponent.swift
//  RoktUXHelper
//
//  Copyright 2020 Rokt Pte Ltd
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
final class TestImageCarouselComponent: XCTestCase {
#if compiler(>=6)
    func test_data_image() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImageCarousel(try get_model()))

        let image = try view.inspect().find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(DataImageCarouselComponent.self)

        XCTAssertNotNil(image)
    }
#else
    func test_data_image() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImageCarousel(try get_model()))

        let image = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageCarouselComponent.self)
            .actualView()

        XCTAssertNotNil(image)
    }
#endif

    func get_model() throws -> DataImageCarouselViewModel {

        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(slots: [get_slot()])
        )
        return try transformer.getDataImageCarousel(
            ModelTestData.DataImageCarouselData.dataImageCarousel(),
            context: .inner(.generic(get_slot().offer!))
        )
    }

    func get_slot() -> SlotModel {
        let image = "https://docs.rokt.com/assets/images/embedded-placement-1-5ab04a718fe7dda94ac24aa7b89aac92.png"
        return SlotModel(instanceGuid: "",
                         offer: OfferModel(campaignId: "", creative:
                                            CreativeModel(referralCreativeId: "",
                                                          instanceGuid: "",
                                                          copy: [:],
                                                          images: [
                                                              "creativeCarouselImageVertical.1": CreativeImage(
                                                                light: image,
                                                                dark: nil, alt: "",
                                                                title: nil
                                                            ),
                                                              "creativeCarouselImageVertical.2": CreativeImage(
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
