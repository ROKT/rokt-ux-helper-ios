import XCTest
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogDevicePayButtonViewModelTests: XCTestCase {

    func test_handleTap_doesNotTriggerEventWhenValidationFails() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: {
                return isValid ? .valid : .invalid
            },
            onStatusChange: { _ in }
        )

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"]),
            customStateKey: nil
        )
        sut.handleTap()
        XCTAssertFalse(eventService.cartItemDevicePayCalled)
    }

    func test_handleTap_triggersEventWhenValidationSucceeds() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        var isValid = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: {
                return isValid ? .valid : .invalid
            },
            onStatusChange: { _ in }
        )

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"]),
            customStateKey: nil
        )

        isValid = true
        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)
    }

    func test_devicePaySuccess_setsGlobalState_whenCustomStateKeyProvided() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        var isValid = true
        var didClose = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: {
                return isValid ? .valid : .invalid
            },
            onStatusChange: { _ in }
        )

        layoutState.actionCollection[.close] = { _ in didClose = true }

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"]),
            customStateKey: "paymentResult"
        )

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        eventService.cartItemDevicePayCompletionCallback?(.success)

        XCTAssertEqual(layoutState.globalCustomStateValue(for: "paymentResult"), 1)
        XCTAssertFalse(didClose)
    }

    func test_devicePayFailure_setsGlobalStateToZero_whenCustomStateKeyProvided() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = true
        var didClose = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: {
                return isValid ? .valid : .invalid
            },
            onStatusChange: { _ in }
        )

        layoutState.actionCollection[.close] = { _ in didClose = true }

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"]),
            customStateKey: "paymentResult"
        )

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        eventService.cartItemDevicePayCompletionCallback?(.failure)

        XCTAssertEqual(layoutState.globalCustomStateValue(for: "paymentResult"), -1)
        XCTAssertFalse(didClose)
    }

    func test_devicePayRetry_setsGlobalStateToZero_whenCustomStateKeyProvided() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = true
        var didClose = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: {
                return isValid ? .valid : .invalid
            },
            onStatusChange: { _ in }
        )

        layoutState.actionCollection[.close] = { _ in didClose = true }

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"]),
            customStateKey: "paymentResult"
        )

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        eventService.cartItemDevicePayCompletionCallback?(.retry)

        XCTAssertEqual(layoutState.globalCustomStateValue(for: "paymentResult"), -1)
        XCTAssertFalse(didClose)
    }

    func test_devicePaySuccess_callsCloseAction_whenNoCustomStateKey() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = true
        var didClose = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: {
                return isValid ? .valid : .invalid
            },
            onStatusChange: { _ in }
        )

        layoutState.actionCollection[.close] = { _ in didClose = true }

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"]),
            customStateKey: nil
        )

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        eventService.cartItemDevicePayCompletionCallback?(.success)

        XCTAssertNil(layoutState.globalCustomStateValue(for: "paymentResult"))
        XCTAssertTrue(didClose)
    }

    func test_devicePayFailure_callsCloseAction_whenNoCustomStateKey() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = true
        var didClose = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: {
                return isValid ? .valid : .invalid
            },
            onStatusChange: { _ in }
        )

        layoutState.actionCollection[.close] = { _ in didClose = true }

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"]),
            customStateKey: nil
        )

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        eventService.cartItemDevicePayCompletionCallback?(.failure)

        XCTAssertNil(layoutState.globalCustomStateValue(for: "paymentResult"))
        XCTAssertTrue(didClose)
    }

    func test_devicePaySuccess_doesNotSetState_whenCustomStateKeyIsEmpty() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = true
        var didClose = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            owner: self,
            validation: {
                return isValid ? .valid : .invalid
            },
            onStatusChange: { _ in }
        )

        layoutState.actionCollection[.close] = { _ in didClose = true }

        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"]),
            customStateKey: ""
        )

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        eventService.cartItemDevicePayCompletionCallback?(.success)

        XCTAssertNil(layoutState.globalCustomStateValue(for: "paymentResult"))
        XCTAssertTrue(didClose)
    }

    private func makeCatalogItem(id: String) -> CatalogItem {
        CatalogItem(
            images: [:],
            catalogItemId: id,
            cartItemId: "cart-\(id)",
            instanceGuid: "instance-\(id)",
            title: "title-\(id)",
            description: "description-\(id)",
            price: nil,
            priceFormatted: nil,
            originalPrice: nil,
            originalPriceFormatted: nil,
            currency: "USD",
            signalType: nil,
            url: nil,
            minItemCount: nil,
            maxItemCount: nil,
            preSelectedQuantity: nil,
            providerData: "provider-\(id)",
            urlBehavior: nil,
            positiveResponseText: "positive",
            negativeResponseText: "negative",
            addOns: nil,
            copy: nil,
            linkedProductId: nil,
            token: "token-\(id)"
        )
    }
}
