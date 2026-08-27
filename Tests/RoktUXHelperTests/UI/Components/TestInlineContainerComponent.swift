import Combine
import DcuiSchema
import SnapshotTesting
import SwiftUI
import XCTest
@testable import RoktUXHelper

@MainActor
final class TestInlineContainerComponent: XCTestCase {
    func testTextAndToggleShareTheSameLineAndBaseline() throws {
        let model = InlineContainerViewModel(children: [.text(text("Description ")), .toggle(toggle(), label: [text("Expand")])])
        let view = render(model, width: 350)
        XCTAssertEqual(view.text, "Description Expand")
        let copy = try XCTUnwrap(view.rects(for: view.runs[0].range).first)
        let action = try XCTUnwrap(view.rects(for: view.runs[1].range).first)
        XCTAssertEqual(copy.minY, action.minY, accuracy: 0.5)
        XCTAssertEqual(copy.height, action.height, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(action.minX, copy.maxX - 0.5)
    }

    func testNarrowWidthsWrapBothCopyAndActionLabels() {
        let model = InlineContainerViewModel(children: [
            .text(text("A description with enough words to wrap naturally. ")),
            .toggle(toggle(), label: [text("A localized action label that also wraps")])
        ])
        let view = render(model, width: 120)
        XCTAssertGreaterThan(view.rects(for: view.runs[0].range).count, 1)
        XCTAssertGreaterThan(view.rects(for: view.runs[1].range).count, 1)
        let narrowHeight = view.measuredHeight(for: 120)
        let wideHeight = view.measuredHeight(for: 400)
        XCTAssertGreaterThan(narrowHeight, wideHeight)
        XCTAssertFalse(view.isScrollEnabled)
    }

    func testWrappedUnicodeActionRangesHitOnlyTheirOwnAction() throws {
        let events = InlineEventService()
        let model = InlineContainerViewModel(children: [
            .text(text("👩🏽‍🚀 e\u{301} 🇺🇸 " + String(repeating: "copy ", count: 5))),
            .link(link(events), label: [text("Open a localized destination")]),
            .text(text(" ")),
            .toggle(toggle(events: events), label: [text("Change content")])
        ])
        let view = render(model, width: 130)
        let linkRun = view.runs[1]
        let toggleRun = view.runs[3]
        XCTAssertGreaterThan(linkRun.range.location, model.children[0].texts[0].boundValue.count)
        for rect in view.rects(for: linkRun.range) {
            XCTAssertEqual(view.actionRun(at: CGPoint(x: rect.midX, y: rect.midY))?.id, linkRun.id)
        }
        for rect in view.rects(for: toggleRun.range) {
            XCTAssertEqual(view.actionRun(at: CGPoint(x: rect.midX, y: rect.midY))?.id, toggleRun.id)
        }
        XCTAssertNil(view.actionRun(at: CGPoint(x: -1, y: -1)))
        XCTAssertTrue(view.activateRun(id: linkRun.id))
        XCTAssertTrue(events.openURLCalled)
        XCTAssertEqual(events.interactionCount, 0)
        XCTAssertTrue(view.activateRun(id: toggleRun.id))
        XCTAssertEqual(events.interactionCount, 1)
    }

    func testSmallActionHasAnEnlargedTapTargetWithoutASeparateButtonRow() throws {
        let model = InlineContainerViewModel(children: [.text(text("Copy ")), .toggle(toggle(), label: [text("Go")])])
        let view = render(model, width: 250)
        let run = view.runs[1]
        let rect = try XCTUnwrap(view.rects(for: run.range).first)
        XCTAssertGreaterThanOrEqual(view.bounds.height, 44)
        XCTAssertEqual(view.actionRun(at: CGPoint(x: rect.midX, y: rect.midY + 20))?.id, run.id)
        XCTAssertEqual(view.actionRun(at: CGPoint(x: rect.midX, y: rect.midY - 20))?.id, run.id)
    }

    func testVoiceOverReadsCopyThenDistinctLinkAndButtonWithoutFullTextDuplication() throws {
        let events = InlineEventService()
        let model = InlineContainerViewModel(children: [
            .text(text("Read the details. ")),
            .link(link(events), label: [text("Terms")], accessibilityLabel: "Open terms"),
            .toggle(toggle(events: events), label: [text("Change"), text(" content")])
        ])
        let view = render(model, width: 240)
        XCTAssertFalse(view.isAccessibilityElement)
        let elements = try XCTUnwrap(view.accessibilityElements as? [UIAccessibilityElement])
        XCTAssertEqual(elements.map(\.accessibilityLabel), ["Read the details. ", "Open terms", "Change content"])
        XCTAssertEqual(elements[0].accessibilityTraits, .staticText)
        XCTAssertEqual(elements[1].accessibilityTraits, .link)
        XCTAssertEqual(elements[2].accessibilityTraits, .button)
        XCTAssertTrue(elements[1].accessibilityActivate())
        XCTAssertTrue(events.openURLCalled)
        XCTAssertEqual(events.interactionCount, 0)
        XCTAssertTrue(elements[2].accessibilityActivate())
        XCTAssertEqual(events.interactionCount, 1)
    }

    func testDisabledActionsCannotActivateFromTouchOrAccessibility() throws {
        let events = InlineEventService()
        let model = InlineContainerViewModel(children: [.toggle(toggle(events: events), label: [text("Change")])])
        let view = render(model, width: 250)
        let run = view.runs[0]
        let rect = try XCTUnwrap(view.rects(for: run.range).first)
        view.actionsEnabled = false
        XCTAssertNil(view.actionRun(at: CGPoint(x: rect.midX, y: rect.midY)))
        XCTAssertFalse(view.activateRun(id: run.id))
        let element = try XCTUnwrap(view.accessibilityElements?.first as? UIAccessibilityElement)
        XCTAssertTrue(element.accessibilityTraits.contains(.notEnabled))
        XCTAssertFalse(element.accessibilityActivate())
        XCTAssertEqual(events.interactionCount, 0)
    }

    func testToggleReusesOfferScopedCustomStateAndEmitsOneInteractionPerActivation() {
        let events = InlineEventService()
        let state = MockLayoutState()
        var identifiers: [CustomStateIdentifiable] = []
        state.actionCollection[.toggleCustomState] = { value in
            if let identifier = value as? CustomStateIdentifiable { identifiers.append(identifier) }
        }
        var progressed = false
        state.actionCollection[.nextOffer] = { _ in progressed = true }
        let button = toggle(events: events, state: state)
        let model = InlineContainerViewModel(children: [.toggle(button, label: [text("Change")])])
        let view = render(model, width: 250, position: 2)
        XCTAssertTrue(view.activateRun(id: button.id))
        XCTAssertTrue(view.activateRun(id: button.id))
        XCTAssertEqual(identifiers, [CustomStateIdentifiable(position: 2, key: "details"),
                                     CustomStateIdentifiable(position: 2, key: "details")])
        XCTAssertEqual(events.interactionCount, 2)
        XCTAssertEqual(events.lastLayoutUserInteractionAction, .ToggleButtonStateTriggerClick)
        XCTAssertEqual(events.lastLayoutUserInteractionContext, .ToggleButtonStateTrigger)
        XCTAssertFalse(events.openURLCalled)
        XCTAssertFalse(events.cartItemInstantPurchaseCalled)
        XCTAssertFalse(progressed)
        update(view, model: model, width: 250, position: 3)
        XCTAssertTrue(view.activateRun(id: button.id))
        XCTAssertEqual(identifiers.last, CustomStateIdentifiable(position: 3, key: "details"))
        XCTAssertEqual(events.interactionCount, 3)
    }

    func testMixedStylesDarkModeAndDynamicType() throws {
        let style = try JSONDecoder().decode(BasicTextStyle.self,
                                             from: Data(##"{"text":{"fontSize":18,"fontWeight":"700","fontStyle":"italic","baselineTextAlign":"super","letterSpacing":2,"textDecoration":"underline","textColor":{"light":"#000000","dark":"#ffffff"}}}"##
                                             .utf8))
        let model = InlineContainerViewModel(children: [.text(text("Plain ")), .text(text("Styled", style: style))])
        let normal = model.textContent(position: nil, colorScheme: .light, contentSize: .large, layoutDirection: .leftToRight)
        let large = model.textContent(position: nil, colorScheme: .dark,
                                      contentSize: .accessibilityExtraExtraExtraLarge, layoutDirection: .leftToRight)
        let index = normal.runs[1].range.location
        let normalFont = try XCTUnwrap(normal.text.attribute(.font, at: index, effectiveRange: nil) as? UIFont)
        let largeFont = try XCTUnwrap(large.text.attribute(.font, at: index, effectiveRange: nil) as? UIFont)
        XCTAssertGreaterThan(largeFont.pointSize, normalFont.pointSize)
        XCTAssertEqual(largeFont.pointSize, Float(18).getAsScaledFontSize(contentSize: .accessibilityExtraExtraExtraLarge),
                       accuracy: 0.01)
        XCTAssertTrue(normalFont.fontDescriptor.symbolicTraits.contains(.traitItalic))
        XCTAssertEqual(normal.text.attribute(.underlineStyle, at: index, effectiveRange: nil) as? Int, 1)
        XCTAssertEqual(normal.text.attribute(.kern, at: index, effectiveRange: nil) as? CGFloat, 2)
        XCTAssertGreaterThan(try XCTUnwrap(normal.text.attribute(.baselineOffset, at: index, effectiveRange: nil) as? CGFloat), 0)
        XCTAssertEqual(normal.text.attribute(.foregroundColor, at: index, effectiveRange: nil) as? UIColor,
                       UIColor(hexString: "#000000"))
        XCTAssertEqual(large.text.attribute(.foregroundColor, at: index, effectiveRange: nil) as? UIColor,
                       UIColor(hexString: "#ffffff"))
    }

    func testNaturalLineMetricsFitMixedFontsAndLargeDynamicType() throws {
        let copyStyle = try JSONDecoder().decode(BasicTextStyle.self, from: Data(#"{"text":{"fontSize":14}}"#.utf8))
        let actionStyle = try JSONDecoder().decode(BasicTextStyle.self, from: Data(#"{"text":{"fontSize":24}}"#.utf8))
        let model = InlineContainerViewModel(children: [
            .text(text("Description ", style: copyStyle)),
            .toggle(toggle(), label: [text("Change", style: actionStyle)])
        ])
        let normal = render(model, width: 350)
        let copyGlyph = normal.layoutManager.glyphIndexForCharacter(at: normal.runs[0].range.location)
        let actionGlyph = normal.layoutManager.glyphIndexForCharacter(at: normal.runs[1].range.location)
        XCTAssertEqual(normal.layoutManager.location(forGlyphAt: copyGlyph).y,
                       normal.layoutManager.location(forGlyphAt: actionGlyph).y, accuracy: 0.5)

        let large = render(model, width: 150, contentSize: .accessibilityExtraExtraExtraLarge)
        XCTAssertGreaterThan(large.bounds.height, normal.bounds.height)
        let glyphs = large.layoutManager.glyphRange(for: large.textContainer)
        large.layoutManager.enumerateLineFragments(forGlyphRange: glyphs) { rect, _, _, range, _ in
            let characters = large.layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: nil)
            large.textStorage.enumerateAttribute(.font, in: characters) { value, _, _ in
                guard let font = value as? UIFont else { return }
                XCTAssertGreaterThanOrEqual(rect.height, font.lineHeight - 1)
            }
        }
        XCTAssertGreaterThanOrEqual(large.bounds.height,
                                    large.layoutManager.usedRect(for: large.textContainer).maxY)
    }

    func testRightToLeftContentRetainsLogicalAccessibilityOrderAndActionRanges() throws {
        let model = InlineContainerViewModel(children: [
            .text(text("وصف قصير ")),
            .toggle(toggle(), label: [text("عرض التفاصيل")])
        ])
        let view = render(model, width: 140, direction: .rightToLeft)
        let paragraph = try XCTUnwrap(view.attributedText.attribute(.paragraphStyle, at: 0,
                                                                    effectiveRange: nil) as? NSParagraphStyle)
        XCTAssertEqual(paragraph.baseWritingDirection, .rightToLeft)
        let action = view.runs[1]
        for rect in view.rects(for: action.range) {
            XCTAssertEqual(view.actionRun(at: CGPoint(x: rect.midX, y: rect.midY))?.id, action.id)
        }
        let elements = try XCTUnwrap(view.accessibilityElements as? [UIAccessibilityElement])
        XCTAssertEqual(elements.map(\.accessibilityLabel), ["وصف قصير ", "عرض التفاصيل"])
    }

    func testUpdatingTextChangesHeightAndEmptyContentRemovesOldActions() {
        let copy = text("Short ")
        let model = InlineContainerViewModel(children: [.text(copy), .toggle(toggle(), label: [text("Change")])])
        let view = render(model, width: 180)
        let originalHeight = view.bounds.height
        copy.updateDataBinding(dataBinding: .value(String(repeating: "Longer description ", count: 20)))
        update(view, model: model, width: 180)
        XCTAssertGreaterThan(view.bounds.height, originalHeight)
        view.setContent(InlineTextContent(text: NSAttributedString(string: ""), runs: []), accessibilityLabel: nil)
        XCTAssertEqual(view.measuredHeight(for: 180), 0)
        XCTAssertEqual(view.accessibilityElements?.count, 0)
        XCTAssertNil(view.actionRun(at: CGPoint(x: 10, y: 10)))
    }

    func testModelPublishesChangesFromExistingTextBinding() {
        let copy = text("Before")
        let model = InlineContainerViewModel(children: [.text(copy)])
        var changes = 0
        let subscription = model.objectWillChange.sink { changes += 1 }
        copy.updateDataBinding(dataBinding: .value("After"))
        XCTAssertGreaterThan(changes, 0)
        XCTAssertEqual(model.textContent(position: nil, colorScheme: .light,
                                         contentSize: .large, layoutDirection: .leftToRight).text.string, "After")
        withExtendedLifetime(subscription) {}
    }

    func testHeightUpdatesCoalesceAndDoNotRepublishTheSameHeight() {
        let coordinator = InlineTextRepresentable.Coordinator()
        var value: CGFloat = 0
        var writes = 0
        let binding = Binding<CGFloat>(get: { value }, set: { value = $0; writes += 1 })
        coordinator.publish(80, to: binding)
        coordinator.publish(120, to: binding)
        let updated = expectation(description: "latest height published")
        DispatchQueue.main.async {
            XCTAssertEqual(value, 120)
            XCTAssertEqual(writes, 1)
            coordinator.publish(120, to: binding)
            DispatchQueue.main.async {
                XCTAssertEqual(writes, 1)
                updated.fulfill()
            }
        }
        waitForExpectations(timeout: 2)
    }

    func testSwiftUIHostResizesWhenInlineCopyChanges() {
        let copy = text("Short copy ")
        let model = InlineContainerViewModel(children: [.text(copy), .toggle(toggle(), label: [text("Change")])])
        let screen = GlobalScreenSize()
        screen.width = 300
        let component = InlineContainerComponent(config: ComponentConfig(parent: .root, position: 0), model: model,
                                                 parentWidth: .constant(nil), parentHeight: .constant(nil),
                                                 parentOverride: nil).environmentObject(screen)
        let host = UIHostingController(rootView: component)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 800))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        let ready = expectation(for: NSPredicate { _, _ in
            self.inlineView(in: host.view)?.bounds.height ?? 0 > 0
        }, evaluatedWith: host)
        wait(for: [ready], timeout: 3)
        let originalHeight = inlineView(in: host.view)?.bounds.height ?? 0
        copy.updateDataBinding(dataBinding: .value(String(repeating: "More description text ", count: 15)))
        let expanded = expectation(for: NSPredicate { _, _ in
            self.inlineView(in: host.view)?.bounds.height ?? 0 > originalHeight
        }, evaluatedWith: host)
        wait(for: [expanded], timeout: 3)
    }

    private func inlineView(in view: UIView) -> InlineTextView? {
        if let text = view as? InlineTextView { return text }
        return view.subviews.lazy.compactMap { self.inlineView(in: $0) }.first
    }

    func testActionPaddingBorderAndOpacityUseNativeRangesWithoutChangingAccessibleText() throws {
        let styles = try JSONDecoder().decode([BasicStateStylingBlock<InlineSpanStyle>].self,
                                              from: Data(##"[{"default":{"spacing":{"padding":"20 8","margin":"0 6"},"backgroundColor":{"light":"#eeeeee"},"border":{"borderColor":{"light":"#0000ff"},"borderWidth":"2","borderRadius":4},"opacity":0.5}}]"##
                                              .utf8))
        let plain = InlineContainerViewModel(children: [.toggle(toggle(), label: [text("Change")])])
        let decorated = InlineContainerViewModel(children: [.toggle(toggle(), label: [text("Change")], styles: styles)])
        let plainView = render(plain, width: 240)
        let view = render(decorated, width: 240)
        let content = decorated.textContent(position: nil, colorScheme: .light,
                                            contentSize: .large, layoutDirection: .leftToRight)
        XCTAssertEqual(content.runs[0].label, "Change")
        let decoration = try XCTUnwrap(content.decorations.first(where: { $0.borderColor != nil }))
        XCTAssertEqual(decoration.borderWidth, FrameAlignmentProperty(top: 2, right: 2, bottom: 2, left: 2))
        XCTAssertEqual(decoration.cornerRadius, 4)
        XCTAssertEqual(decoration.opacity, 0.5)
        XCTAssertGreaterThan(view.bounds.height, plainView.bounds.height)
        let rect = try XCTUnwrap(view.rects(for: view.runs[0].range).first)
        let plainRect = try XCTUnwrap(plainView.rects(for: plainView.runs[0].range).first)
        XCTAssertGreaterThanOrEqual(rect.width, plainRect.width + 16)
        XCTAssertEqual(view.actionRun(at: CGPoint(x: rect.midX, y: rect.midY))?.id, view.runs[0].id)
        let labelRange = (content.text.string as NSString).range(of: "Change")
        let color = try XCTUnwrap(content.text.attribute(.foregroundColor, at: labelRange.location,
                                                         effectiveRange: nil) as? UIColor)
        XCTAssertEqual(color.cgColor.alpha, 0.5, accuracy: 0.01)
        let repeatContent = decorated.textContent(position: nil, colorScheme: .light,
                                                  contentSize: .large, layoutDirection: .leftToRight)
        XCTAssertTrue(content.text.isEqual(to: repeatContent.text))
    }

    func testEnlargedTargetDoesNotStealAdjacentCopyOrAnotherAction() throws {
        let model = InlineContainerViewModel(children: [
            .text(text("Copy")), .toggle(toggle(), label: [text("A")]), .link(link(InlineEventService()), label: [text("B")])
        ])
        let view = render(model, width: 240)
        let copy = try XCTUnwrap(view.rects(for: view.runs[0].range).first)
        XCTAssertNil(view.actionRun(at: CGPoint(x: copy.maxX - 1, y: copy.midY)))
        for run in view.runs.dropFirst() {
            let rect = try XCTUnwrap(view.rects(for: run.range).first)
            XCTAssertEqual(view.actionRun(at: CGPoint(x: rect.midX, y: rect.midY))?.id, run.id)
        }
    }

    func testDashedBordersRenderEachNonzeroSideAndLeaveGaps() throws {
        for widths in ["2 0 0 0", "0 2 0 0", "0 0 2 0", "0 0 0 2"] {
            let dashed = try decorationPixels(borderWidth: widths, borderStyle: "dashed")
            let solid = try decorationPixels(borderWidth: widths, borderStyle: "solid")
            XCTAssertGreaterThan(dashed.filter { $0 != 0 }.count, 0, widths)
            XCTAssertLessThan(dashed.filter { $0 != 0 }.count, solid.filter { $0 != 0 }.count, widths)
        }
        let absent = try decorationPixels(borderWidth: "0", borderStyle: "dashed")
        XCTAssertTrue(absent.allSatisfy { $0 == 0 })
    }

    func testSnapshot_narrowWrappingTextAndAction() throws {
        let copyStyle = try JSONDecoder().decode(BasicTextStyle.self, from: Data(#"{"text":{"fontSize":17}}"#.utf8))
        let actionStyle = try JSONDecoder().decode(BasicTextStyle.self,
                                                   from: Data(##"{"text":{"fontSize":17,"fontWeight":"700","textColor":{"light":"#154caa"},"textDecoration":"underline"}}"##
                                                   .utf8))
        let styles = try JSONDecoder().decode([BasicStateStylingBlock<InlineSpanStyle>].self,
                                              from: Data(##"[{"default":{"spacing":{"padding":"2 3","margin":"0 2"},"backgroundColor":{"light":"#f1f5fa"},"border":{"borderColor":{"light":"#154caa"},"borderWidth":"2 0 0 0","borderStyle":"dashed"}}}]"##
                                              .utf8))
        let model = InlineContainerViewModel(children: [
            .text(text("A concise description with enough detail to wrap naturally beside the action. ", style: copyStyle)),
            .toggle(toggle(), label: [text("Show more information", style: actionStyle)], styles: styles)
        ])
        let view = render(model, width: 180)
        XCTAssertGreaterThan(view.rects(for: view.runs[0].range).count, 1)
        XCTAssertGreaterThan(view.rects(for: view.runs[1].range).count, 1)
        assertInlineSnapshot(view)
    }

    func testSnapshot_expandedRightToLeftInDarkMode() throws {
        let style = try JSONDecoder().decode(BasicTextStyle.self, from: Data(#"{"text":{"fontSize":18}}"#.utf8))
        let actionStyle = try JSONDecoder().decode(BasicTextStyle.self,
                                                   from: Data(##"{"text":{"fontSize":18,"fontWeight":"700","textColor":{"light":"#154caa","dark":"#99c2ff"},"textDecoration":"underline"}}"##
                                                   .utf8))
        let copy = text("وصف قصير ", style: style)
        let model = InlineContainerViewModel(children: [
            .text(copy), .toggle(toggle(), label: [text("عرض أقل", style: actionStyle)])
        ])
        let view = render(model, width: 230, direction: .rightToLeft, colorScheme: .dark)
        let collapsedHeight = view.bounds.height
        copy
            .updateDataBinding(
                dataBinding: .value(
                    "وصف المنتج الكامل يقدم معلومات إضافية واضحة عن المزايا والتفاصيل. يمكن قراءة النص الكامل هنا قبل اختيار المتابعة، مع بقاء الإجراء في نهاية النص. "
                )
            )
        update(view, model: model, width: 230, direction: .rightToLeft, colorScheme: .dark)
        XCTAssertGreaterThan(view.bounds.height, collapsedHeight)
        assertInlineSnapshot(view, colorScheme: .dark)
    }

    private func decorationPixels(borderWidth: String, borderStyle: String) throws -> Data {
        let styles = try JSONDecoder().decode([BasicStateStylingBlock<InlineSpanStyle>].self,
                                              from: Data("""
                                              [{"default":{"border":{"borderColor":{"light":"#0000ff"},
                                              "borderWidth":"\(borderWidth)","borderStyle":"\(borderStyle)"}}}]
                                              """.utf8))
        let model = InlineContainerViewModel(children: [.toggle(toggle(), label: [text("Change content")], styles: styles)])
        let view = render(model, width: 240)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { _ in
            view.layoutManager.drawBackground(forGlyphRange: view.layoutManager.glyphRange(for: view.textContainer),
                                              at: CGPoint(x: view.textContainerInset.left, y: view.textContainerInset.top))
        }
        return try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
    }

    private func assertInlineSnapshot(_ view: InlineTextView, colorScheme: ColorScheme = .light,
                                      file: StaticString = #filePath, testName: String = #function, line: UInt = #line) {
        let controller = UIViewController()
        controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        controller.view.backgroundColor = colorScheme == .dark ? .black : .white
        view.frame.origin = CGPoint(x: 16, y: 80)
        controller.view.addSubview(view)
        var strategy = Snapshotting<UIViewController, UIImage>.image(
            on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision
        )
        let snapshot = strategy.snapshot
        strategy.snapshot = { controller in
            .init { callback in
                snapshot(controller).run { image in
                    do {
                        try self.exportSnapshot(image, testName: testName, file: file)
                    } catch {
                        XCTFail("Could not export snapshot: \(error)", file: file, line: line)
                    }
                    callback(image)
                }
            }
        }
        assertSnapshot(of: controller, as: strategy, named: "inline", file: file, testName: testName, line: line)
    }

    private func exportSnapshot(_ image: UIImage, testName: String, file: StaticString) throws {
        // Missing references normally stay beside the tests; also expose the first rendering to CI's existing artifact upload.
        guard let path = ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] else { return }
        let suite = URL(fileURLWithPath: "\(file)").deletingPathExtension().lastPathComponent
        let directory = URL(fileURLWithPath: path).appendingPathComponent(suite)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = testName.replacingOccurrences(of: "()", with: "")
        try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent("\(name).inline.png"))
    }

    private func render(_ model: InlineContainerViewModel, width: CGFloat,
                        position: Int? = nil, direction: LayoutDirection = .leftToRight,
                        colorScheme: ColorScheme = .light, contentSize: UIContentSizeCategory = .large) -> InlineTextView {
        let view = InlineTextView()
        update(view, model: model, width: width, position: position, direction: direction,
               colorScheme: colorScheme, contentSize: contentSize)
        return view
    }

    private func update(_ view: InlineTextView, model: InlineContainerViewModel, width: CGFloat,
                        position: Int? = nil, direction: LayoutDirection = .leftToRight,
                        colorScheme: ColorScheme = .light, contentSize: UIContentSizeCategory = .large) {
        view.frame = CGRect(x: 0, y: 0, width: width, height: 1)
        view.setContent(model.textContent(position: position, colorScheme: colorScheme, contentSize: contentSize,
                                          layoutDirection: direction), accessibilityLabel: model.accessibilityLabel)
        view.frame.size.height = view.measuredHeight(for: width)
        view.layoutIfNeeded()
    }

    private func text(_ value: String, style: BasicTextStyle? = nil) -> BasicTextViewModel {
        BasicTextViewModel(value: value, defaultStyle: style.map { [$0] }, pressedStyle: nil,
                           hoveredStyle: nil, disabledStyle: nil, layoutState: nil, diagnosticService: nil)
    }

    private func toggle(events: EventDiagnosticServicing? = nil,
                        state: (any LayoutStateRepresenting)? = nil) -> ToggleButtonViewModel {
        ToggleButtonViewModel(children: nil, customStateKey: "details", defaultStyle: nil, pressedStyle: nil,
                              hoveredStyle: nil, disabledStyle: nil, eventService: events, layoutState: state)
    }

    private func link(_ events: EventDiagnosticServicing) -> StaticLinkViewModel {
        StaticLinkViewModel(children: nil, src: "https://example.com/terms", open: .externally,
                            defaultStyle: nil, pressedStyle: nil, hoveredStyle: nil, disabledStyle: nil,
                            layoutState: nil, eventService: events)
    }
}

private final class InlineEventService: MockEventService {
    var interactionCount = 0
    override func sendUserInteraction(action: UserInteraction, context: UserInteractionContext) {
        interactionCount += 1
        super.sendUserInteraction(action: action, context: context)
    }
}
