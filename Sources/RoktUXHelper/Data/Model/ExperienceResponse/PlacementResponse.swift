//
//  PlacementResponse.swift
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
public class PlacementResponse: Decodable {
    public let sessionId: String
    public let page: Page?
    public let placementContext: PlacementContext
    public let placements: [Placement]
    // outermost `token`
    public let responseJWTToken: String

    enum CodingKeys: String, CodingKey {
        case sessionId
        case page
        case placementContext
        case placements
        case responseJWTToken = "token"
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        sessionId = try container.decode(String.self, forKey: .sessionId)
        page = try container.decodeIfPresent(Page.self, forKey: .page)
        placementContext = try container.decode(PlacementContext.self, forKey: .placementContext)
        placements = try container.decode([Placement].self, forKey: .placements)
        responseJWTToken = try container.decode(String.self, forKey: .responseJWTToken)
    }
}
