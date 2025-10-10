import XCTest
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogDevicePayButtonViewModelTests: XCTestCase {

    func test_handleTap_doesNotTriggerEventWhenValidationFails() {
        let layoutState = MockLayoutState()
        let eventService = MockEventService()
        var isValid = false

        layoutState.validationCoordinator.registerField(
            key: "dropdown",
            validation: { isValid ? .valid : .invalid },
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
            validation: { isValid ? .valid : .invalid },
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
