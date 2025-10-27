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

    func test_devicePaySuccess_setsLayoutVariantCustomState_whenCustomStateKeyProvided() {
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
        sut.position = 0

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        let expectation = expectation(description: "State is set")
        eventService.cartItemDevicePayCompletionCallback?(.success)

        DispatchQueue.main.async {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(layoutState.layoutVariantCustomStateValue(for: "paymentResult", position: 0), 1)
        XCTAssertFalse(didClose)
    }

    func test_devicePayFailure_setsLayoutVariantCustomState_whenCustomStateKeyProvided() {
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
        sut.position = 0

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        let expectation = expectation(description: "State is set")
        eventService.cartItemDevicePayCompletionCallback?(.failure)

        DispatchQueue.main.async {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(layoutState.layoutVariantCustomStateValue(for: "paymentResult", position: 0), -1)
        XCTAssertFalse(didClose)
    }

    func test_devicePayRetry_setsLayoutVariantCustomState_whenCustomStateKeyProvided() {
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
        sut.position = 0

        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)

        let expectation = expectation(description: "State is set")
        eventService.cartItemDevicePayCompletionCallback?(.retry)

        DispatchQueue.main.async {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(layoutState.layoutVariantCustomStateValue(for: "paymentResult", position: 0), -1)
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
