//
//  TestProgressIndicatorComponent.swift
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
final class TestProgressIndicatorComponent: XCTestCase {
#if compiler(>=6)
    func test_progress_indicator() throws {
        let progressIndicatorUIModel = try get_model(model: ModelTestData.ProgressIndicatorData.progressIndicatorUI())
        progressIndicatorUIModel.updateDataBinding(dataBinding: .value(progressIndicatorUIModel.indicator))

        let view = TestPlaceHolder(layout: .progressIndicator(progressIndicatorUIModel))

        let progressIndicator = try view.inspect()
            .find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ProgressIndicatorComponent.self)
        
        let modifierContent = try progressIndicator
            .modifierIgnoreAny(LayoutSchemaModifier.self)
            .ignoreAny(ViewType.ViewModifierContent.self)
        
        let paddingModifier = try modifierContent.modifier(PaddingModifier.self)
        XCTAssertEqual(
            try paddingModifier.actualView().padding,
            FrameAlignmentProperty(top: 10, right: 10, bottom: 10, left: 10))
        
        // test the effect of custom modifier
        let padding = try modifierContent.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0))
        
        let hStack = try progressIndicator.find(ViewType.HStack.self)
        XCTAssertEqual(try hStack.accessibilityLabel().string(), "1 of 1")
        XCTAssertEqual(try hStack.accessibilityHidden(), false)
    }
    
    func test_start_position_progress_indicator() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.progressIndicator(try get_model(
            model: ModelTestData.ProgressIndicatorData.startPosition())))
        
        let progressIndicatorComponent = try view.inspect()
            .find(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ProgressIndicatorComponent.self)
        
        // test page indicator is empty view as startPosition=2
        XCTAssertNotNil(try progressIndicatorComponent.find(ViewType.EmptyView.self))
        XCTAssertEqual(try progressIndicatorComponent.actualView().startIndex, 1)
        
    }
    
    func test_progress_indicator_with_accessibilityhidden() throws {
        let progressIndicatorUIModel = try get_model(model: ModelTestData.ProgressIndicatorData.accessibilityHidden())
        progressIndicatorUIModel.updateDataBinding(dataBinding: .value(progressIndicatorUIModel.indicator))

        let view = TestPlaceHolder(layout: .progressIndicator(progressIndicatorUIModel))
        
        let progressIndicator = try view.inspect()
            .view(TestPlaceHolder.self)
            .find(EmbeddedComponent.self)
            .find(ViewType.VStack.self)[0]
            .find(LayoutSchemaComponent.self)
            .find(ProgressIndicatorComponent.self)
            .find(ViewType.HStack.self)
        
        XCTAssertEqual(try progressIndicator.accessibilityHidden(), true)
    }
#else
    func test_progress_indicator() throws {
        let progressIndicatorUIModel = try get_model(model: ModelTestData.ProgressIndicatorData.progressIndicatorUI())
        progressIndicatorUIModel.updateDataBinding(dataBinding: .value(progressIndicatorUIModel.indicator))

        let view = TestPlaceHolder(layout: .progressIndicator(progressIndicatorUIModel))

        let progressIndicator = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ProgressIndicatorComponent.self)
            .actualView()
            .inspect()
            .hStack()
        
        // test custom modifier class
        let paddingModifier = try progressIndicator.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 10, right: 10, bottom: 10, left: 10))
        
        // test the effect of custom modifier
        let padding = try progressIndicator.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0))
        
        XCTAssertEqual(try progressIndicator.accessibilityLabel().string(), "1 of 1")
        XCTAssertEqual(try progressIndicator.accessibilityHidden(), false)
    }
    
    func test_start_position_progress_indicator() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.progressIndicator(try get_model(
            model: ModelTestData.ProgressIndicatorData.startPosition())))
        
        let progressIndicatorComponent = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ProgressIndicatorComponent.self)
            .actualView()
        
        let progressIndicatorView = try progressIndicatorComponent
            .inspect()
        
        // test page indicator is empty view as startPosition=2
        XCTAssertNotNil(try progressIndicatorView.emptyView())
        XCTAssertEqual(progressIndicatorComponent.startIndex, 1)
    }
    
    func test_progress_indicator_with_accessibilityhidden() throws {
        let progressIndicatorUIModel = try get_model(model: ModelTestData.ProgressIndicatorData.accessibilityHidden())
        progressIndicatorUIModel.updateDataBinding(dataBinding: .value(progressIndicatorUIModel.indicator))

        let view = TestPlaceHolder(layout: .progressIndicator(progressIndicatorUIModel))
        
        let progressIndicator = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(ProgressIndicatorComponent.self)
            .actualView()
            .inspect()
            .hStack()
        
        XCTAssertEqual(try progressIndicator.accessibilityHidden(), true)
    }
#endif
    func get_model(model: ProgressIndicatorModel<WhenPredicate>) throws -> ProgressIndicatorViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        return try transformer.getProgressIndicatorUIModel(model)
    }
}
