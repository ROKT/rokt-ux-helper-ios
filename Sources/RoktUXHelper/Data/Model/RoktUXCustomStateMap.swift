//
//  RoktUXCustomStateMap.swift
//  
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

extension RoktUXCustomStateMap {
    mutating func toggleValueFor(_ customStateId: Any?) -> RoktUXCustomStateMap {
        guard let customStateId = customStateId as? CustomStateIdentifiable else {
            return self
        }
        // Toggle value between 0 and 1 (if nil, toggle on to 1)
        self.updateValue((self[customStateId] ?? 0 == 1) ? 0 : 1, forKey: customStateId)
        return self
    }
}

public typealias RoktUXCustomStateMap = [CustomStateIdentifiable: Int]

public struct CustomStateIdentifiable: Hashable, Codable {
    let position: Int?
    let key: String
    
    public init(position: Int?, key: String) {
        self.position = position
        self.key = key
    }
}

extension CustomStateIdentifiable {
    enum Keys {
        case imageCarouselPosition
        case imageCarouselKey(key: String)

        var rawValue: String {
            switch self {
            case .imageCarouselPosition:
                return "imageCarouselPosition"
            case .imageCarouselKey(let key):
                return "DataImageCarousel.\(key)"
            }
        }
    }
    
    init(position: Int?, key: Keys) {
        self.position = position
        self.key = key.rawValue
    }
}

extension CustomStatePredicate {
    init(key: CustomStateIdentifiable.Keys, condition: OrderableWhenCondition, value: Int32) {
        self.init(key: key.rawValue, condition: condition, value: value)
    }
}
