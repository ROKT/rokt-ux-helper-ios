import XCTest
import SwiftUI
import ViewInspector
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class CatalogResponseButtonInteractionTests: XCTestCase {
    func test_productUsesNativeButtonAndRespondsOnceWithItsBoundContext() throws {
        let fixture = try makeFixture()
        var responses = 0
        var receivedContext: CatalogItemContext?
        var receivedKey: String?
        var closed = false
        fixture.state.actionCollection[.close] = { _ in closed = true }
        fixture.model.productResponse = { context, key in
            responses += 1
            receivedContext = context
            receivedKey = key
        }
        let button = try fixture.view.inspect().find(ViewType.Button.self)
        XCTAssertTrue(try button.buttonStyle() is StateButtonStyle)
        let label = try button.labelView().find(BasicTextComponent.self).actualView()
        XCTAssertEqual(label.model.boundValue, "View product")

        try button.tap()

        XCTAssertEqual(responses, 1)
        XCTAssertEqual(receivedContext?.offerIndex, fixture.context.offerIndex)
        XCTAssertEqual(receivedContext?.itemIndex, fixture.context.itemIndex)
        XCTAssertEqual(receivedKey, "buy-now")
        XCTAssertFalse(fixture.events.cartItemInstantPurchaseCalled)
        XCTAssertFalse(fixture.events.cartItemForwardPaymentCalled)
        XCTAssertFalse(fixture.events.dismissalEventCalled)
        XCTAssertFalse(closed)
    }

    func test_productButtonLabelHasNoCompetingTapOrLongPressHandlers() throws {
        let fixture = try makeFixture()
        var responses = 0
        fixture.model.productResponse = { _, _ in responses += 1 }
        let button = try fixture.view.inspect().find(ViewType.Button.self)
        let label = try button.labelView().find(ViewType.HStack.self)

        XCTAssertThrowsError(try label.callOnTapGesture())
        XCTAssertThrowsError(try label.callOnLongPressGesture())
        XCTAssertThrowsError(try label.gesture(SequenceGesture<LongPressGesture, LongPressGesture>.self))
        XCTAssertEqual(responses, 0)
    }

    func test_disabledProductButtonDoesNotRespond() throws {
        let fixture = try makeFixture()
        var responses = 0
        fixture.model.productResponse = { _, _ in responses += 1 }
        let button = try fixture.view.disabled(true).inspect().find(ViewType.Button.self)

        XCTAssertTrue(button.isDisabled())
        XCTAssertThrowsError(try button.tap())
        XCTAssertEqual(responses, 0)
        XCTAssertFalse(fixture.events.cartItemInstantPurchaseCalled)
        XCTAssertFalse(fixture.events.cartItemForwardPaymentCalled)
        XCTAssertFalse(fixture.events.dismissalEventCalled)
    }

    func test_invalidProductResponseDoesNotCreateButtonOrLabel() throws {
        let fixture = try makeFixture(responseKey: "missing-response")

        XCTAssertFalse(fixture.model.isRenderable)
        XCTAssertThrowsError(try fixture.view.inspect().find(ViewType.Button.self))
        XCTAssertThrowsError(try fixture.view.inspect().find(ViewType.HStack.self))
    }

    func test_legacyPurchaseKeepsItsGestureAndPurchaseBehavior() throws {
        let fixture = try makeFixture(isProduct: false)
        var closed = false
        var productResponses = 0
        fixture.state.actionCollection[.close] = { _ in closed = true }
        fixture.model.productResponse = { _, _ in productResponses += 1 }
        let inspected = try fixture.view.inspect()

        XCTAssertThrowsError(try inspected.find(ViewType.Button.self))
        try inspected.find(ViewType.HStack.self).callOnTapGesture()

        XCTAssertTrue(fixture.events.cartItemInstantPurchaseCalled)
        XCTAssertFalse(fixture.events.cartItemForwardPaymentCalled)
        XCTAssertTrue(fixture.events.dismissalEventCalled)
        XCTAssertTrue(closed)
        XCTAssertEqual(productResponses, 0)
    }

    private func makeFixture(isProduct: Bool = true, responseKey: String = "buy-now") throws -> Fixture {
        let slots = try CatalogProductFixture.slots()
        let context = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        let state = LayoutState()
        let events = MockEventService()
        let text = BasicTextViewModel(value: "View product", defaultStyle: nil, pressedStyle: nil,
                                      hoveredStyle: nil, disabledStyle: nil, layoutState: state,
                                      diagnosticService: nil)
        let model = CatalogResponseButtonViewModel(
            catalogItem: context.catalogItem, children: [.basicText(text)], layoutState: state,
            eventService: events, defaultStyle: nil, pressedStyle: nil, hoveredStyle: nil,
            disabledStyle: nil, catalogItemContext: isProduct ? context : nil, responseKey: responseKey
        )
        let screen = GlobalScreenSize()
        screen.width = 240
        let component = CatalogResponseButtonComponent(config: .init(parent: .column, position: 1), model: model,
                                                       parentWidth: .constant(240), parentHeight: .constant(nil),
                                                       parentOverride: nil)
        return Fixture(component: component, model: model, context: context, state: state, events: events, screen: screen)
    }

    @MainActor
    private struct Fixture {
        let component: CatalogResponseButtonComponent
        let model: CatalogResponseButtonViewModel
        let context: CatalogItemContext
        let state: LayoutState
        let events: MockEventService
        let screen: GlobalScreenSize

        var view: some View { component.environmentObject(screen) }
    }
}
