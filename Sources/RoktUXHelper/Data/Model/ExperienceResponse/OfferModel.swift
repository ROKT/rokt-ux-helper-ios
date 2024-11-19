//
//  OfferModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

struct OfferModel: Codable {
    let campaignId: String?
    let creative: CreativeModel
    let catalogItems: [CatalogItem]?
}

struct CreativeModel: Codable {
    let referralCreativeId: String
    let instanceGuid: String
    let copy: [String: String]
    let images: [String: CreativeImage]?
    let links: [String: CreativeLink]?

    let responseOptionsMap: ResponseOptionList?
    let jwtToken: String

    enum CodingKeys: String, CodingKey {
        case referralCreativeId
        case instanceGuid
        case copy
        case images
        case links
        case responseOptionsMap
        case jwtToken = "token"
    }
}

struct CreativeImage: Codable, Hashable {
    let light: String?
    let dark: String?
    let alt: String?
    let title: String?

    var hasImageURL: Bool { light?.isEmpty == false || dark?.isEmpty == false }
}

struct ResponseOptionList: Codable {
    let positive: ResponseOption?
    let negative: ResponseOption?
}

struct CreativeLink: Codable, Hashable {
    let url: String?
    let title: String?
}
