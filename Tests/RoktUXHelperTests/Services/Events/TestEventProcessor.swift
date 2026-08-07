import Foundation
import Combine
import XCTest
@testable import RoktUXHelper

@available(iOS 13.0, *)
final class TestEventProcessor: XCTestCase {

    func testEvents() {
        let expectation = expectation(description: "test event types")
        let allEventTypes = RoktUXEventType.allCases
        let date = Date()

        let sut = EventProcessor(queue: .userInitiated, integrationType: .sdk) { [weak self] payload in
            guard let self,
                  let body: SessionBody = deserialize(payload) else {
                XCTFail("fail unwrapping")
                return
            }

            XCTAssertEqual(body.channel.type, "s2s")
            // single_session pins the batch to the synchronous events path (one session per batch).
            XCTAssertTrue(body.singleSession)
            XCTAssertEqual(body.events.count, 16)

            allEventTypes.forEach { eventType in
                // Each event carries a unique eventData value, so locate it by that.
                guard let event = body.events.first(where: {
                    $0.data["key"] == "value \(eventType.rawValue)"
                }) else {
                    XCTFail("missing event for \(eventType.rawValue)")
                    return
                }
                XCTAssertEqual(event.eventType, Self.expectedType(eventType))
                XCTAssertFalse(event.instanceId.isEmpty)
                XCTAssertEqual(event.sessionId, "sessionId")
                XCTAssertEqual(event.data["name"], "meta \(eventType.rawValue)")
                XCTAssertEqual(event.data["capture_method"], kClientProvided)
                XCTAssertEqual(event.data["parent_id"], "parentGuid")
                XCTAssertEqual(event.data["token"], "token")
                XCTAssertEqual(event.data["page_instance_guid"], "pageInstanceGuid")
            }
            expectation.fulfill()
        }

        allEventTypes.forEach {
            sut.handle(
                event: mockEvent(
                    eventType: $0,
                    date: date,
                    extraMetadata: [.init(name: "name", value: "meta \($0.rawValue)")],
                    eventData: ["key": "value \($0.rawValue)"]
                )
            )
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testS2SEvents() {
        let expectation = expectation(description: "test s2s event types")
        let allEventTypes = RoktUXEventType.allCases
        let date = Date()

        let sut = EventProcessor(queue: .userInitiated, integrationType: .s2s) { [weak self] payload in
            guard let self,
                  let body: SessionBody = deserialize(payload) else {
                XCTFail("fail unwrapping")
                return
            }

            // S2S filters SignalLoadStart / SignalLoadComplete.
            XCTAssertEqual(body.events.count, 14)
            expectation.fulfill()
        }
        allEventTypes.forEach {
            sut.handle(
                event: mockEvent(
                    eventType: $0,
                    date: date,
                    extraMetadata: [.init(name: "name", value: "meta \($0.rawValue)")],
                    eventData: ["key": "value \($0.rawValue)"]
                )
            )
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testEventDelayProcessing() {
        var expectation = expectation(description: "wait")
        var received: [SessionBody.Event]?
        let sut = EventProcessor(delay: 0.5, queue: .userInitiated) { [weak self] payload in
            guard let self else {
                XCTFail("Fail self")
                return
            }
            received = deserialize(payload)?.events
            expectation.fulfill()
        }

        sut.handle(event: mockEvent(eventType: .SignalActivation, date: Date()))
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(received?.count, 1)
        XCTAssertEqual(received?.first?.eventType, "user_interaction")

        expectation = XCTestExpectation(description: "wait again")
        sut.handle(event: mockEvent(eventType: .SignalViewed, date: Date()))
        microSleep(0.1)
        sut.handle(event: mockEvent(eventType: .SignalImpression, date: Date()))
        microSleep(0.1)
        sut.handle(event: mockEvent(eventType: .SignalResponse, date: Date()))
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(received?.count, 3)
        XCTAssertEqual(received?[0].eventType, "viewed")
        XCTAssertEqual(received?[1].eventType, "impression")
        XCTAssertEqual(received?[2].eventType, "signal_response")
    }

    func testEventRemoveDuplicates() {
        let expectation = expectation(description: "test duplicates")
        var received: [SessionBody.Event]?
        let sut = EventProcessor(queue: .userInitiated) { [weak self] payload in
            guard let self else {
                XCTFail("Fail self")
                return
            }
            received = deserialize(payload)?.events
            expectation.fulfill()
        }
        let date = Date()

        // Exact duplicate — deduplicated.
        let event1 = mockEvent(
            eventType: .SignalViewed, date: date,
            sessionId: "session1", parentGuid: "parent1", pageInstanceGuid: "page1"
        )
        sut.handle(event: event1)
        sut.handle(event: event1)

        // Different sessionId / parentGuid / pageInstanceGuid / eventType / data — NOT deduplicated.
        sut.handle(event: mockEvent(
            eventType: .SignalViewed,
            date: date,
            sessionId: "session2",
            parentGuid: "parent1",
            pageInstanceGuid: "page1"
        ))
        sut.handle(event: mockEvent(
            eventType: .SignalViewed,
            date: date,
            sessionId: "session1",
            parentGuid: "parent2",
            pageInstanceGuid: "page1"
        ))
        sut.handle(event: mockEvent(
            eventType: .SignalViewed,
            date: date,
            sessionId: "session1",
            parentGuid: "parent1",
            pageInstanceGuid: "page2"
        ))
        sut.handle(event: mockEvent(
            eventType: .SignalImpression,
            date: date,
            sessionId: "session1",
            parentGuid: "parent1",
            pageInstanceGuid: "page1"
        ))
        sut.handle(event: mockEvent(
            eventType: .SignalViewed,
            date: date,
            sessionId: "session1",
            parentGuid: "parent1",
            pageInstanceGuid: "page1",
            eventData: ["key": "value1"]
        ))
        sut.handle(event: mockEvent(
            eventType: .SignalViewed,
            date: date,
            sessionId: "session1",
            parentGuid: "parent1",
            pageInstanceGuid: "page1",
            eventData: ["key": "value2"]
        ))

        // Same event, same data — deduplicated.
        let event7 = mockEvent(
            eventType: .SignalActivation,
            date: date,
            sessionId: "session1",
            parentGuid: "parent1",
            pageInstanceGuid: "page1",
            eventData: ["key": "value"]
        )
        sut.handle(event: event7)
        sut.handle(event: event7)

        // Metadata does NOT affect deduplication.
        sut.handle(event: mockEvent(
            eventType: .SignalResponse,
            date: date,
            sessionId: "session1",
            parentGuid: "parent1",
            pageInstanceGuid: "page1",
            extraMetadata: [.init(name: "meta1", value: "value1")]
        ))
        sut.handle(event: mockEvent(
            eventType: .SignalResponse,
            date: date,
            sessionId: "session1",
            parentGuid: "parent1",
            pageInstanceGuid: "page1",
            extraMetadata: [.init(name: "meta2", value: "value2")]
        ))

        wait(for: [expectation], timeout: 1)

        XCTAssertNotNil(received, "Payload should not be nil")
        XCTAssertEqual(received?.count, 9, "Should have 9 unique events after deduplication")
        XCTAssertEqual(received?.filter { $0.eventType == "viewed" }.count, 6)
        XCTAssertEqual(received?.filter { $0.eventType == "impression" }.count, 1)
        // SignalActivation maps to user_interaction.
        XCTAssertEqual(received?.filter { $0.eventType == "user_interaction" }.count, 1)
        XCTAssertEqual(received?.filter { $0.eventType == "signal_response" }.count, 1)
    }

    func testEventDeduplicationDetails() {
        let expectation = expectation(description: "test detailed deduplication")
        var received: [SessionBody.Event]?
        let sut = EventProcessor(queue: .userInitiated) { [weak self] payload in
            guard let self else {
                XCTFail("Fail self")
                return
            }
            received = deserialize(payload)?.events
            expectation.fulfill()
        }

        let baseEvent = mockEvent(
            eventType: .SignalViewed, date: Date(),
            sessionId: "session1", parentGuid: "parent1", pageInstanceGuid: "page1",
            eventData: ["key": "value"]
        )
        sut.handle(event: baseEvent)
        sut.handle(event: mockEventWithModification(
            baseEvent: baseEvent,
            modifyMetadata: [.init(name: "differentMeta", value: "value")]
        ))
        sut.handle(event: mockEventWithModification(baseEvent: baseEvent, modifyDate: Date(timeIntervalSinceNow: 100)))
        sut.handle(event: mockEventWithModification(baseEvent: baseEvent, modifyJwtToken: "differentToken"))

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(received?.count, 1, "All events should be considered duplicates except for the first one")
    }

    func testSignalUserInteractionBypassesDeduplication() {
        let expectation = expectation(description: "user interaction should not deduplicate")
        var received: [SessionBody.Event]?
        let date = Date()

        let sut = EventProcessor(queue: .userInitiated) { [weak self] payload in
            guard let self else {
                XCTFail("Fail self")
                return
            }
            received = deserialize(payload)?.events
            expectation.fulfill()
        }

        let event = mockEvent(eventType: .SignalUserInteraction, date: date, eventData: ["action": "click"])
        sut.handle(event: event)
        sut.handle(event: event)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(received?.count, 2)
        XCTAssertEqual(received?.filter { $0.eventType == "user_interaction" }.count, 2)
    }

    func testDelayProcessorDeallocation() {
        let expectation = expectation(description: "wait")
        var received: [SessionBody.Event]?
        weak var weakSut: EventProcessor?
        var sut: EventProcessor? = EventProcessor(delay: 1, queue: .userInitiated) { [weak self] payload in
            guard let self else {
                XCTFail("Fail self")
                return
            }
            XCTAssertNotNil(weakSut)
            received = deserialize(payload)?.events
            expectation.fulfill()
        }
        weakSut = sut
        sut?.handle(event: mockEvent(eventType: .SignalActivation, date: Date()))
        sut = nil

        wait(for: [expectation], timeout: 3)

        XCTAssertNil(weakSut)
        XCTAssertEqual(received?.count, 1)
        XCTAssertEqual(received?.first?.eventType, "user_interaction")
    }

    // MARK: - Helpers

    /// Decodes the `v2/sessions/events` body emitted by the processor.
    private struct SessionBody: Decodable {
        struct Channel: Decodable { let type: String }
        struct Event: Decodable {
            let eventType: String
            let instanceId: String
            let sessionId: String
            let timestamp: Int64
            let data: [String: String]

            enum CodingKeys: String, CodingKey {
                case eventType = "event_type"
                case instanceId = "instance_id"
                case sessionId = "session_id"
                case timestamp
                case data
            }
        }
        let channel: Channel
        let singleSession: Bool
        let events: [Event]

        enum CodingKeys: String, CodingKey {
            case channel
            case singleSession = "single_session"
            case events
        }
    }

    /// Mirrors the production legacy-enum → registry-string mapping.
    private static func expectedType(_ eventType: RoktUXEventType) -> String {
        switch eventType {
        case .SignalImpression: return "impression"
        case .SignalViewed: return "viewed"
        case .SignalResponse: return "signal_response"
        case .SignalGatedResponse: return "signal_gated_response"
        case .SignalDismissal: return "dismissal"
        case .SignalInitialize: return "signal_initialize"
        case .SignalLoadStart: return "load_start"
        case .SignalLoadComplete: return "load_complete"
        case .SignalActivation, .SignalUserInteraction: return "user_interaction"
        case .SignalSdkDiagnostic: return "sdk_diagnostic"
        case .SignalCartItemInstantPurchase: return "cart_item_instant_purchase"
        case .SignalCartItemInstantPurchaseFailure: return "cart_item_instant_purchase_failure"
        case .SignalCartItemInstantPurchaseInitiated: return "cart_item_instant_purchase_initiated"
        case .SignalInstantPurchaseDismissal: return "instant_purchase_dismissal"
        case .CaptureAttributes: return "capture_attributes"
        }
    }

    private func microSleep(_ seconds: Double) {
        usleep(useconds_t(Int32(seconds * 1000000)))
    }

    private func deserialize(_ events: [String: Any]) -> SessionBody? {
        let data = try? JSONSerialization.data(withJSONObject: events, options: [])
        return data.flatMap { try? JSONDecoder().decode(SessionBody.self, from: $0) }
    }

    private func mockEvent(
        eventType: RoktUXEventType,
        date: Date,
        sessionId: String = "sessionId",
        parentGuid: String = "parentGuid",
        pageInstanceGuid: String = "pageInstanceGuid",
        extraMetadata: [RoktEventNameValue] = [],
        eventData: [String: String] = [:]
    ) -> RoktEventRequest {
        .init(
            sessionId: sessionId,
            eventType: eventType,
            parentGuid: parentGuid,
            eventTime: date,
            extraMetadata: extraMetadata,
            eventData: eventData,
            pageInstanceGuid: pageInstanceGuid,
            jwtToken: "token"
        )
    }

    private func mockEventWithModification(
        baseEvent: RoktEventRequest,
        modifyDate: Date? = nil,
        modifyMetadata: [RoktEventNameValue]? = nil,
        modifyJwtToken: String? = nil
    ) -> RoktEventRequest {
        .init(
            sessionId: baseEvent.sessionId,
            eventType: baseEvent.eventType,
            parentGuid: baseEvent.parentGuid,
            eventTime: modifyDate ?? EventDateFormatter.dateFormatter.date(from: baseEvent.eventTime)!,
            extraMetadata: modifyMetadata ?? baseEvent.metadata,
            eventData: baseEvent.eventData.reduce(into: [String: String]()) { $0[$1.name] = $1.value },
            pageInstanceGuid: baseEvent.pageInstanceGuid,
            jwtToken: modifyJwtToken ?? baseEvent.jwtToken
        )
    }
}
