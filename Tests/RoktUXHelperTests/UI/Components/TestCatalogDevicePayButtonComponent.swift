//
//  TestCatalogDevicePayButtonComponent.swift
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
final class TestCatalogDevicePayButtonComponent: XCTestCase {

    func test_creative_response() throws {

        let view = try TestPlaceHolder
            .make(layoutMaker: LayoutSchemaViewModel.makeCatalogDevicePayButton(layoutState:eventService:))

        let catalogDevicePayButton = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogDevicePayButtonComponent.self)
            .actualView()
            .inspect()
            .hStack()

        // test custom modifier class
        let paddingModifier = try catalogDevicePayButton.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 5, right: 5, bottom: 5, left: 5))
        let marginModifier = try catalogDevicePayButton.modifier(MarginModifier.self)
        XCTAssertEqual(
            try marginModifier.actualView().getMargin(),
            FrameAlignmentProperty(top: 24, right: 0, bottom: 24, left: 0)
        )

        // test the effect of custom modifier
        let padding = try catalogDevicePayButton.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 29.0, leading: 5.0, bottom: 29.0, trailing: 5.0))
    }

    func test_send_ux_event() throws {
        var signalCartItemInitiatedCalled = false
        let eventDelegate = MockUXHelper()
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalCartItemStripePayInitiated {
                    signalCartItemInitiatedCalled = true
                }
            },
            eventDelegate: eventDelegate,
            layoutMaker: LayoutSchemaViewModel.makeCatalogDevicePayButton(layoutState:eventService:)
        )

        let catalogDevicePayButton = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogDevicePayButtonComponent.self)
            .actualView()

        let sut = catalogDevicePayButton.model
        sut.cartItemDevicePay()

        XCTAssertTrue(eventDelegate.roktEvents.contains(.CartItemStripePay))
        XCTAssertTrue(signalCartItemInitiatedCalled)
        XCTAssertNotNil(sut.layoutState)
    }
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {
    static func makeCatalogDevicePayButton(
        layoutState: LayoutState,
        eventService: EventService
    ) throws -> Self {
        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(),
            layoutState: layoutState,
            eventService: eventService
        )
        let catalogDevicePayButton = ModelTestData.CatalogDevicePayButtonData.catalogDevicePayButton()

        guard let catalogItem = ModelTestData.CatalogPageModelData.withBNF().layoutPlugins?.first?.slots.first?.offer?
            .catalogItems?.first else {
            XCTFail("Couldn't get catalog item")
            throw LayoutTransformerError.InvalidMapping()
        }
        return LayoutSchemaViewModel.catalogDevicePayButton(
            try transformer.getCatalogDevicePayButtonModel(
                style: catalogDevicePayButton.styles,
                children: transformer.transformChildren(
                    catalogDevicePayButton.children,
                    context: .inner(.addToCart(catalogItem))
                ),
                provider: catalogDevicePayButton.provider,
                context: .inner(.addToCart(catalogItem))
            )
        )
    }
}
