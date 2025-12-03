//
//  EventProcessor.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import Combine

private let defaultEventBufferDuration: TimeInterval = 0.025

@available(iOS 13.0, *)
protocol EventProcessing {
    var publisher: PassthroughSubject<(RoktEventRequest, EventProcessor?), Never> { get }

    func handle(event: RoktEventRequest)
}

@available(iOS 13.0, *)
class EventProcessor: EventProcessing {
    private var cancellables: Set<AnyCancellable> = []
    private var processedEvents: Set<ProcessedEvent> = []
    private var onRoktPlatformEvent: (([String: Any]) -> Void)?
    // EventProcessor is being passed in so that the publisher will always finish publishing before the Processor class gets deallocated.
    private(set) var publisher: PassthroughSubject<(RoktEventRequest, EventProcessor?), Never> = .init()

    /// Event types that should bypass deduplication logic
    private static let excludedFromDeduplication: Set<RoktUXEventType> = [
        .SignalUserInteraction,
        .SignalCartItemInstantPurchaseInitiated
    ]

    init(
        delay: Double = defaultEventBufferDuration,
        queue: DispatchQueue = DispatchQueue.background,
        integrationType: HelperIntegrationType = .s2s,
        onRoktPlatformEvent: (([String: Any]) -> Void)?
    ) {
        self.onRoktPlatformEvent = onRoktPlatformEvent

        publisher
            // Skip specific event types for S2S integration
            .filter { event, _ in
                guard integrationType == .s2s else { return true }
                return ![.SignalLoadStart, .SignalLoadComplete].contains(event.eventType)
            }
            // Deduplicate events (excluding specific event types)
            .filter { event, processor in
                guard let processor = processor else { return false }
                if Self.excludedFromDeduplication.contains(event.eventType) {
                    return true
                }
                return processor.processedEvents.insert(.init(event)).inserted
            }
            .collect(.byTime(queue, .seconds(delay)))
            // Transform to payload
            .map { events -> (RoktUXEventsPayload, EventProcessor?) in
                return (RoktUXEventsPayload(events: events.map(\.0)), events.first?.1)
            }
            // Serialize payload
            .compactMap { payload, processor in
                guard let serializedData = processor?.serialize(payload: payload) else {
                    return nil
                }
                return (serializedData, processor)
            }
            // Send to platform handler
            .sink { _ in } receiveValue: { (event: [String: Any], processor: EventProcessor?) in
                processor?.onRoktPlatformEvent?(event)
            }
            .store(in: &cancellables)
    }

    func handle(event: RoktEventRequest) {
        publisher.send((event, self))
    }

    private func serialize(payload: RoktUXEventsPayload) -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(payload)
            guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            return jsonObject
        } catch {
            return nil
        }
    }
}
