//
//  TestProgressControlComponent.swift
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
final class TestProgressControlComponent: XCTestCase {
#if compiler(>=6)
    func test_progress_control() throws {
        
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.progressControl(try get_model()))
        
        let progressControl = try view.inspect().find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ProgressControlComponent.self)
        
        let modifierContent = try progressControl.modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)
        
        let paddingModifier = try modifierContent.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 5, right: 5, bottom: 5, left: 5))
        
        // test the effect of custom modifier
        let marginModifier = try modifierContent.modifier(MarginModifier.self)
        XCTAssertEqual(
            try marginModifier.actualView().getMargin(),
            FrameAlignmentProperty(top: 0, right: 10, bottom: 8, left: 20)
        )
        
        XCTAssertEqual(
            try progressControl
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .implicitAnyView()
                .accessibilityLabel()
                .string(),
            "Next page button"
        )
    }
#else
    func test_progress_control() throws {
        
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.progressControl(try get_model()))
        
        let progressControl = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ProgressControlComponent.self)
            .actualView()
            .inspect()
            .hStack()
        
        // test custom modifier class
        let paddingModifier = try progressControl.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 5, right: 5, bottom: 5, left: 5))
        
        // test the effect of custom modifier
        let paddingMargin = try progressControl.padding()
        XCTAssertEqual(paddingMargin, EdgeInsets(top: 5.0, leading: 25.0, bottom: 13.0, trailing: 15.0))
        
        XCTAssertEqual(try progressControl.accessibilityLabel().string(), "Next page button")
    }
#endif
    func get_model() throws -> ProgressControlViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let progressControl = ModelTestData.ProgressControlData.progressControl()
        return try transformer.getProgressControl(styles: progressControl.styles, direction: progressControl.direction,
                                                  children: transformer.transformChildren(
                                                      progressControl.children,
                                                      context: .outer([])
                                                  ))
    }
}
