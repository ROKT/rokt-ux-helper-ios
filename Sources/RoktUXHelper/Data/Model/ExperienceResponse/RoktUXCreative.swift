//
//  RoktUXCreative.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

public struct RoktUXCreative: Codable {
    public let referralCreativeId: String
    public let instanceGuid: String
    public let copy: [String: String]
    public let responseOptions: [RoktUXResponseOption]?
    public let creativeJWTToken: String

    enum CodingKeys: String, CodingKey {
        case referralCreativeId
        case instanceGuid
        case copy
        case responseOptions
        case creativeJWTToken = "token"
    }
}
