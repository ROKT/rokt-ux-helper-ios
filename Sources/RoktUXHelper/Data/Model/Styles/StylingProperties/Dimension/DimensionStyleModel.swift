//
//  DimensionStylingPropertiesModel.swift
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
struct DimensionStylingPropertiesModel: Decodable, Hashable {
    let width: WidthProperty?
    let minWidth: Float?
    let maxWidth: Float?

    let height: HeightProperty?
    let minHeight: Float?
    let maxHeight: Float?
}

@available(iOS 13, *)
enum HeightDimensionType: Decodable, Hashable {
    static let fixedRaw = "fixed"
    static let percentageRaw = "percentage"
    static let fitRaw = "fit"

    case fixed(Float?)
    case percentage(Float?)
    case fit(HeightFitProperty?)
}

@available(iOS 13, *)
enum WidthDimensionType: Decodable, Hashable {
    static let fixedRaw = "fixed"
    static let percentageRaw = "percentage"
    static let fitRaw = "fit"

    case fixed(Float?)
    case percentage(Float?)
    case fit(WidthFitProperty?)
}

@available(iOS 13, *)
enum HeightFitProperty: String, Codable, Hashable, RoktUXCaseIterableDefaultLast {
    case fitHeight = "fit-height"
    case wrapContent = "wrap-content"
}

@available(iOS 13, *)
enum WidthFitProperty: String, Codable, Hashable, RoktUXCaseIterableDefaultLast {
    case fitWidth = "fit-width"
    case wrapContent = "wrap-content"
}
