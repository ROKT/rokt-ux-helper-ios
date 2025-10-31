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
            layoutMaker: { layoutState, eventService in
                try LayoutSchemaViewModel.makeCatalogImageGallery(
                    layoutState: layoutState,
                    eventService: eventService
                )
            }
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
            layoutMaker: { layoutState, eventService in
                try LayoutSchemaViewModel.makeCatalogImageGallery(
                    layoutState: layoutState,
                    eventService: eventService
                )
            }
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

    func test_catalogImageGallery_hidesThumbnailsWhenStyleMissing() throws {
        let view = try TestPlaceHolder.make { layoutState, eventService in
            try LayoutSchemaViewModel.makeCatalogImageGallery(
                layoutState: layoutState,
                eventService: eventService,
                includeThumbnailRow: false
            )
        }

        let component = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogImageGalleryComponent.self)

        let sut = try component.actualView()

        XCTAssertFalse(sut.model.showThumbnails)
        XCTAssertThrowsError(try component.find(ViewType.ScrollViewReader.self))
    }

    func test_catalogImageGallery_indicatorHiddenWithoutContainer() throws {
        let view = try TestPlaceHolder.make { layoutState, eventService in
            try LayoutSchemaViewModel.makeCatalogImageGallery(
                layoutState: layoutState,
                eventService: eventService,
                includeIndicatorContainer: false
            )
        }

        let component = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogImageGalleryComponent.self)

        _ = try component.actualView()

        let rowComponents = component.findAll(ViewType.View<RowComponent>.self)
        XCTAssertEqual(rowComponents.count, 0)
    }

    func test_catalogImageGallery_indicatorAlignSelfFromStyles() throws {
        let view = try TestPlaceHolder.make { layoutState, eventService in
            try LayoutSchemaViewModel.makeCatalogImageGallery(
                layoutState: layoutState,
                eventService: eventService,
                indicatorAlignSelf: .flexEnd
            )
        }

        let component = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogImageGalleryComponent.self)

        let sut = try component.actualView()

        XCTAssertEqual(sut.model.indicatorAlignSelf(for: 0), .flexEnd)
    }

    func test_catalogImageGallery_selectNextImageAdvancesIndex() throws {
        let view = try TestPlaceHolder.make(
            layoutMaker: { layoutState, eventService in
                try LayoutSchemaViewModel.makeCatalogImageGallery(
                    layoutState: layoutState,
                    eventService: eventService
                )
            }
        )

        let component = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogImageGalleryComponent.self)

        let sut = try component.actualView()
        XCTAssertEqual(sut.model.selectedIndex, 0)

        sut.model.selectedIndex = 1

        XCTAssertEqual(sut.model.selectedIndex, 1)
        XCTAssertTrue(sut.model.selectedImage === sut.model.images[1])
    }

    func test_catalogImageGallery_selectPreviousImageAtFirstIndexDoesNotMove() throws {
        let view = try TestPlaceHolder.make(
            layoutMaker: { layoutState, eventService in
                try LayoutSchemaViewModel.makeCatalogImageGallery(
                    layoutState: layoutState,
                    eventService: eventService
                )
            }
        )

        let component = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogImageGalleryComponent.self)

        let sut = try component.actualView()
        XCTAssertEqual(sut.model.selectedIndex, 0)
    }
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {
    static func makeCatalogImageGallery(
        layoutState: LayoutState,
        eventService: EventService,
        includeThumbnailRow: Bool = true,
        includeIndicatorContainer: Bool = true,
        indicatorAlignSelf: FlexAlignment? = nil
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

        let thumbnailList = includeThumbnailRow ? [BasicStateStylingBlock<RowStyle>(
            default: RowStyle(
                container: ContainerStylingProperties(
                    justifyContent: .center,
                    alignItems: .center,
                    shadow: nil,
                    overflow: nil,
                    gap: 8,
                    blur: nil
                ),
                background: nil,
                border: nil,
                dimension: nil,
                flexChild: nil,
                spacing: nil
            ),
            pressed: nil,
            hovered: nil,
            disabled: nil
        )] : nil

        let indicatorContainer = includeIndicatorContainer ? [BasicStateStylingBlock<CatalogImageGalleryIndicatorStyles>(
            default: CatalogImageGalleryIndicatorStyles(
                container: ContainerStylingProperties(
                    justifyContent: .center,
                    alignItems: .center,
                    shadow: nil,
                    overflow: nil,
                    gap: 4,
                    blur: nil
                ),
                background: nil,
                border: nil,
                dimension: nil,
                flexChild: indicatorAlignSelf.map {
                    FlexChildStylingProperties(weight: nil, order: nil, alignSelf: $0)
                },
                spacing: nil
            ),
            pressed: nil,
            hovered: nil,
            disabled: nil
        )] : nil

        let galleryElements = CatalogImageGalleryElements(
            own: [
                BasicStateStylingBlock(
                    default: CatalogImageGalleryStyles(
                        container: nil,
                        background: nil,
                        border: nil,
                        dimension: nil,
                        flexChild: nil,
                        spacing: nil
                    ),
                    pressed: nil,
                    hovered: nil,
                    disabled: nil
                )
            ],
            mainImage: nil,
            thumbnailImage: nil,
            selectedThumbnailImage: nil,
            thumbnailList: thumbnailList,
            scrollIconButton: nil,
            indicator: nil,
            activeIndicator: nil,
            seenIndicator: nil,
            progressIndicatorContainer: indicatorContainer
        )

        let galleryModel = CatalogImageGalleryModel<WhenPredicate>(
            styles: LayoutStyle(elements: galleryElements, conditionalTransitions: nil),
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
