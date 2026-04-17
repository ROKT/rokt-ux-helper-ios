import XCTest
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogResponseButtonViewModelTests: XCTestCase {

    func test_isPartnerManagedPurchase_defaultsToTrue_whenFlagAbsent() {
        let layoutState = MockLayoutState()
        layoutState.items[LayoutState.fullOfferKey] = makeOfferModel(copy: [:])

        let sut = makeSUT(layoutState: layoutState)

        XCTAssertTrue(sut.isPartnerManagedPurchase)
    }

    func test_isPartnerManagedPurchase_true_whenFlagTrue() {
        let layoutState = MockLayoutState()
        layoutState.items[LayoutState.fullOfferKey] = makeOfferModel(copy: [
            "ppu.partnerManagedPurchase": "true"
        ])

        let sut = makeSUT(layoutState: layoutState)

        XCTAssertTrue(sut.isPartnerManagedPurchase)
    }

    func test_isPartnerManagedPurchase_false_whenFlagFalse() {
        let layoutState = MockLayoutState()
        layoutState.items[LayoutState.fullOfferKey] = makeOfferModel(copy: [
            "ppu.partnerManagedPurchase": "false"
        ])

        let sut = makeSUT(layoutState: layoutState)

        XCTAssertFalse(sut.isPartnerManagedPurchase)
    }

    func test_cartItemInstantPurchase_partnerManaged_callsInstantPurchaseAndDismisses() {
        let eventService = MockEventService()
        let layoutState = MockLayoutState()
        var closeInvoked = false
        layoutState.actionCollection[.close] = { _ in closeInvoked = true }

        let sut = makeSUT(
            catalogItem: makeCatalogItem(id: "item-1"),
            layoutState: layoutState,
            eventService: eventService
        )

        sut.cartItemInstantPurchase(position: nil)

        XCTAssertTrue(eventService.cartItemInstantPurchaseCalled)
        XCTAssertFalse(eventService.cartItemForwardPaymentCalled)
        XCTAssertTrue(eventService.dismissalEventCalled)
        XCTAssertEqual(eventService.dismissOption, .defaultDismiss)
        XCTAssertTrue(closeInvoked)
    }

    func test_cartItemInstantPurchase_forwardPayment_callsForwardPaymentWithReference() {
        let eventService = MockEventService()
        let layoutState = MockLayoutState()
        layoutState.items[LayoutState.fullOfferKey] = makeOfferModel(copy: [
            "ppu.partnerManagedPurchase": "false",
            "ppu.partnerPaymentReference": "ref-xyz"
        ])
        var closeInvoked = false
        layoutState.actionCollection[.close] = { _ in closeInvoked = true }

        let catalogItem = makeCatalogItem(id: "item-1")
        let sut = makeSUT(
            catalogItem: catalogItem,
            layoutState: layoutState,
            eventService: eventService
        )

        sut.cartItemInstantPurchase(position: nil)

        XCTAssertTrue(eventService.cartItemForwardPaymentCalled)
        XCTAssertFalse(eventService.cartItemInstantPurchaseCalled)
        XCTAssertFalse(eventService.dismissalEventCalled)
        XCTAssertFalse(closeInvoked)
        XCTAssertEqual(eventService.lastForwardPaymentReference, "ref-xyz")
        XCTAssertEqual(eventService.lastForwardPaymentCatalogItem?.catalogItemId, "item-1")
    }

    func test_isPartnerManagedPurchase_true_whenFlagTypo() {
        let layoutState = MockLayoutState()
        layoutState.items[LayoutState.fullOfferKey] = makeOfferModel(copy: [
            "ppu.partnerManagedPurchase": "trrue"
        ])

        let sut = makeSUT(layoutState: layoutState)

        XCTAssertTrue(sut.isPartnerManagedPurchase)
    }

    func test_cartItemInstantPurchase_nilCatalogItem_dismisses() {
        let eventService = MockEventService()
        let layoutState = MockLayoutState()
        var closeInvoked = false
        layoutState.actionCollection[.close] = { _ in closeInvoked = true }

        let sut = makeSUT(
            catalogItem: nil,
            layoutState: layoutState,
            eventService: eventService
        )

        sut.cartItemInstantPurchase(position: nil)

        XCTAssertFalse(eventService.cartItemInstantPurchaseCalled)
        XCTAssertFalse(eventService.cartItemForwardPaymentCalled)
        XCTAssertTrue(eventService.dismissalEventCalled)
        XCTAssertTrue(closeInvoked)
    }

    func test_forwardPaymentSuccess_writesSuccessToCustomState() {
        let eventService = MockEventService()
        let layoutState = MockLayoutState()
        layoutState.items[LayoutState.fullOfferKey] = makeOfferModel(copy: [
            "ppu.partnerManagedPurchase": "false"
        ])

        let sut = makeSUT(
            catalogItem: makeCatalogItem(id: "item-1"),
            layoutState: layoutState,
            eventService: eventService
        )

        sut.cartItemInstantPurchase(position: 0)
        XCTAssertTrue(eventService.cartItemForwardPaymentCalled)

        let expectation = expectation(description: "Success state written")
        eventService.cartItemForwardPaymentCompletionCallback?(.success)
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(
            layoutState.layoutVariantCustomStateValue(
                for: CustomStateIdentifiable.Keys.paymentResult.rawValue,
                position: 0
            ),
            1
        )
    }

    func test_forwardPaymentFailure_writesFailureToCustomState() {
        let eventService = MockEventService()
        let layoutState = MockLayoutState()
        layoutState.items[LayoutState.fullOfferKey] = makeOfferModel(copy: [
            "ppu.partnerManagedPurchase": "false"
        ])

        let sut = makeSUT(
            catalogItem: makeCatalogItem(id: "item-1"),
            layoutState: layoutState,
            eventService: eventService
        )

        sut.cartItemInstantPurchase(position: 0)
        XCTAssertTrue(eventService.cartItemForwardPaymentCalled)

        let expectation = expectation(description: "Failure state written")
        eventService.cartItemForwardPaymentCompletionCallback?(.failure(reason: "declined"))
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(
            layoutState.layoutVariantCustomStateValue(
                for: CustomStateIdentifiable.Keys.paymentResult.rawValue,
                position: 0
            ),
            -1
        )
    }

    // MARK: - Helpers

    private func makeSUT(
        catalogItem: CatalogItem? = nil,
        layoutState: MockLayoutState,
        eventService: MockEventService = MockEventService()
    ) -> CatalogResponseButtonViewModel {
        CatalogResponseButtonViewModel(
            catalogItem: catalogItem,
            children: nil,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil
        )
    }

    private func makeOfferModel(copy: [String: String]) -> OfferModel {
        OfferModel(
            campaignId: nil,
            creative: CreativeModel(
                referralCreativeId: "ref",
                instanceGuid: "instance",
                copy: copy,
                images: nil,
                links: nil,
                responseOptionsMap: nil,
                jwtToken: "token"
            ),
            catalogItems: nil,
            catalogItemGroup: nil
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
