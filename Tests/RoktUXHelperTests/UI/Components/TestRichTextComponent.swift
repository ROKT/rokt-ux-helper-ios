//
//  TestBasicTextComponent.swift
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
final class TestRichTextComponent: XCTestCase {

    func test_rich_text() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.richText(try get_model()))
        
        let text = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RichTextComponent.self)
            .actualView()
            .inspect()
            .text()
        
        // test custom modifier class
        let paddingModifier = try text.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 1, right: 0, bottom: 1, left: 8))
        
        // test the effect of custom modifier
        let padding = try text.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 1.0, leading: 8.0, bottom: 17.0, trailing: 0.0))
        
        let model = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RichTextComponent.self)
            .actualView()
            .model
        let nsAttrString = model.attributedString
        
        XCTAssertEqual(nsAttrString.string, "ORDER Number: Uk171359906")
        
        // space-agnostic colour comparison
        let foregroundColor = nsAttrString.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertEqual(foregroundColor?.isEqualIgnoringSpaceContext(UIColor(hexString: "#AABBCC")), true)
        
        let font = nsAttrString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)
        
        let underlineRange = NSRange(location: 0, length: 5)
        let underlineText = nsAttrString.attributedSubstring(from: underlineRange)
        
        underlineText.enumerateAttributes(in: underlineRange, options: []) { (dict, _, _) in
            XCTAssertTrue(dict.keys.contains(.underlineStyle))
        }
        
        let strikeThroughRange = NSRange(location: 6, length: 6)
        let strikeThroughText = nsAttrString.attributedSubstring(from: strikeThroughRange)
        let strikeThroughTextRange = NSRange(location: 0, length: 6)
        
        strikeThroughText.enumerateAttributes(in: strikeThroughTextRange, options: []) { (dict, _, _) in
            XCTAssertTrue(dict.keys.contains(.strikethroughStyle))
        }
        
        // raw richtext
        let rawText = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RichTextComponent.self)
            .actualView()
        XCTAssertNil(rawText.linkStyle)
        
        XCTAssertEqual(rawText.horizontalAlignment, .start)

        XCTAssertNil(rawText.lineLimit)
        
        XCTAssertEqual(rawText.lineHeightPadding, 0)
        XCTAssertEqual(rawText.lineHeight, 0)
    }
    
    func test_rich_text_with_state() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.richText(try get_state_model()))
        
        let text = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RichTextComponent.self)
            .actualView()
            .inspect()
            .text()
        
        // test custom modifier class
        let paddingModifier = try text.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 1, right: 0, bottom: 1, left: 8))
        
        // test the effect of custom modifier
        let padding = try text.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 1.0, leading: 8.0, bottom: 17.0, trailing: 0.0))
        
        let model = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RichTextComponent.self)
            .actualView()
            .model
        let nsAttrString = model.attributedString
        //before state replacement
        XCTAssertEqual(nsAttrString.string, "%^STATE.IndicatorPosition^% ORDER Number:")
        
        // space-agnostic colour comparison
        let foregroundColor = nsAttrString.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertEqual(foregroundColor?.isEqualIgnoringSpaceContext(UIColor(hexString: "#AABBCC")), true)
        
        let font = nsAttrString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), false)
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), false)

        // check min/max width/height
        let flexFrame = try text.flexFrame()
        XCTAssertEqual(flexFrame.minWidth, 10)
        XCTAssertEqual(flexFrame.maxWidth, 100)
        XCTAssertEqual(flexFrame.minHeight, 15)
        XCTAssertEqual(flexFrame.maxHeight, 150)
        
        // raw richtext
        let rawText = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(RichTextComponent.self)
            .actualView()
        XCTAssertNil(rawText.linkStyle)
        
        XCTAssertEqual(rawText.horizontalAlignment, .start)
        // after state replacement
        XCTAssertEqual(rawText.model.stateReplacedAttributedString.string, "1 ORDER Number:")
        let colors = rawText.model.stateReplacedAttributedString.attribute(
            .foregroundColor,
            at: 0,
            effectiveRange: nil
        ) as? UIColor
        XCTAssertEqual(colors?.isEqualIgnoringSpaceContext(UIColor(hexString: "#AABBCC")), true)
        XCTAssertNil(rawText.lineLimit)
        
        XCTAssertEqual(rawText.lineHeightPadding, 0)
        XCTAssertEqual(rawText.lineHeight, 0)
    }
    
    func test_rich_text_with_app_config() throws {
        if let model = try get_dark_config_model() {
            
            let view = TestPlaceHolder(layout: model)
            
            let text = try view.inspect()
                .view(TestPlaceHolder.self)
                .view(EmbeddedComponent.self)
                .vStack()[0]
                .view(LayoutSchemaComponent.self)
                .view(RichTextComponent.self)
                .actualView()
                .inspect()
                .text()
            
            // test custom modifier class
            let paddingModifier = try text.modifier(PaddingModifier.self)
            XCTAssertEqual(
                try paddingModifier.actualView().padding,
                FrameAlignmentProperty(top: 1, right: 0, bottom: 1, left: 8)
            )
            
            // test the effect of custom modifier
            let padding = try text.padding()
            XCTAssertEqual(padding, EdgeInsets(top: 1.0, leading: 8.0, bottom: 17.0, trailing: 0.0))
            
            let model = try view.inspect()
                .view(TestPlaceHolder.self)
                .view(EmbeddedComponent.self)
                .vStack()[0]
                .view(LayoutSchemaComponent.self)
                .view(RichTextComponent.self)
                .actualView()
                .model
            let nsAttrString = model.attributedString

            XCTAssertEqual(nsAttrString.string, "ORDER Number: Uk171359906")
            
            // Test color mode to be dark
            let foregroundColor = nsAttrString.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
            XCTAssertEqual(foregroundColor?.isEqualIgnoringSpaceContext(UIColor(hexString: "#000000")), true)
        }
    }
    
    // MARK: - Snapshots

    func testSnapshot() throws {
        assertRichTextSnapshot(try get_model(), width: 350, height: 350)
    }

    func testSnapshot_nilDefaultStyle() {
        let model = RichTextViewModel(
            value: "<b>Bold</b> and <i>italic</i> with <a href='https://rokt.com'>a link</a>",
            defaultStyle: nil,
            openLinks: nil,
            layoutState: LayoutState(),
            eventService: nil
        )
        assertRichTextSnapshot(model)
    }

    func testSnapshot_nilTextStyle() {
        let model = RichTextViewModel(
            value: "<b>Bold</b> and <i>italic</i> text",
            defaultStyle: [RichTextStyle(dimension: nil, flexChild: nil, spacing: nil, background: nil, text: nil)],
            openLinks: nil,
            layoutState: LayoutState(),
            eventService: nil
        )
        assertRichTextSnapshot(model)
    }

    // MARK: - Helpers

    private func assertRichTextSnapshot(
        _ model: RichTextViewModel,
        colorMode: RoktUXConfig.ColorMode? = .light,
        width: CGFloat = 350,
        height: CGFloat = 200,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        model.transformValueToAttributedString(colorMode)
        waitForAttributedStringConversion(on: model, timeout: 2.0)

        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.richText(model))
            .frame(width: width, height: height)

        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(of: hostingController, as: .image(on: snapshotDevice), file: file, line: line)
    }
    
    // MARK: - Nil / empty defaultStyle tests

    func test_rich_text_nil_default_style_still_parses_html() {
        let html = "<b>Bold</b> and <i>italic</i>"
        let model = RichTextViewModel(
            value: html,
            defaultStyle: nil,
            openLinks: nil,
            layoutState: LayoutState(),
            eventService: nil
        )
        model.transformValueToAttributedString(.light)
        waitForAttributedStringConversion(on: model, timeout: 2.0)

        XCTAssertEqual(model.attributedString.string, "Bold and italic")
        XCTAssertFalse(model.attributedString.string.contains("<b>"))
        XCTAssertFalse(model.attributedString.string.contains("<i>"))
    }

    func test_rich_text_empty_default_style_still_parses_html() {
        let html = "<b>Bold</b> and <i>italic</i>"
        let model = RichTextViewModel(
            value: html,
            defaultStyle: [],
            openLinks: nil,
            layoutState: LayoutState(),
            eventService: nil
        )
        model.transformValueToAttributedString(.light)
        waitForAttributedStringConversion(on: model, timeout: 2.0)

        XCTAssertEqual(model.attributedString.string, "Bold and italic")
        XCTAssertFalse(model.attributedString.string.contains("<b>"))
    }

    func test_rich_text_nil_text_property_still_parses_html() {
        let html = "<b>Bold</b> text"
        let style = RichTextStyle(dimension: nil, flexChild: nil, spacing: nil, background: nil, text: nil)
        let model = RichTextViewModel(
            value: html,
            defaultStyle: [style],
            openLinks: nil,
            layoutState: LayoutState(),
            eventService: nil
        )
        model.transformValueToAttributedString(.light)
        waitForAttributedStringConversion(on: model, timeout: 2.0)

        XCTAssertEqual(model.attributedString.string, "Bold text")
        XCTAssertFalse(model.attributedString.string.contains("<b>"))
    }

    func test_rich_text_nil_default_style_strips_tags_without_font() {
        let html = "<b>Bold</b> normal"
        let model = RichTextViewModel(
            value: html,
            defaultStyle: nil,
            openLinks: nil,
            layoutState: LayoutState(),
            eventService: nil
        )
        model.transformValueToAttributedString(.light)
        waitForAttributedStringConversion(on: model, timeout: 2.0)

        XCTAssertEqual(model.attributedString.string, "Bold normal")
        // The WebKit morphing code strips the font when uiFont is nil
        // (it removes Times New Roman but has no replacement font to apply).
        // Bold traits are only preserved when a campaign uiFont is provided.
        let font = model.attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNil(font)
    }

    func test_rich_text_nil_default_style_preserves_link() {
        let html = "Click <a href='https://rokt.com'>here</a>"
        let model = RichTextViewModel(
            value: html,
            defaultStyle: nil,
            openLinks: nil,
            layoutState: LayoutState(),
            eventService: nil
        )
        model.transformValueToAttributedString(.light)
        waitForAttributedStringConversion(on: model, timeout: 2.0)

        XCTAssertEqual(model.attributedString.string, "Click here")
        let link = model.attributedString.attribute(.link, at: 6, effectiveRange: nil)
        XCTAssertNotNil(link)
    }

    func get_model() throws -> RichTextViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let richText = try transformer.getRichText(ModelTestData.TextData.richTextHTML(), context: .outer([]))
        richText.transformValueToAttributedString(.light)
        waitForAttributedStringConversion(on: richText, timeout: 2.0)
        return richText
    }

    func get_state_model() throws -> RichTextViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        let richText = try transformer.getRichText(ModelTestData.TextData.richTextState(), context: .outer([]))
        richText.transformValueToAttributedString(.light)
        waitForAttributedStringConversion(on: richText, timeout: 2.0)
        return richText
    }

    private func waitForAttributedStringConversion(on model: RichTextViewModel, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while model.attributedString.string.isEmpty && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }
    
    func get_dark_config_model() throws -> LayoutSchemaViewModel? {
        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(),
            layoutState: .init(
                config: RoktUXConfig.Builder().colorMode(.dark).build()
            )
        )
        return try transformer.transform()
    }
}

extension UIColor {
    func isEqualIgnoringSpaceContext(_ otherColor: UIColor) -> Bool {
        guard let selfAsCGColor = self.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
            else {
            XCTFail("Could not convert to cgColor \(self)")
            return false
        }
        
        guard let otherAsCGColor = otherColor.cgColor.converted(
            to: CGColorSpaceCreateDeviceRGB(),
            intent: .defaultIntent,
            options: nil
        ) else {
            XCTFail("Could not convert to cgColor \(otherColor)")
            return false
        }
        
        return selfAsCGColor == otherAsCGColor
    }
}
