//
//  ShadowStyleModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

@available(iOS 13, *)
struct ShadowStyleModel: Decodable, Hashable {
    let offsetX: Float?
    let offsetY: Float?
    let color: String?
    let blurRadius: Float?
}
