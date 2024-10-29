//
//  LayoutValidator.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
struct LayoutValidator {
    
    static func isValidColor(_ hexString: String) -> Bool {
        // ARGB (32-bit), RGB (24-bit), RGB (12-bit)
        let regex = "^#([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        return hexString.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
}
