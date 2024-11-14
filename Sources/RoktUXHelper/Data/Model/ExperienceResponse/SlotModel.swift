//
//  SlotModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

struct SlotModel: Decodable {
    let instanceGuid: String?

    // contains BNF placeholder Strings
    // has properties or nested entities with properties that provide the actual value of BNF placeholder Strings
    let offer: OfferModel?

    let layoutVariant: LayoutVariantModel?

    let jwtToken: String

    enum CodingKeys: String, CodingKey {
        case instanceGuid
        case offer
        case layoutVariant
        case jwtToken = "token"
    }

    func toSlotOfferModel() -> SlotOfferModel {
        return SlotOfferModel(offer: offer)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.instanceGuid = try container.decodeIfPresent(String.self, forKey: .instanceGuid)
        self.offer = try container.decodeIfPresent(OfferModel.self, forKey: .offer)
        self.layoutVariant = try container.decodeIfPresent(LayoutVariantModel.self, forKey: .layoutVariant)
        self.jwtToken = try container.decode(String.self, forKey: .jwtToken)
    }
}
