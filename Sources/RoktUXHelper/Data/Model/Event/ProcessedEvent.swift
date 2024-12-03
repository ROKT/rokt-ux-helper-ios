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

public struct ProcessedEvent: Hashable, Equatable {
    let sessionId: String
    let parentGuid: String
    let eventType: EventType
    let pageInstanceGuid: String
    let eventData: [RoktEventNameValue]
}

extension ProcessedEvent {
    public init(_ event: RoktEventRequest) {
        self = .init(
            sessionId: event.sessionId,
            parentGuid: event.parentGuid,
            eventType: event.eventType,
            pageInstanceGuid: event.pageInstanceGuid,
            eventData: event.eventData
        )
    }
    
    private var attributesAsString: String {
        let eventDataDict: [String: String] = eventData
            .map { $0.getDictionary() }
            .flatMap { $0 }
            .reduce([String:String]()) { (dict, tuple) in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            }
        return eventDataDict
            .sorted(by: { $0.0 < $1.0 })
            .map { "\($0):\($1)" }
            .joined(separator: "")
    }
    
    @available(iOS 13.0, *)
    public func getHashString() -> String {
        return [sessionId, parentGuid, eventType.rawValue, pageInstanceGuid, attributesAsString]
            .joined(separator: "")
            .sha256()
    }
}
