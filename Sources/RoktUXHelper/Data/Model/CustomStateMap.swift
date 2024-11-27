//
//  CustomStateMap.swift
//  
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

extension CustomStateMap {
    mutating func toggleValueFor(_ customStateId: Any?) -> CustomStateMap {
        guard let customStateId = customStateId as? CustomStateIdentifiable else {
            return self
        }
        // Toggle value between 0 and 1 (if nil, toggle on to 1)
        self.updateValue((self[customStateId] ?? 0 == 1) ? 0 : 1, forKey: customStateId)
        return self
    }
}

public typealias CustomStateMap = [CustomStateIdentifiable: Int]

public struct CustomStateIdentifiable: Hashable, Codable {
    let position: Int?
    let key: String
}
