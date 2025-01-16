//
//  TestCloseButtonComponent.swift
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
final class TestCloseButtonComponent: XCTestCase {
#if compiler(>=6)
    func test_creative_response() throws {
        
        let view = try TestPlaceHolder.make(layoutMaker: LayoutSchemaViewModel.makeCloseButton(layoutState:eventService:))
        
        let closeButton = try view.inspect()
            .view(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(CloseButtonComponent.self)
        
        // test custom modifier class
        let modifierContent = try closeButton
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)

        let paddingModifier = try modifierContent.modifier(PaddingModifier.self).actualView().padding
        
        XCTAssertEqual(paddingModifier, FrameAlignmentProperty(top: 10, right: 10, bottom: 10, left: 10))
        
        // test the effect of custom modifier
        XCTAssertEqual(
            try modifierContent.padding(),
            EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0)
        )

        XCTAssertEqual(
            try closeButton
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .accessibilityLabel()
                .string(),
            "Close button"
        )
    }
#else
    func test_creative_response() throws {
        
        let view = try TestPlaceHolder.make(layoutMaker: LayoutSchemaViewModel.makeCloseButton(layoutState:eventService:))

        let closeButton = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CloseButtonComponent.self)
            .actualView()
            .inspect()
            .hStack()
        
        // test custom modifier class
        let paddingModifier = try closeButton.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 10, right: 10, bottom: 10, left: 10))
        
        // test the effect of custom modifier
        let padding = try closeButton.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0))
        
        XCTAssertEqual(try closeButton.accessibilityLabel().string(), "Close button")
    }

    func test_send_close_event() throws {
        var closeEventCalled = false
        let eventDelegate = MockUXHelper()
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeEventCalled = true
                }
            },
            eventDelegate: eventDelegate,
            layoutMaker: LayoutSchemaViewModel.makeCloseButton(layoutState:eventService:)
        )

        let closeButton = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CloseButtonComponent.self)
            .actualView()

        let sut = closeButton.model
        sut.sendCloseEvent()

        XCTAssertTrue(closeEventCalled)
        XCTAssertTrue(eventDelegate.roktEvents.contains(.PlacementClosed))
        XCTAssertNotNil(sut.layoutState)
    }
#endif
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {
    static func makeCloseButton(
        layoutState: LayoutState,
        eventService: EventService
    ) throws -> Self {
        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(),
            layoutState: layoutState,
            eventService: eventService
        )
        let closeButton = ModelTestData.CloseButtonData.closeButton()
        return LayoutSchemaViewModel.closeButton(
            try transformer.getCloseButton(
                styles: closeButton.styles,
                children: transformer.transformChildren(closeButton.children, slot: nil)
            )
        )
    }
}
