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

@available(iOS 13.0, *)
protocol EventProcessing {
    var publisher: PassthroughSubject<EventRequest, Never> { get }
    
    func handle(event: EventRequest)
}

@available(iOS 13.0, *)
class EventProcessor: EventProcessing {
    private var cancellables: Set<AnyCancellable> = .init()
    private var processedEvents: Set<ProcessedEvent> = .init()
    private var onRoktPlatformEvent: (([String: Any]) -> Void)?
    private(set) var publisher: PassthroughSubject<EventRequest, Never> = .init()
    
    init(
        delay: Double = kEventDelay,
        queue: DispatchQueue = DispatchQueue.background,
        integrationType: HelperIntegrationType = .s2s,
        onRoktPlatformEvent: (([String: Any]) -> Void)?
    ) {
        self.onRoktPlatformEvent = onRoktPlatformEvent
        publisher
            .filter {
                if integrationType == .s2s &&
                    ($0.eventType == .SignalLoadStart ||
                     $0.eventType == .SignalLoadComplete) {
                    return false
                }
                return true
            }
            .filter { [weak self] in
                self?.processedEvents.insert(.init($0)).inserted == true
            }
            .collect(.byTime(queue, .seconds(delay)), options: nil)
            .map(EventsPayload.init(events:))
            .encode(encoder: JSONEncoder())
            .map {
                (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] ?? [:]
            }
            .sink(receiveCompletion: {_ in }, receiveValue: { [weak self] in
                self?.onRoktPlatformEvent?($0)
            })
            .store(in: &cancellables)
    }
    
    func handle(event: EventRequest) {
        publisher.send(event)
    }
}
