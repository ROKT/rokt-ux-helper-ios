//
//  TestOverlayComponent.swift
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
final class TestOverlayComponent: XCTestCase {
    enum LayoutName {
        case singleText, alignSelf, alignWrapper
    }
#if compiler(>=6)
    func testOverlayComponent() throws {
        let view = TestOverlayPlaceholder(layout: try getModel(.singleText))
        
        let zStack = try view.inspect().find(TestOverlayPlaceholder.self)
            .find(OverlayComponent.self)
            .find(ViewType.ZStack.self)
        
        // Outer + Child
        XCTAssertEqual(zStack.count, 2)
        
        // check alignments to be top
        XCTAssertEqual(try zStack.alignment(), .top)
        
        // background
        let backgroundModifier = try zStack.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#520E0A13", dark: "#520E0A13"))
    }
    
    func test_overlayComponent_withFlexEndAlignSelf_andCenterAlignWrapper_isAlignmentFlexEnd() throws {
        let view = TestOverlayPlaceholder(layout: try getModel(.alignSelf))
        
        let zStack = try view.inspect().find(TestOverlayPlaceholder.self)
            .find(OverlayComponent.self)
            .find(ViewType.ZStack.self)
        
        // Outer + Child
        XCTAssertEqual(zStack.count, 2)
        
        // check alignments to be trailing
        XCTAssertEqual(try zStack.alignment().asVerticalType, VerticalAlignment.bottom)
    }
    
    func test_overlayComponent_withCenterAlignWrapper_isAlignmentCenter() throws {
        let view = TestOverlayPlaceholder(layout: try getModel(.alignWrapper))
        
        let zStack = try view.inspect().find(TestOverlayPlaceholder.self)
            .find(OverlayComponent.self)
            .find(ViewType.ZStack.self)
        
        // Outer + Child
        XCTAssertEqual(zStack.count, 2)
        
        // check alignments to be center
        XCTAssertEqual(try zStack.alignment().asVerticalType, VerticalAlignment.center)
    }
#else
    func testOverlayComponent() throws {
        let view = TestOverlayPlaceholder(layout: try getModel(.singleText))
        
        let zStack = try view.inspect().view(TestOverlayPlaceholder.self)
            .view(OverlayComponent.self)
            .actualView()
            .inspect()
            .zStack()
        
        // Outer + Child
        XCTAssertEqual(zStack.count, 2)
        
        // check alignments to be top
        XCTAssertEqual(try zStack.alignment(), .top)
        
        // background
        let backgroundModifier = try zStack.modifier(BackgroundModifier.self)
        let backgroundStyle = try backgroundModifier.actualView().backgroundStyle
        
        XCTAssertEqual(backgroundStyle?.backgroundColor, ThemeColor(light: "#520E0A13", dark: "#520E0A13"))
    }
    
    func test_overlayComponent_withFlexEndAlignSelf_andCenterAlignWrapper_isAlignmentFlexEnd() throws {
        let view = TestOverlayPlaceholder(layout: try getModel(.alignSelf))
        
        let zStack = try view.inspect().view(TestOverlayPlaceholder.self)
            .view(OverlayComponent.self)
            .actualView()
            .inspect()
            .zStack()
        
        // Outer + Child
        XCTAssertEqual(zStack.count, 2)
        
        // check alignments to be trailing
        XCTAssertEqual(try zStack.alignment().asVerticalType, VerticalAlignment.bottom)
    }
    
    func test_overlayComponent_withCenterAlignWrapper_isAlignmentCenter() throws {
        let view = TestOverlayPlaceholder(layout: try getModel(.alignWrapper))
        
        let zStack = try view.inspect().view(TestOverlayPlaceholder.self)
            .view(OverlayComponent.self)
            .actualView()
            .inspect()
            .zStack()
        
        // Outer + Child
        XCTAssertEqual(zStack.count, 2)
        
        // check alignments to be center
        XCTAssertEqual(try zStack.alignment().asVerticalType, VerticalAlignment.center)
    }

#endif

    func getModel(_ layoutName: LayoutName) throws -> OverlayViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let overlay = getOverlayModel(layoutName: layoutName)
        return try transformer.getOverlay(
            overlay.styles,
            allowBackdropToClose: nil,
            children: transformer.transformChildren(overlay.children, context: .outer([]))
        )
    }
    
    func getOverlayModel(layoutName: LayoutName) -> OverlayModel<RichTextModel<WhenPredicate>, WhenPredicate> {
        switch layoutName {
        case .singleText:
            return ModelTestData.OverlayData.singleTextOverlay()
        case .alignWrapper:
            return ModelTestData.OverlayData.alignWrapperCenterOverlay()
        case .alignSelf:
            return ModelTestData.OverlayData.alignSelfFlexEndOverlay()
        }
    }
}
