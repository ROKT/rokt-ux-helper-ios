//
//  HeightProperty.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI

@available(iOS 13, *)
struct HeightProperty: Decodable, Hashable {
    let dimensionType: HeightDimensionType?

    enum CodingKeys: String, CodingKey {
        case value
        case dimensionType = "type"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let dimensionTypeRaw = try values.decodeIfPresent(String.self, forKey: .dimensionType)

        guard let dimensionTypeRaw else {
            throw CustomDecodingError.invalidKey(name: CodingKeys.dimensionType.rawValue)
        }

        switch dimensionTypeRaw.lowercased() {
        case HeightDimensionType.fixedRaw:
            let value = try values.decodeIfPresent(Float.self, forKey: .value)
            dimensionType = .fixed(value)
        case HeightDimensionType.percentageRaw:
            let value = try values.decodeIfPresent(Float.self, forKey: .value)
            dimensionType = .percentage(value)
        case HeightDimensionType.fitRaw:
            let value = try values.decodeIfPresent(HeightFitProperty.self, forKey: .value)
            dimensionType = .fit(value)
        default:
            throw CustomDecodingError.invalidKey(name: CodingKeys.value.rawValue)
        }
    }

    init(dimensionType: HeightDimensionType?) {
        self.dimensionType = dimensionType
    }

    var heightPercentage: Float? {
        if case .percentage(let heightPercentage) = dimensionType {
            return heightPercentage
        } else {
            return nil
        }
    }
}
