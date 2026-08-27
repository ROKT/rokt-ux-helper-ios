import Combine
import DcuiSchema
import SwiftUI
import XCTest
@testable import RoktUXHelper

@MainActor
final class TestInlineSchemaLifecycle: XCTestCase {
    func testOuterTogglePublishesGlobalStateAndCapturesItForRestoration() throws {
        var captured: [RoktPluginViewState] = []
        let state = LayoutState(pluginId: "example-plugin", onPluginViewStateChange: { captured.append($0) })
        let events = SchemaIntegrationEventService()
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: [], state: state, events: events)
        let schema = try JSONDecoder().decode(InlineContainerModel<OuterLayoutInlineChildren, OuterLayoutWhenPredicate>.self,
                                              from: conditionalInlineData())
        let model = try transformer.getInlineContainer(schema, context: .outer([]))
        let scene = mount(.inlineContainer(model))
        defer { scene.tearDown() }
        let view = try XCTUnwrap(scene.firstInline())
        XCTAssertFalse(view.isAccessibilityElement)
        XCTAssertEqual(view.accessibilityLabel, "Description")
        XCTAssertEqual((view.accessibilityElements as? [UIAccessibilityElement])?.map(\.accessibilityLabel),
                       ["Copy ", "Change details"])
        let action = try XCTUnwrap(view.runs.first { $0.action != nil })
        let changed = expectation(description: "Conditional style observes the global toggle")
        let subscription = try XCTUnwrap(model.conditionalStyle).objectWillChange.sink { _ in
            if state.globalCustomStateValue(for: "details") == 1 { changed.fulfill() }
        }
        XCTAssertTrue(view.activateRun(id: action.id))
        wait(for: [changed], timeout: 3)
        subscription.cancel()
        XCTAssertEqual(state.globalCustomStateValue(for: "details"), 1)
        XCTAssertEqual(captured.last?.customStateMap?[CustomStateIdentifiable(position: nil, key: "details")], 1)
        XCTAssertEqual(model.style(state: .default, position: nil, width: 200, colorScheme: .light)?.container?.opacity, 0.5)
        let content = ProductCarouselIntegrationFixture.content(model)
        XCTAssertTrue(content.text.string.hasPrefix("COPY "))
        XCTAssertTrue(content.transitionStates.allSatisfy { $0 })
        XCTAssertEqual(content.transitionDuration, 0.1)
        XCTAssertEqual(content.runs.last?.label, "Change details")
        XCTAssertTrue(view.activateRun(id: action.id))
        XCTAssertEqual(state.globalCustomStateValue(for: "details"), 0)
        XCTAssertEqual(captured.last?.customStateMap?[CustomStateIdentifiable(position: nil, key: "details")], 0)
        XCTAssertEqual(events.interactionCount, 2)
        XCTAssertFalse(events.openURLCalled)
        XCTAssertFalse(events.cartItemInstantPurchaseCalled)
    }

    func testEveryDistributionPublishesOfferToggleChangesToConditionalInlineStyles() throws {
        for distribution in ProductCarouselIntegrationFixture.distributions {
            let state = LayoutState()
            let events = SchemaIntegrationEventService()
            let schema = try JSONDecoder().decode(InlineContainerModel<InlineChildren, WhenPredicate>.self,
                                                  from: conditionalInlineData())
            let inlineSchema = LayoutSchemaModel.inlineContainer(schema)
            let slots = [SlotModel(instanceGuid: "example-slot", offer: .mock(),
                                   layoutVariant: LayoutVariantModel(layoutVariantSchema: inlineSchema,
                                                                     moduleName: "standard-marketing"), jwtToken: "")]
            let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots, state: state, events: events)
            let layout = try transformer.transform(distribution, context: .outer(slots.map(\.offer)))
            let scene = mount(layout)
            defer { scene.tearDown() }
            let view = try XCTUnwrap(scene.firstInline())
            let action = try XCTUnwrap(view.runs.first { $0.action != nil })
            let published = expectation(description: "Distribution publishes its local toggle")
            let subscription = state.itemsPublisher.compactMap {
                ($0[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>)?.wrappedValue
            }.filter { $0[CustomStateIdentifiable(position: 0, key: "details")] == 1 }
                .first().sink { _ in published.fulfill() }
            XCTAssertTrue(view.activateRun(id: action.id))
            wait(for: [published], timeout: 3)
            subscription.cancel()
            waitForInline(in: scene) { $0.text.hasPrefix("COPY ") }
            XCTAssertTrue(try XCTUnwrap(scene.firstInline()).text.hasPrefix("COPY "))
            XCTAssertEqual(events.interactionCount, 1)
            XCTAssertNil(state.globalCustomStateValue(for: "details"))
        }
    }

    func testExplicitDisabledStylePreventsHostedInlineActions() throws {
        let events = SchemaIntegrationEventService()
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: [], events: events)
        let schema = try JSONDecoder().decode(InlineContainerModel<InlineChildren, WhenPredicate>.self,
                                              from: conditionalInlineData())
        let model = try transformer.getInlineContainer(schema, context: .outer([]))
        let scene = mount(.inlineContainer(model), styleState: .disabled)
        defer { scene.tearDown() }
        let view = try XCTUnwrap(scene.firstInline())
        let action = try XCTUnwrap(view.runs.first { $0.action != nil })
        XCTAssertFalse(view.actionsEnabled)
        XCTAssertFalse(view.activateRun(id: action.id))
        let element = try XCTUnwrap((view.accessibilityElements as? [UIAccessibilityElement])?.last)
        XCTAssertTrue(element.accessibilityTraits.contains(.notEnabled))
        XCTAssertFalse(element.accessibilityActivate())
        XCTAssertEqual(events.interactionCount, 0)
    }

    func testExpandedDescriptionReflowsAndNextOfferStartsCollapsed() throws {
        let copy = String(repeating: "An example description with more detail. ", count: 9)
        let slots = try ProductCarouselIntegrationFixture.slots(copies: [copy, copy])
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.lightGray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        let state = LayoutState(config: RoktUXConfig.Builder().imageLoader(InlineLifecycleImageLoader(image: image)).build())
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots, state: state)
        let distribution = ProductCarouselIntegrationFixture.distributions[0]
        let layout = try transformer.transform(distribution, context: .outer(slots.map(\.offer)))
        let scene = mount(layout, width: 180)
        defer { scene.tearDown() }
        let collapsed = try XCTUnwrap(scene.firstInline())
        let height = collapsed.bounds.height
        XCTAssertTrue(collapsed.text.contains("See More"))
        let action = try XCTUnwrap(collapsed.runs.first { $0.action != nil })
        XCTAssertTrue(collapsed.activateRun(id: action.id))
        waitForInline(in: scene) { $0.text.contains("See Less") && $0.bounds.height > height }
        let full = try XCTUnwrap(scene.firstInline())
        XCTAssertTrue(full.text.contains("See Less"))
        XCTAssertGreaterThan(full.bounds.height, height)
        let next = expectation(description: "Next offer is visible")
        let subscription = state.itemsPublisher.compactMap { $0[LayoutState.visibleOfferIndexesKey] as? [Int] }
            .filter { $0 == [1] }.first().sink { _ in next.fulfill() }
        state.actionCollection[.progressControlNext](nil)
        wait(for: [next], timeout: 3)
        subscription.cancel()
        waitForInline(in: scene) { $0.text.contains("See More") }
        XCTAssertTrue(try XCTUnwrap(scene.firstInline()).text.contains("See More"))
    }

    private func conditionalInlineData() -> Data {
        Data(#"""
        {
          "a11yLabel": "Description",
          "styles": {
            "elements": {"own": [{"default": {"container": {"opacity": 1}}}]},
            "conditionalTransitions": {"predicates": [{"type":"CustomState","predicate":{"key":"details","condition":"is","value":1}}],
              "duration":100,"value":{"own":{"container":{"opacity":0.5}}}}
          },
          "children": [
            {"type":"BasicText","node":{"value":"Copy ","styles":{"conditionalTransitions":{
              "predicates":[{"type":"CustomState","predicate":{"key":"details","condition":"is","value":1}}],
              "duration":100,"value":{"own":{"text":{"textTransform":"uppercase"}}}}}}},
            {"type":"ToggleButtonStateTrigger","node":{"customStateKey":"details","a11yLabel":"Change details",
              "children":[{"type":"BasicText","node":{"value":"Change"}}]}}
          ]
        }
        """#.utf8)
    }

    private func mount(_ layout: LayoutSchemaViewModel, width: CGFloat = 240, styleState: StyleState = .default) -> Scene {
        let screen = GlobalScreenSize()
        screen.width = width
        screen.height = 900
        let mounted = expectation(description: "Layout mounted")
        let root = LayoutSchemaComponent(config: .init(parent: .column, position: nil), layout: layout,
                                         parentWidth: .constant(width), parentHeight: .constant(nil),
                                         styleState: .constant(styleState))
            .frame(width: width, alignment: .topLeading)
            .environmentObject(screen)
            .onAppear { DispatchQueue.main.async { mounted.fulfill() } }
        let host = UIHostingController(rootView: AnyView(root))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 900))
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        wait(for: [mounted], timeout: 3)
        window.layoutIfNeeded()
        let scene = Scene(window: window)
        waitForInline(in: scene) { _ in true }
        return scene
    }

    private func waitForInline(in scene: Scene, matching condition: @escaping (InlineTextView) -> Bool) {
        let ready = expectation(for: NSPredicate { _, _ in
            scene.window.layoutIfNeeded()
            guard let view = scene.firstInline(), view.bounds.height > 0, view.bounds.width > 0 else { return false }
            return abs(view.bounds.height - view.measuredHeight(for: view.bounds.width)) < 0.5 && condition(view)
        }, evaluatedWith: nil)
        wait(for: [ready], timeout: 3)
    }

    @MainActor
    private struct Scene {
        let window: UIWindow

        func firstInline() -> InlineTextView? {
            func find(_ view: UIView) -> InlineTextView? {
                if let inline = view as? InlineTextView, !inline.isHidden { return inline }
                return view.subviews.lazy.compactMap { find($0) }.first
            }
            return find(window)
        }

        func tearDown() {
            window.isHidden = true
            window.rootViewController = nil
        }
    }
}

private final class InlineLifecycleImageLoader: RoktUXImageLoader {
    private let image: UIImage

    init(image: UIImage) { self.image = image }

    func loadImage(urlString: String, completion: @escaping (Result<UIImage?, Error>) -> Void) {
        completion(.success(image))
    }
}
