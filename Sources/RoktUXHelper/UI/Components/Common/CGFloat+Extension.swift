//
//  CGFloat+extension.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

extension CGFloat {
    func precised(_ value: Int = 2) -> CGFloat {
        (self * pow(10.0, CGFloat(value))).rounded()/pow(10.0, CGFloat(value))
    }
}
