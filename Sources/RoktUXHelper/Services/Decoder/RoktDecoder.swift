//
//  RoktDecoder.swift
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
struct RoktDecoder {
    
    func decode<T: Decodable>(_ type: T.Type, _ string: String) throws -> T {
        try string.data(using: .utf8)
            .flatMap {
                try JSONDecoder().decode(type, from: $0)
            }
            .unwrap(orThrow: RoktUXError.experienceResponseMapping)
    }
}
