//
//  Placement.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

public struct Placement: Codable {
    public let id: String
    public let targetElementSelector: String
    public let offerLayoutCode: String
    public let placementLayoutCode: PlacementLayoutCode?
    public let placementConfigurables: [String: String]?
    public let instanceGuid: String
    public let slots: [Slot]?
    public let placementsJWTToken: String

    enum CodingKeys: String, CodingKey {
        case id
        case targetElementSelector
        case offerLayoutCode
        case placementLayoutCode
        case placementConfigurables
        case instanceGuid
        case slots
        case placementsJWTToken = "token"
    }
}
