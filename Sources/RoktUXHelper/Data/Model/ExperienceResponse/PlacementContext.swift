//
//  PlacementContext.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

public struct PlacementContext: Codable {
    public let roktTagId: String
    public let pageInstanceGuid: String
    public let placementContextJWTToken: String

    enum CodingKeys: String, CodingKey {
        case roktTagId
        case pageInstanceGuid
        case placementContextJWTToken = "token"
    }
}
