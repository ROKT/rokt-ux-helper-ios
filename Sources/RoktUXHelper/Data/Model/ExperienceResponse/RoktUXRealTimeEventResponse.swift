//
//  RoktUXRealTimeEventResponse.swift
//
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

public struct RoktUXRealTimeEventResponse: Codable, Hashable {
    public let triggerGuid: String?
    public let triggerEvent: String?
    public let eventType: String?
    public let payload: String?

    public init(
        triggerGuid: String?,
        triggerEvent: String?,
        eventType: String?,
        payload: String?
    ) {
        self.triggerGuid = triggerGuid
        self.triggerEvent = triggerEvent
        self.eventType = eventType
        self.payload = payload
    }

    public func isValid() -> Bool {
        if triggerGuid == nil || triggerEvent == nil || eventType == nil || payload == nil {
            return false
        }
        return true
    }
}
