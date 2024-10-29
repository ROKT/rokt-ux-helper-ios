//
//  ThemeColor.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import DcuiSchema

@available(iOS 13, *)
extension ThemeColor {
    func getAdaptiveColor(_ colorScheme: ColorScheme) -> String {
        switch colorScheme {
        case .light:
            return light
        case .dark:
            // if phone is in darkmode and dark color is nil, return light as default
            return dark ?? light
        default:
            return light
        }
    }
}

@available(iOS 13, *)
extension UITraitCollection {
    static func getConfigColorSchema(colorMode: RoktUXConfig.ColorMode?) -> ColorScheme {
        switch colorMode {
        case .light:
            return .light
        case .dark:
            return .dark
        default:
            return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        }
    }
}
