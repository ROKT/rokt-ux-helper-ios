//
//  TestCatalogImageGalleryComponent.swift
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
final class TestCatalogImageGalleryComponent: XCTestCase {

    func test_catalogImageGallery_rendersExpectedThumbnails() throws {
        let view = try TestPlaceHolder.make(
            layoutMaker: LayoutSchemaViewModel.makeCatalogImageGallery(layoutState:eventService:)
        )

        let component = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogImageGalleryComponent.self)

        let sut = try component.actualView()

        XCTAssertEqual(sut.model.images.count, 3)
        XCTAssertEqual(sut.model.selectedIndex, 0)

        let thumbnails = try component
            .find(ViewType.ScrollViewReader.self)
            .scrollView()
            .hStack()
            .forEach(0)

        XCTAssertEqual(thumbnails.count, sut.model.images.count)
    }

    func test_catalogImageGallery_thumbnailTapUpdatesSelection() throws {
        let view = try TestPlaceHolder.make(
            layoutMaker: LayoutSchemaViewModel.makeCatalogImageGallery(layoutState:eventService:)
        )

        let component = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogImageGalleryComponent.self)

        let sut = try component.actualView()
        XCTAssertEqual(sut.model.selectedIndex, 0)

        let thumbnails = try component
            .find(ViewType.ScrollViewReader.self)
            .scrollView()
            .hStack()
            .forEach(0)

        let secondThumbnail = try thumbnails.view(DataImageViewComponent.self, 1)
        try secondThumbnail.callOnTapGesture()

        XCTAssertEqual(sut.model.selectedIndex, 1)
        XCTAssertTrue(sut.model.selectedImage === sut.model.images[1])
    }
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {
    static func makeCatalogImageGallery(
        layoutState: LayoutState,
        eventService: EventService
    ) throws -> Self {
        let catalogItem = CatalogItem.mock(
            images: [
                "catalogItemImage0": CreativeImage(
                    light: "https://example.com/gallery-0.png",
                    dark: nil,
                    alt: "Gallery 0",
                    title: nil
                ),
                "catalogItemImage1": CreativeImage(
                    light: "https://example.com/gallery-1.png",
                    dark: nil,
                    alt: "Gallery 1",
                    title: nil
                ),
                "catalogItemImage2": CreativeImage(
                    light: "https://example.com/gallery-2.png",
                    dark: nil,
                    alt: "Gallery 2",
                    title: nil
                )
            ]
        )

        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(),
            layoutState: layoutState,
            eventService: eventService
        )

        let galleryModel = CatalogImageGalleryModel<WhenPredicate>(
            styles: nil,
            scrollGradientLength: nil,
            leftScrollIconTemplate: nil,
            rightScrollIconTemplate: nil
        )

        return LayoutSchemaViewModel.catalogImageGallery(
            try transformer.getCatalogImageGalleryModel(
                model: galleryModel,
                context: .inner(.addToCart(catalogItem))
            )
        )
    }
}
