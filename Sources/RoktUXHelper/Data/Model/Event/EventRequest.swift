//
//  EventRequest.swift
//  RoktUXHelper
//
//  Copyright 2020 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

public struct EventRequest: Codable, Hashable {
    public let uuid: String
    public let sessionId: String
    public let eventType: EventType
    public let parentGuid: String
    public let eventTime: String
    public let attributes: [EventNameValue]
    public let metadata: [EventNameValue]
    public let pageInstanceGuid: String
    public let jwtToken: String

    public enum CodingKeys: String, CodingKey {
        case uuid = "instanceGuid"
        case sessionId
        case eventType
        case parentGuid
        case eventTime
        case attributes
        case metadata
        case pageInstanceGuid
        case jwtToken = "token"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        eventType = try container.decode(EventType.self, forKey: .eventType)
        parentGuid = try container.decode(String.self, forKey: .parentGuid)
        eventTime = try container.decode(String.self, forKey: .eventTime)
        attributes = try container.decode([EventNameValue].self, forKey: .attributes)
        metadata = try container.decode([EventNameValue].self, forKey: .metadata)
        pageInstanceGuid = try container.decode(String.self, forKey: .pageInstanceGuid)
        jwtToken = try container.decode(String.self, forKey: .jwtToken)
        uuid = try container.decode(String.self, forKey: .uuid)
    }

    public init(
        sessionId: String,
        eventType: EventType,
        parentGuid: String,
        eventTime: Date = Date(),
        extraMetadata: [EventNameValue] = [EventNameValue](),
        attributes: [String: String] = [String: String](),
        pageInstanceGuid: String = "",
        jwtToken: String
    ) {
        self.uuid = UUID().uuidString
        self.sessionId = sessionId
        self.eventType = eventType
        self.parentGuid = parentGuid
        self.eventTime = EventDateFormatter.getDateString(eventTime)
        self.attributes = EventRequest.convertDictionaryToNameValue(attributes)
        self.pageInstanceGuid = pageInstanceGuid
        self.metadata = [EventNameValue(name: BE_CLIENT_TIME_STAMP,
                                        value: EventDateFormatter.getDateString(eventTime)),
                         EventNameValue(name: BE_CAPTURE_METHOD,
                                        value: kClientProvided)] + extraMetadata
        self.jwtToken = jwtToken
    }

    public var getParams: [String: Any] {
        (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }

    public func getLog() -> String {
        let params: [String: Any] = [
            BE_SESSION_ID_KEY: sessionId,
            BE_PARENT_GUID_KEY: parentGuid,
            BE_PAGE_INSTANCE_GUID_KEY: pageInstanceGuid,
            BE_EVENT_TYPE_KEY: eventType.rawValue,
            BE_METADATA_KEY: getNameValueDictionary(metadata),
            BE_ATTRIBUTES_KEY: getNameValueDictionary(attributes)
        ]

        guard let theJSONData = try? JSONSerialization.data(withJSONObject: params,
                                                            options: []),
              let jsonString = String(data: theJSONData, encoding: .utf8) else {
            return ""
        }
        return "RoktEventLog: \(jsonString)"
    }

    private func getNameValueDictionary(_ nameValues: [EventNameValue]) -> [[String: Any]] {
        return nameValues.map { $0.getDictionaty()}
    }

    private static func convertDictionaryToNameValue(_ from: [String: String]) -> [EventNameValue] {
        return from.map { EventNameValue(name: $0.key, value: $0.value)}
    }
}
