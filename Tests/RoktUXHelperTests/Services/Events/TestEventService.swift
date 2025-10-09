//
//  TestEventService.swift
//  RoktUXHelperTests
//
//  Copyright 2020 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
import DcuiSchema

@testable import RoktUXHelper

@available(iOS 13, *)
final class TestEventService: XCTestCase {
    var events = [RoktEventRequest]()
    var errors = [String]()
    let startDate = Date()
    let responseReceivedDate = Date()
    var stubUXHelper: MockUXHelper!

    override func setUpWithError() throws {
        events = [RoktEventRequest]()
        self.stubUXHelper = MockUXHelper()
    }

    // MARK: Events

    func test_sendEventsOnTransformerSuccess_readyEventsAndLoadCompleteSignals_shouldSend() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.sendEventsOnTransformerSuccess()

        // Assert
        XCTAssertEqual(events.first?.eventType, .SignalLoadComplete)

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 1)
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.PlacementReady))
    }

    func test_sendEventsOnLoad_interactiveEventsAndImpressionSignals_shouldSend() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.sendEventsOnLoad()

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalImpression)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        XCTAssertNotNil(event?.metadata.first { $0.name == BE_PAGE_SIGNAL_LOAD })
        XCTAssertNotNil(
            event?.metadata.first { $0.value == EventDateFormatter.getDateString(startDate) })
        XCTAssertNotNil(event?.metadata.first { $0.name == BE_PAGE_RENDER_ENGINE })
        XCTAssertNotNil(event?.metadata.first { $0.value == BE_RENDER_ENGINE_LAYOUTS })

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 1)
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.PlacementInteractive))
    }

    func test_slot_impression_event() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.sendSlotImpressionEvent(instanceGuid: "instanceGuid", jwtToken: "jwt-token")

        // Assert
        XCTAssertEqual(events.first?.eventType, .SignalImpression)
    }

    func test_two_unique_slot_impression_event() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.sendSlotImpressionEvent(instanceGuid: "instanceGuid1", jwtToken: "jwt-token")
        eventService.sendSlotImpressionEvent(instanceGuid: "instanceGuid2", jwtToken: "jwt-token")

        // Assert
        XCTAssertNotNil(
            events.first { $0.eventType == .SignalImpression && $0.parentGuid == "instanceGuid1" })
        XCTAssertNotNil(
            events.first { $0.eventType == .SignalImpression && $0.parentGuid == "instanceGuid2" })
        XCTAssertEqual(events.count, 2)
    }

    func test_plugin_activation_event() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.sendSignalActivationEvent()

        // Assert
        XCTAssertEqual(events.first?.eventType, .SignalActivation)
        XCTAssertEqual(events.first?.pageInstanceGuid, mockPageInstanceGuid)
    }

    func test_sendSignalResponse_onPositive_engagementEventsAndSignals_shouldSend() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.sendSignalResponseEvent(
            instanceGuid: "instanceGuid", jwtToken: "plugin-token", isPositive: true)

        // Assert
        XCTAssertEqual(events.first?.eventType, .SignalResponse)
        XCTAssertEqual(events.first?.parentGuid, "instanceGuid")
        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 3)
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.PositiveEngagement))
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.FirstPositiveEngagement))
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.OfferEngagement))
        XCTAssertEqual(stubUXHelper.sessionId, "session")
        XCTAssertEqual(stubUXHelper.jwtToken, "plugin-config-token")
        XCTAssertEqual(stubUXHelper.pluginInstanceGuid, "pluginInstanceGuid")
        XCTAssertEqual(stubUXHelper.layoutId, "pluginId")
    }

    func test_sendDismissal_onNoMoreOffer_dismissalEventsAndSignals_shouldSend() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.dismissOption = .noMoreOffer
        eventService.sendDismissalEvent()

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalDismissal)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        XCTAssertNotNil(event?.metadata.first { $0.name == kInitiator })
        XCTAssertNotNil(event?.metadata.first { $0.value == kNoMoreOfferToShow })

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 1)
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.PlacementCompleted))
    }

    func test_sendDismissal_onCloseButton_dismissalEventsAndSignals_shouldSend() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.dismissOption = .closeButton
        eventService.sendDismissalEvent()

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalDismissal)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        XCTAssertNotNil(event?.metadata.first { $0.name == kInitiator })
        XCTAssertNotNil(event?.metadata.first { $0.value == kCloseButton })

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 1)
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.PlacementClosed))
    }

    func test_dismissal_dimissed_event() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.dismissOption = .defaultDismiss
        eventService.sendDismissalEvent()

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalDismissal)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        XCTAssertNotNil(event?.metadata.first { $0.name == kInitiator })
        XCTAssertNotNil(event?.metadata.first { $0.value == kDismissed })
    }

    func test_diagnostic_processing() {
        let expectation = expectation(description: "test diagnostics")
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            useDiagnosticEvents: true,
            eventHandler: { event in
                switch event.eventType {
                case .SignalSdkDiagnostic:
                    XCTAssertEqual(
                        event.eventData.first(where: { $0.name == "code" })?.value, "error message")
                    XCTAssertEqual(
                        event.eventData.first(where: { $0.name == "stackTrace" })?.value, "stack")
                    XCTAssertEqual(
                        event.eventData.first(where: { $0.name == "severity" })?.value, "ERROR")
                    expectation.fulfill()
                default:
                    XCTFail("Should not be here")
                }
            })
        eventService.sendDiagnostics(message: "error message", callStack: "stack", severity: .error)
        wait(for: [expectation], timeout: 1.0)
    }

    func test_font_diagnostic_processing() {
        let expectation = expectation(description: "test font diagnostics")
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            useDiagnosticEvents: true,
            eventHandler: { event in
                switch event.eventType {
                case .SignalSdkDiagnostic:
                    XCTAssertEqual(
                        event.eventData.first(where: { $0.name == "code" })?.value, "[VIEW]")
                    XCTAssertEqual(
                        event.eventData.first(where: { $0.name == "stackTrace" })?.value,
                        "Font family not found: Arial")
                    XCTAssertEqual(
                        event.eventData.first(where: { $0.name == "severity" })?.value, "ERROR")
                    expectation.fulfill()
                default:
                    XCTFail("Should not be here")
                }
            })
        eventService.sendFontDiagnostics("Arial")
        wait(for: [expectation], timeout: 1.0)
    }

    func test_diagnostic_processing_disabled() {
        let expectation = expectation(description: "test diagnostics")
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            useDiagnosticEvents: false,
            eventHandler: { event in
                switch event.eventType {
                default:
                    expectation.fulfill()
                }
            })
        eventService.sendDiagnostics(message: "error message", callStack: "stack", severity: .error)
        let result = XCTWaiter().wait(for: [expectation], timeout: 2)
        XCTAssertEqual(
            result, .timedOut, "The test should time out since the expectation was not fulfilled.")
    }

    func test_openURL_containsCorrectLayoutId() {
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            useDiagnosticEvents: false,
            eventHandler: { event in
                switch event.eventType {
                default:
                    XCTFail("Should not be here")
                }
            })

        eventService.openURL(
            url: URL(string: "https://www.rokt.com")!, type: .passthrough, completionHandler: {})

        XCTAssertEqual(stubUXHelper.roktEvents.count, 1)
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.OpenUrl))
        XCTAssertEqual(stubUXHelper.layoutId, "pluginId")
        XCTAssertEqual(stubUXHelper.url, "https://www.rokt.com")
        XCTAssertEqual(stubUXHelper.openUrlType, .passthrough)
    }

    func test_send_device_pay_initiated() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemDevicePay(catalogItem: .mock(), paymentProvider: .applePay)

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalCartItemInstantPurchaseInitiated)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        let cartItemId = event?.eventData.first { $0.name == kCartItemId }
        XCTAssertEqual(cartItemId?.value, "cartItemId")
        let catalogItemId = event?.eventData.first { $0.name == kCatalogItemId }
        XCTAssertEqual(catalogItemId?.value, "catalogItemId")
        let currency = event?.eventData.first { $0.name == kCurrency }
        XCTAssertEqual(currency?.value, "USD")
        let description = event?.eventData.first { $0.name == kDescription }
        XCTAssertEqual(description?.value, "Catalog Description")
        let linkedProductId = event?.eventData.first { $0.name == kLinkedProductId }
        XCTAssertEqual(linkedProductId?.value, "linked")
        let totalPrice = event?.eventData.first { $0.name == kTotalPrice }
        XCTAssertEqual(totalPrice?.value, "14.99")
        let quantity = event?.eventData.first { $0.name == kQuantity }
        XCTAssertEqual(quantity?.value, "1")
        let unitPrice = event?.eventData.first { $0.name == kUnitPrice }
        XCTAssertEqual(unitPrice?.value, "14.99")

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 1)
    }

    func test_send_device_pay_succeeded() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "catalogItemId")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemDevicePaySuccess(itemId: "catalogItemId")

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalCartItemInstantPurchase)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        let cartItemId = event?.eventData.first { $0.name == kCartItemId }
        XCTAssertEqual(cartItemId?.value, "cartItemId")
        let catalogItemId = event?.eventData.first { $0.name == kCatalogItemId }
        XCTAssertEqual(catalogItemId?.value, "catalogItemId")
        let currency = event?.eventData.first { $0.name == kCurrency }
        XCTAssertEqual(currency?.value, "USD")
        let description = event?.eventData.first { $0.name == kDescription }
        XCTAssertEqual(description?.value, "Catalog Description")
        let linkedProductId = event?.eventData.first { $0.name == kLinkedProductId }
        XCTAssertEqual(linkedProductId?.value, "linked")
        let totalPrice = event?.eventData.first { $0.name == kTotalPrice }
        XCTAssertEqual(totalPrice?.value, "14.99")
        let quantity = event?.eventData.first { $0.name == kQuantity }
        XCTAssertEqual(quantity?.value, "1")
        let unitPrice = event?.eventData.first { $0.name == kUnitPrice }
        XCTAssertEqual(unitPrice?.value, "14.99")

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 0)
    }

    func test_send_device_pay_failed() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "catalogItemId")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemDevicePayFailure(itemId: "catalogItemId")

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalCartItemInstantPurchaseFailure)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        let cartItemId = event?.eventData.first { $0.name == kCartItemId }
        XCTAssertEqual(cartItemId?.value, "cartItemId")
        let catalogItemId = event?.eventData.first { $0.name == kCatalogItemId }
        XCTAssertEqual(catalogItemId?.value, "catalogItemId")
        let currency = event?.eventData.first { $0.name == kCurrency }
        XCTAssertEqual(currency?.value, "USD")
        let description = event?.eventData.first { $0.name == kDescription }
        XCTAssertEqual(description?.value, "Catalog Description")
        let linkedProductId = event?.eventData.first { $0.name == kLinkedProductId }
        XCTAssertEqual(linkedProductId?.value, "linked")
        let totalPrice = event?.eventData.first { $0.name == kTotalPrice }
        XCTAssertEqual(totalPrice?.value, "14.99")
        let quantity = event?.eventData.first { $0.name == kQuantity }
        XCTAssertEqual(quantity?.value, "1")
        let unitPrice = event?.eventData.first { $0.name == kUnitPrice }
        XCTAssertEqual(unitPrice?.value, "14.99")

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 0)
    }

    func test_send_instant_purchase_initiated() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemInstantPurchase(catalogItem: .mock())

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalCartItemInstantPurchaseInitiated)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        let cartItemId = event?.eventData.first { $0.name == kCartItemId }
        XCTAssertEqual(cartItemId?.value, "cartItemId")
        let catalogItemId = event?.eventData.first { $0.name == kCatalogItemId }
        XCTAssertEqual(catalogItemId?.value, "catalogItemId")
        let currency = event?.eventData.first { $0.name == kCurrency }
        XCTAssertEqual(currency?.value, "USD")
        let description = event?.eventData.first { $0.name == kDescription }
        XCTAssertEqual(description?.value, "Catalog Description")
        let linkedProductId = event?.eventData.first { $0.name == kLinkedProductId }
        XCTAssertEqual(linkedProductId?.value, "linked")
        let totalPrice = event?.eventData.first { $0.name == kTotalPrice }
        XCTAssertEqual(totalPrice?.value, "14.99")
        let quantity = event?.eventData.first { $0.name == kQuantity }
        XCTAssertEqual(quantity?.value, "1")
        let unitPrice = event?.eventData.first { $0.name == kUnitPrice }
        XCTAssertEqual(unitPrice?.value, "14.99")

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 1)
        XCTAssertTrue(stubUXHelper.roktEvents.contains(.CartItemInstantPurchase))
    }

    func test_send_instant_purchase_succeeded() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "catalogItemId")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemInstantPurchaseSuccess(itemId: "catalogItemId")

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalCartItemInstantPurchase)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        let cartItemId = event?.eventData.first { $0.name == kCartItemId }
        XCTAssertEqual(cartItemId?.value, "cartItemId")
        let catalogItemId = event?.eventData.first { $0.name == kCatalogItemId }
        XCTAssertEqual(catalogItemId?.value, "catalogItemId")
        let currency = event?.eventData.first { $0.name == kCurrency }
        XCTAssertEqual(currency?.value, "USD")
        let description = event?.eventData.first { $0.name == kDescription }
        XCTAssertEqual(description?.value, "Catalog Description")
        let linkedProductId = event?.eventData.first { $0.name == kLinkedProductId }
        XCTAssertEqual(linkedProductId?.value, "linked")
        let totalPrice = event?.eventData.first { $0.name == kTotalPrice }
        XCTAssertEqual(totalPrice?.value, "14.99")
        let quantity = event?.eventData.first { $0.name == kQuantity }
        XCTAssertEqual(quantity?.value, "1")
        let unitPrice = event?.eventData.first { $0.name == kUnitPrice }
        XCTAssertEqual(unitPrice?.value, "14.99")

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 0)
    }

    func test_send_instant_purchase_failed() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [
                .mock(catalogItemId: "xyz"),
                .mock(catalogItemId: "catalogItemId"),
            ],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemInstantPurchaseFailure(itemId: "catalogItemId")

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalCartItemInstantPurchaseFailure)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        let cartItemId = event?.eventData.first { $0.name == kCartItemId }
        XCTAssertEqual(cartItemId?.value, "cartItemId")
        let catalogItemId = event?.eventData.first { $0.name == kCatalogItemId }
        XCTAssertEqual(catalogItemId?.value, "catalogItemId")
        let currency = event?.eventData.first { $0.name == kCurrency }
        XCTAssertEqual(currency?.value, "USD")
        let description = event?.eventData.first { $0.name == kDescription }
        XCTAssertEqual(description?.value, "Catalog Description")
        let linkedProductId = event?.eventData.first { $0.name == kLinkedProductId }
        XCTAssertEqual(linkedProductId?.value, "linked")
        let totalPrice = event?.eventData.first { $0.name == kTotalPrice }
        XCTAssertEqual(totalPrice?.value, "14.99")
        let quantity = event?.eventData.first { $0.name == kQuantity }
        XCTAssertEqual(quantity?.value, "1")
        let unitPrice = event?.eventData.first { $0.name == kUnitPrice }
        XCTAssertEqual(unitPrice?.value, "14.99")

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 0)
    }

    func test_given_no_catalogItems_then_send_nothing() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemInstantPurchaseSuccess(itemId: "catalogItemId")
        eventService.cartItemInstantPurchaseFailure(itemId: "catalogItemId")

        // Assert
        XCTAssertEqual(events.count, 0)

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 0)
    }
}

class MockUXHelper: UXEventsDelegate {

    var roktEvents = [RoktEventListenerType]()

    func onOfferEngagement(_ pluginId: String) {
        self.roktEvents.append(.OfferEngagement)
    }

    var sessionId: String?
    var pluginInstanceGuid: String?
    var jwtToken: String?
    var layoutId: String?
    var url: String?
    var openUrlType: RoktUXOpenURLType?
    func onFirstPositiveEngagement(
        sessionId: String, pluginInstanceGuid: String, jwtToken: String, layoutId: String
    ) {
        self.sessionId = sessionId
        self.pluginInstanceGuid = pluginInstanceGuid
        self.jwtToken = jwtToken
        self.layoutId = layoutId
        self.roktEvents.append(.FirstPositiveEngagement)
    }

    func onPositiveEngagement(_ pluginId: String) {
        self.roktEvents.append(.PositiveEngagement)
    }

    func onShowLoadingIndicator(_ pluginId: String) {
        self.roktEvents.append(.ShowLoadingIndicator)
    }

    func onHideLoadingIndicator(_ pluginId: String) {
        self.roktEvents.append(.HideLoadingIndicator)
    }

    func onPlacementInteractive(_ pluginId: String) {
        self.roktEvents.append(.PlacementInteractive)
    }

    func onPlacementReady(_ pluginId: String) {
        self.roktEvents.append(.PlacementReady)
    }

    func onPlacementClosed(_ pluginId: String) {
        self.roktEvents.append(.PlacementClosed)
    }

    func onPlacementCompleted(_ pluginId: String) {
        self.roktEvents.append(.PlacementCompleted)
    }

    func onPlacementFailure(_ pluginId: String) {
        self.roktEvents.append(.PlacementFailure)
    }

    func openURL(
        url: String,
        id: String,
        layoutId: String,
        type: RoktUXOpenURLType,
        onClose: @escaping (String) -> Void,
        onError: @escaping (String, Error?) -> Void
    ) {
        self.roktEvents.append(.OpenUrl)
        self.layoutId = layoutId
        self.url = url
        self.openUrlType = type
    }

    func onCartItemInstantPurchase(_ layoutId: String, catalogItem: RoktUXHelper.CatalogItem) {
        self.roktEvents.append(.CartItemInstantPurchase)
    }

    func onCartItemDevicePay(_ layoutId: String, catalogItem: RoktUXHelper.CatalogItem, paymentProvider: PaymentProvider) {
        self.roktEvents.append(.CartItemDevicePay)
    }
}
