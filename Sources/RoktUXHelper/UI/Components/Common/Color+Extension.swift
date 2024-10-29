//
//  Color+Extension.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI

@available(iOS 15, *)
extension Color {
    init(hex: String?) {
        if let hex {
            self.init(uiColor: UIColor(hexString: hex))
        } else {
            self.init(.clear)
        }
    }
}
