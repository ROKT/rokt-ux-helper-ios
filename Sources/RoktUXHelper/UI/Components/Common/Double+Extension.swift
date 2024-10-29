//
//  Double+Extension.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

extension Double {
    static func equal(_ lhs: Double, _ rhs: Double, precise value: Int? = nil) -> Bool {
        guard let value = value else { return lhs == rhs }
        return lhs.precised(value) == rhs.precised(value)
    }

    func precised(_ value: Int = 1) -> Double {
        let offset = pow(10, Double(value))
        return (self * offset).rounded() / offset
    }
}
