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
import SnapshotTesting

@available(iOS 15.0, *)
final class TestOneByOneComponent: XCTestCase {
#if compiler(>=6)
    func test_one_by_one() throws {
        var closeActionCalled = false
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeOneByOne(layoutState:eventService:)
        )
        let oneByOneComponent = try view.inspect().find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(OneByOneComponent.self)
        
        let group = try oneByOneComponent
            .ignoreAny(ViewType.Group.self)
        
        let modifierContent = try group[0].modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)
        let paddingModifier = try modifierContent.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 3, right: 4, bottom: 5, left: 6))
        
        let padding = try modifierContent.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 3.0, leading: 6.0, bottom: 5.0, trailing: 4.0))

        XCTAssertEqual(try group.accessibilityLabel().string(), "Offer 1 of 1")
        
        try oneByOneComponent.actualView().goToNextOffer()
        XCTAssertTrue(closeActionCalled)
    }
    
    func test_goToNextOffer_with_closeOnComplete_false() throws {
        var closeActionCalled = false
        var SignalResponseCalled = false
        
        let closeOnCompleteSettings = LayoutSettings(closeOnComplete: false)
        
        let view = try TestPlaceHolder.make(
            layoutSettings: closeOnCompleteSettings,
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                } else if event.eventType == .SignalResponse {
                    SignalResponseCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeOneByOne(layoutState:eventService:)
        )

        let oneByOneComponent = try view.inspect().find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(OneByOneComponent.self)
            .actualView()

        XCTAssertFalse(SignalResponseCalled)
        
        oneByOneComponent.goToNextOffer()
        XCTAssertFalse(closeActionCalled)
        XCTAssertFalse(SignalResponseCalled)
        
    }

#else

    func test_one_by_one() throws {
        var closeActionCalled = false
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeOneByOne(layoutState:eventService:)
        )
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

        let view = try TestPlaceHolder.make(
            layoutSettings: closeOnCompleteSettings,
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                } else if event.eventType == .SignalResponse {
                    SignalResponseCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeOneByOne(layoutState:eventService:)
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
#endif
    
    func testSnapshot() throws {
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
//                    closeActionCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeOneByOne(layoutState:eventService:)
        )
            .frame(width: 350, height: 350)
        
        let hostingController = UIHostingController(rootView: view)
        let expectation = XCTestExpectation(description: "Wait for SwiftUI rendering")

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                assertSnapshot(of: hostingController, as: .image)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 3.0)
    }
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {

    static func makeOneByOne(
        layoutState: LayoutState,
        eventService: EventService
    ) throws -> Self {
        let slots = ModelTestData.PageModelData.withBNF().layoutPlugins?.first?.slots
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots!),
                                            layoutState: layoutState,
                                            eventService: eventService)
        let model = ModelTestData.OneByOneData.oneByOne()
        return LayoutSchemaViewModel.oneByOne(try transformer.getOneByOne(
            oneByOneModel: model!,
            context: .outer(slots!.map(\.offer))
        ))
    }
}
