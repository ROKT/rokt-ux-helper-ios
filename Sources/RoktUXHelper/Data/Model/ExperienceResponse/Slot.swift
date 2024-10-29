//
//  Slot.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

public struct Slot: Codable {
    public let instanceGuid: String
    public let offer: Offer?
    public let slotJWTToken: String

    enum CodingKeys: String, CodingKey {
        case instanceGuid
        case offer
        case slotJWTToken = "token"
    }
}
