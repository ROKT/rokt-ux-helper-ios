//
//  CatalogItemGroup.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

struct CatalogItemGroup: Codable {
    let groupId: String
    let catalogItemIds: [String]
    let attributes: [CatalogItemGroupAttribute]?
    let metadata: [String: String]?
}

struct CatalogItemGroupAttribute: Codable {
    let attributeId: String
    let label: String?
    let options: [CatalogItemGroupOption]?
    let metadata: [String: String]?
}

struct CatalogItemGroupOption: Codable {
    let label: String?
    let catalogItemIds: [String]?
    let metadata: [String: String]?
}
