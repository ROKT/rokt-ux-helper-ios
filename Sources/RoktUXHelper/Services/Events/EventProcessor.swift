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

private let defaultEventBufferDuration: Double = 0.025

@available(iOS 13.0, *)
protocol EventProcessing {
    var publisher: PassthroughSubject<(RoktEventRequest, EventProcessor?), Never> { get }

    func handle(event: RoktEventRequest)
}

@available(iOS 13.0, *)
class EventProcessor: EventProcessing {
    private var cancellables: Set<AnyCancellable> = .init()
    private var processedEvents: Set<ProcessedEvent> = .init()
    private var onRoktPlatformEvent: (([String: Any]) -> Void)?
    // EventProcessor is being passed in so that the publisher will always finish publishing before the Processor class gets deallocated.
    private(set) var publisher: PassthroughSubject<(RoktEventRequest, EventProcessor?), Never> = .init()

    init(
        delay: Double = defaultEventBufferDuration,
        queue: DispatchQueue = DispatchQueue.background,
        integrationType: HelperIntegrationType = .s2s,
        onRoktPlatformEvent: (([String: Any]) -> Void)?
    ) {
        self.onRoktPlatformEvent = onRoktPlatformEvent
        publisher
            .filter { (event, processor) in
                if integrationType == .s2s &&
                    (event.eventType == .SignalLoadStart ||
                     event.eventType == .SignalLoadComplete) {
                    return false
                }
                return true
            }
            .filter { (event, processor) in
                processor?.processedEvents.insert(.init(event)).inserted == true
            }
            .collect(.byTime(queue, .seconds(delay)), options: nil)
            .map {
                (RoktUXEventsPayload.init(events: $0.map(\.0)), $0.first?.1)
            }
            .compactMap { (events, processor) in
                guard let payload = processor?.serializeData(payload: events) else { return nil }
                return (payload, processor)
            }
            .sink(
                receiveCompletion: {_ in },
                receiveValue: { (event: [String: Any], processor: EventProcessor?) in
                    processor?.onRoktPlatformEvent?(event)
                }
            )
            .store(in: &cancellables)
    }

    func handle(event: RoktEventRequest) {
        publisher.send((event, self))
    }

    private func serializeData(payload: RoktUXEventsPayload) -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
}
