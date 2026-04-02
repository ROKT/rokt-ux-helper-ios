import XCTest
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogDevicePayButtonViewModelTests: XCTestCase {

    func test_customStateKey_isPaymentResult() {
        let sut = CatalogDevicePayButtonViewModel(
            catalogItem: makeCatalogItem(id: "item"),
            children: nil,
            provider: .applePay,
            layoutState: MockLayoutState(),
            eventService: MockEventService(),
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            validatorTriggerConfig: nil
        )

        XCTAssertEqual(sut.customStateKey, "paymentResult")
    }

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
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"])
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
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"])
        )

        isValid = true
        sut.handleTap()

        XCTAssertTrue(eventService.cartItemDevicePayCalled)
    }

    func test_devicePaySuccess_setsLayoutVariantCustomState() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = true

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
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"])
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

        XCTAssertEqual(
            layoutState.layoutVariantCustomStateValue(
                for: CustomStateIdentifiable.Keys.paymentResult.rawValue,
                position: 0
            ),
            1
        )
    }

    func test_devicePayFailure_setsLayoutVariantCustomState() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = true

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
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"])
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

        XCTAssertEqual(
            layoutState.layoutVariantCustomStateValue(
                for: CustomStateIdentifiable.Keys.paymentResult.rawValue,
                position: 0
            ),
            -1
        )
    }

    func test_devicePayRetry_setsLayoutVariantCustomState() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        let isValid = true

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
            validatorTriggerConfig: ValidationTriggerConfig(validatorFieldKeys: ["dropdown"])
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

        XCTAssertEqual(
            layoutState.layoutVariantCustomStateValue(
                for: CustomStateIdentifiable.Keys.paymentResult.rawValue,
                position: 0
            ),
            -1
        )
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
            inventoryStatus: nil,
            linkedProductId: nil,
            token: "token-\(id)"
        )
    }
}
