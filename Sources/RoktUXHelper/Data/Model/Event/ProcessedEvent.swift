//
//  ProcessedEvent.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

struct ProcessedEvent: Hashable, Equatable {
    let sessionId: String
    let parentGuid: String
    let eventType: EventType
    let pageInstanceGuid: String
    let eventData: [RoktEventNameValue]
}

extension ProcessedEvent {
    init(_ event: RoktEventRequest) {
        self = .init(
            sessionId: event.sessionId,
            parentGuid: event.parentGuid,
            eventType: event.eventType,
            pageInstanceGuid: event.pageInstanceGuid,
            eventData: event.eventData
        )
    }
}
