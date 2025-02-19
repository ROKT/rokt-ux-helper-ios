//
//  RoktUXResponseOption.swift
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
public struct RoktUXResponseOption: Codable, Hashable {
    public let id: String
    public let action: Action?
    public let instanceGuid: String
    public let signalType: RoktUXSignalType?
    public let shortLabel: String?
    public let longLabel: String?
    public let shortSuccessLabel: String?
    public let isPositive: Bool?
    public let url: String?
    public let responseJWTToken: String

    enum CodingKeys: String, CodingKey {
        case id
        case action
        case instanceGuid
        case signalType
        case shortLabel
        case longLabel
        case shortSuccessLabel
        case isPositive
        case url
        case responseJWTToken = "token"
    }
}

public enum RoktUXSignalType: String, Codable, RoktUXCaseIterableDefaultLast {
    case signalResponse = "SignalResponse"
    case signalGatedResponse = "SignalGatedResponse"
    case unknown
}

public enum Action: String, Codable, RoktUXCaseIterableDefaultLast {
    case url = "Url"
    case captureOnly = "CaptureOnly"
    case unknown
}
