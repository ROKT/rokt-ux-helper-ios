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

    func test_sendDismissal_onInstantPurchaseDismissed_dismissalEventsAndSignals_shouldSend() throws {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.dismissOption = .instantPurchaseDismiss
        eventService.sendDismissalEvent()

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalInstantPurchaseDismissal)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)
        XCTAssertNotNil(event?.metadata.first { $0.name == kInitiator })
        XCTAssertNotNil(event?.metadata.first { $0.value == kInstantPurchaseDismiss })

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
        eventService.cartItemDevicePay(catalogItem: .mock(), paymentProvider: .applePay) { _ in
            // Completion handler - not called immediately
        }

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalCartItemInstantPurchaseInitiated)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)

        // Check objectData contains catalogItemId and quantity
        XCTAssertNotNil(event?.objectData, "objectData should not be nil")
        XCTAssertEqual(event?.objectData?[kCatalogItemId], "catalogItemId")
        XCTAssertEqual(event?.objectData?[kQuantity], "1")

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

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 0)
    }

    func test_device_pay_completion_handler_flow() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "catalogItemId")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        var completionCalled = false
        var receivedStatus: DevicePayStatus?

        // Act - First call cartItemDevicePay (completion should be stored but not called)
        eventService.cartItemDevicePay(catalogItem: .mock(), paymentProvider: .applePay) { status in
            completionCalled = true
            receivedStatus = status
        }

        // Assert - Completion should not be called yet
        XCTAssertFalse(completionCalled, "Completion should not be called immediately")

        // Act - Then call cartItemDevicePaySuccess (completion should be called)
        eventService.cartItemDevicePaySuccess(itemId: "catalogItemId")

        // Assert - Completion should now be called with success status
        XCTAssertTrue(completionCalled, "Completion should be called on success")
        XCTAssertEqual(receivedStatus, .success, "Completion should receive .success status")

        // Verify events were sent
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].eventType, .SignalCartItemInstantPurchaseInitiated)
        XCTAssertEqual(events[1].eventType, .SignalCartItemInstantPurchase)
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

        // Rokt callbacks
        XCTAssertEqual(stubUXHelper.roktEvents.count, 0)
    }

    func test_device_pay_completion_handler_called_on_failure() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "catalogItemId")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        var completionCalled = false
        var receivedStatus: DevicePayStatus?

        // Act - First call cartItemDevicePay (completion should be stored but not called)
        eventService.cartItemDevicePay(catalogItem: .mock(), paymentProvider: .applePay) { status in
            completionCalled = true
            receivedStatus = status
        }

        // Assert - Completion should not be called yet
        XCTAssertFalse(completionCalled, "Completion should not be called immediately")

        // Act - Then call cartItemDevicePayFailure (completion should be called with .failure)
        eventService.cartItemDevicePayFailure(itemId: "catalogItemId")

        // Assert - Completion should be called with failure status
        XCTAssertTrue(completionCalled, "Completion should be called on failure")
        XCTAssertEqual(receivedStatus, .failure, "Completion should receive .failure status")

        // Verify events were sent
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].eventType, .SignalCartItemInstantPurchaseInitiated)
        XCTAssertEqual(events[1].eventType, .SignalCartItemInstantPurchaseFailure)
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

    func test_cartItemUserInteraction_sendsUserInteractionEvent() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "catalogItemId")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemUserInteraction(
            itemId: "catalogItemId",
            action: .ThumbnailClick,
            context: .CatalogImageGallery)

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalUserInteraction)
        XCTAssertEqual(event?.pageInstanceGuid, mockPageInstanceGuid)

        // Check objectData contains action and context
        XCTAssertNotNil(event?.objectData, "objectData should not be nil")
        XCTAssertEqual(event?.objectData?[kAction], "ThumbnailClick")
        XCTAssertEqual(event?.objectData?[kContext], "CatalogImageGallery")
    }

    func test_cartItemUserInteraction_withDropDownItemSelected() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "item1")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemUserInteraction(
            itemId: "item1",
            action: .DropDownItemSelected,
            context: .CatalogDropDown)

        // Assert
        let event = events.first
        XCTAssertEqual(event?.eventType, .SignalUserInteraction)
        XCTAssertEqual(event?.objectData?[kAction], "DropDownItemSelected")
        XCTAssertEqual(event?.objectData?[kContext], "CatalogDropDown")
    }

    func test_cartItemUserInteraction_withMainImageScrollActions() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "item1")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act - Left scroll
        eventService.cartItemUserInteraction(
            itemId: "item1",
            action: .MainImageScrollIconLeftClick,
            context: .CatalogImageGallery)

        // Assert
        let leftEvent = events.first
        XCTAssertEqual(leftEvent?.eventType, .SignalUserInteraction)
        XCTAssertEqual(leftEvent?.objectData?[kAction], "MainImageScrollIconLeftClick")
        XCTAssertEqual(leftEvent?.objectData?[kContext], "CatalogImageGallery")

        // Act - Right scroll
        eventService.cartItemUserInteraction(
            itemId: "item1",
            action: .MainImageScrollIconRightClick,
            context: .CatalogImageGallery)

        // Assert
        XCTAssertEqual(events.count, 2)
        let rightEvent = events.last
        XCTAssertEqual(rightEvent?.eventType, .SignalUserInteraction)
        XCTAssertEqual(rightEvent?.objectData?[kAction], "MainImageScrollIconRightClick")
        XCTAssertEqual(rightEvent?.objectData?[kContext], "CatalogImageGallery")
    }

    func test_cartItemUserInteraction_withSwipeActions() {
        // Arrange
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [.mock(catalogItemId: "item1")],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act - Swipe left
        eventService.cartItemUserInteraction(
            itemId: "item1",
            action: .MainImageSwipeLeft,
            context: .CatalogImageGallery)

        // Assert
        let swipeLeftEvent = events.first
        XCTAssertEqual(swipeLeftEvent?.eventType, .SignalUserInteraction)
        XCTAssertEqual(swipeLeftEvent?.objectData?[kAction], "MainImageSwipeLeft")
        XCTAssertEqual(swipeLeftEvent?.objectData?[kContext], "CatalogImageGallery")

        // Act - Swipe right
        eventService.cartItemUserInteraction(
            itemId: "item1",
            action: .MainImageSwipeRight,
            context: .CatalogImageGallery)

        // Assert
        XCTAssertEqual(events.count, 2)
        let swipeRightEvent = events.last
        XCTAssertEqual(swipeRightEvent?.eventType, .SignalUserInteraction)
        XCTAssertEqual(swipeRightEvent?.objectData?[kAction], "MainImageSwipeRight")
        XCTAssertEqual(swipeRightEvent?.objectData?[kContext], "CatalogImageGallery")
    }

    func test_cartItemUserInteraction_sendsCorrectParentGuid() {
        // Arrange
        let catalogItem = CatalogItem.mock(catalogItemId: "item1")
        let eventService = get_mock_event_processor(
            startDate: startDate,
            catalogItems: [catalogItem],
            uxEventDelegate: stubUXHelper,
            eventHandler: { event in
                self.events.append(event)
            })

        // Act
        eventService.cartItemUserInteraction(
            itemId: "item1",
            action: .ThumbnailClick,
            context: .CatalogImageGallery)

        // Assert
        let event = events.first
        XCTAssertEqual(event?.parentGuid, catalogItem.instanceGuid, "Should use catalog item's instanceGuid as parentGuid")
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
