//
//  TestDismissInstantPurchaseButtonComponent.swift
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
final class TestDismissInstantPurchaseButtonComponent: XCTestCase {

    func test_creative_response() throws {

        let view = try TestPlaceHolder
            .make(layoutMaker: LayoutSchemaViewModel.makeDismissInstantPurchaseButton(layoutState:eventService:))

        let dismissInstantPurchaseButton = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DismissInstantPurchaseButtonComponent.self)
            .actualView()
            .inspect()
            .hStack()
        
        // test custom modifier class
        let paddingModifier = try dismissInstantPurchaseButton.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 10, right: 10, bottom: 10, left: 10))
        
        // test the effect of custom modifier
        let padding = try dismissInstantPurchaseButton.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0))
        
        XCTAssertEqual(try dismissInstantPurchaseButton.accessibilityLabel().string(), "Dismiss Instant Purchase")
    }

    func test_send_dismiss_instant_purchase_event() throws {
        var dismissEventCalled = false
        let eventDelegate = MockUXHelper()
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalInstantPurchaseDismissal {
                    dismissEventCalled = true
                }
            },
            eventDelegate: eventDelegate,
            layoutMaker: LayoutSchemaViewModel.makeDismissInstantPurchaseButton(layoutState:eventService:)
        )

        let dismissInstantPurchaseButton = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DismissInstantPurchaseButtonComponent.self)
            .actualView()

        let sut = dismissInstantPurchaseButton.model
        sut.sendDismissInstantPurchaseEvent()

        XCTAssertTrue(dismissEventCalled)
        XCTAssertTrue(eventDelegate.roktEvents.contains(.PlacementClosed))
        XCTAssertNotNil(sut.layoutState)
    }
    
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {
    static func makeDismissInstantPurchaseButton(
        layoutState: LayoutState,
        eventService: EventService
    ) throws -> Self {
        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(),
            layoutState: layoutState,
            eventService: eventService
        )
        let dismissInstantPurchaseButton = ModelTestData.DismissInstantPurchaseButtonData.dismissInstantPurchaseButton()
        return LayoutSchemaViewModel.dismissInstantPurchaseButton(
            try transformer.getDismissInstantPurchaseButton(
                styles: dismissInstantPurchaseButton.styles,
                children: transformer.transformChildren(dismissInstantPurchaseButton.children, context: .outer([]))
            )
        )
    }
}
