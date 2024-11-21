//
//  CatalogItem.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

struct CatalogItem: Codable {
    let images: [String: CreativeImage]?
    let catalogItemId: String?
    let cartItemId: String?
    let instanceGuid: String?
    let title: String?
    let description: String?
    let price: Decimal?
    let originalPrice: Decimal?
    let originalPriceFormatted: String?
    let currency: String?
    let linkedProductId: String?
    let positiveResponseText: String?
    let negativeResponseText: String?
    let providerData: String?
    let token: String?
    
    init(images: [String : CreativeImage]? = nil,
         catalogItemId: String? = nil,
         cartItemId: String? = nil,
         instanceGuid: String? = nil,
         title: String? = nil,
         description: String? = nil,
         price: Decimal? = nil,
         originalPrice: Decimal? = nil,
         originalPriceFormatted: String? = nil,
         currency: String? = nil,
         linkedProductId: String? = nil,
         positiveResponseText: String? = nil,
         negativeResponseText: String? = nil,
         providerData: String? = nil,
         token: String? = nil) {
        self.images = images
        self.catalogItemId = catalogItemId
        self.cartItemId = cartItemId
        self.instanceGuid = instanceGuid
        self.title = title
        self.description = description
        self.price = price
        self.originalPrice = originalPrice
        self.originalPriceFormatted = originalPriceFormatted
        self.currency = currency
        self.linkedProductId = linkedProductId
        self.positiveResponseText = positiveResponseText
        self.negativeResponseText = negativeResponseText
        self.providerData = providerData
        self.token = token
    }
}
