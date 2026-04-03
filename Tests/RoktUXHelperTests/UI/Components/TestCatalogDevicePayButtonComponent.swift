import XCTest
import SwiftUI
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
final class TestCatalogDevicePayButtonComponent: XCTestCase {

    func test_handleTap_callsDevicePay_whenNoValidation() {
        let eventService = MockEventService()
        let catalogItem = CatalogItem.mock(catalogItemId: "item-1")

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: catalogItem,
            children: nil,
            provider: .applePay,
            layoutState: MockLayoutState(),
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: nil
        )

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)
    }

    func test_handleTap_doesNotCallDevicePay_whenNoCatalogItem() {
        let eventService = MockEventService()

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: nil,
            children: nil,
            provider: .applePay,
            layoutState: MockLayoutState(),
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: nil
        )

        sut.handleTap()

        XCTAssertFalse(eventService.cartItemDevicePayCalled)
    }

    func test_handleTap_blockedByValidation_sendsUserInteraction() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let catalogItem = CatalogItem.mock(catalogItemId: "item-1")

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: { .invalid },
            onStatusChange: { _ in }
        )

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: catalogItem,
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"])
        )

        sut.handleTap()

        XCTAssertFalse(eventService.cartItemDevicePayCalled)
        XCTAssertTrue(eventService.cartItemUserInteractionCalled)
    }

    func test_devicePayCompletion_success_setsCustomState() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let catalogItem = CatalogItem.mock(catalogItemId: "item-1")

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: catalogItem,
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: nil
        )
        sut.position = 0

        sut.handleTap()
        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        // Simulate completion callback
        eventService.cartItemDevicePayCompletionCallback?(.success)

        let exp = expectation(description: "custom state updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let map = layoutState.items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>
            let identifier = CustomStateIdentifiable(position: 0, key: .paymentResult)
            XCTAssertEqual(map?.wrappedValue?[identifier], 1)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_devicePayCompletion_failure_setsNegativeCustomState() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let catalogItem = CatalogItem.mock(catalogItemId: "item-1")

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: catalogItem,
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: nil
        )
        sut.position = 0

        sut.handleTap()
        eventService.cartItemDevicePayCompletionCallback?(.failure)

        let exp = expectation(description: "custom state updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let map = layoutState.items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>
            let identifier = CustomStateIdentifiable(position: 0, key: .paymentResult)
            XCTAssertEqual(map?.wrappedValue?[identifier], -1)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
