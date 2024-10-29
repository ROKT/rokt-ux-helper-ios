//
//  BNFPlaceholder.swift
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

struct BNFPlaceholder: Equatable {
    let parseableChains: [BNFKeyAndNamespace]
    let defaultValue: String?
}

enum BNFPlaceholderError: Error {
    case mandatoryKeyEmpty
}

struct BNFKeyAndNamespace: Equatable {
    let key: String
    let namespace: BNFNamespace
    var isMandatory: Bool = false
}
