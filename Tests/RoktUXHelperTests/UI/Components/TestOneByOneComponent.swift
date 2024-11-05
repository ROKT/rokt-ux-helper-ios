//
//  TestOneByOneComponent.swift
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
final class TestOneByOneComponent: XCTestCase {
    
    func test_one_by_one() throws {
        var closeActionCalled = false
        
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.oneByOne(try get_model(eventHandler: { event in
            
            if event.eventType == .SignalDismissal {
                closeActionCalled = true
            }
        })))
        let oneByOneComponent = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(OneByOneComponent.self)
            .actualView()
        
        let group = try oneByOneComponent
            .inspect()
            .group()
        
        let oneByOne = try group
            .find(LayoutSchemaComponent.self)
        
        // test custom modifier class
        let paddingModifier = try oneByOne.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 3, right: 4, bottom: 5, left: 6))
        
        // test the effect of custom modifier
        let padding = try oneByOne.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 3.0, leading: 6.0, bottom: 5.0, trailing: 4.0))
        
        XCTAssertEqual(try group.accessibilityLabel().string(), "Offer 1 of 1")
        
        oneByOneComponent.goToNextOffer()
        XCTAssertTrue(closeActionCalled)
    }
    
    func test_goToNextOffer_with_closeOnComplete_false() throws {
        var closeActionCalled = false
        var SignalResponseCalled = false
        
        let closeOnCompleteSettings = LayoutSettings(closeOnComplete: false)
        
        let view = TestPlaceHolder(
            layout: LayoutSchemaViewModel.oneByOne(
                try get_model(eventHandler: { event in
                    if event.eventType == .SignalDismissal {
                        closeActionCalled = true
                    } else if event.eventType == .SignalResponse {
                        SignalResponseCalled = true
                    }
                })
            ),
            layoutSettings: closeOnCompleteSettings
        )
        
        let oneByOneComponent = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(OneByOneComponent.self)
            .actualView()

        XCTAssertFalse(SignalResponseCalled)
        
        oneByOneComponent.goToNextOffer()
        XCTAssertFalse(closeActionCalled)
        XCTAssertFalse(SignalResponseCalled)
    }
    
    func get_model(layoutSettings: LayoutSettings? = nil, 
                   eventHandler: @escaping (EventRequest) -> Void) throws -> OneByOneViewModel {
        let eventService = EventService(
            pageId: nil,
            pageInstanceGuid: "",
            sessionId: "",
            pluginInstanceGuid: "",
            pluginId: nil,
            pluginName: nil,
            startDate: Date(),
            uxEventDelegate: MockUXHelper(),
            processor: MockEventProcessor(handler: eventHandler),
            responseReceivedDate: Date(),
            pluginConfigJWTToken: "",
            useDiagnosticEvents: false
        )
        let layoutState = LayoutState()
        layoutState.items[LayoutState.layoutSettingsKey] = layoutSettings
        
        let slots = ModelTestData.PageModelData.withBNF().layoutPlugins?.first?.slots
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots!),
                                            layoutState: layoutState,
                                            eventService: eventService)
        let model = ModelTestData.OneByOneData.oneByOne()
        return try transformer.getOneByOne(oneByOneModel: model!)
    }
}
