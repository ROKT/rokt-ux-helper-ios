//
//  Image+Extension.swift
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

@available(iOS 15.0, *)
extension Image {
    func scaleIfNeeded(scale: BackgroundImageScale?) -> some View {
        switch scale {
        case .crop:
            return AnyView(self) // No resizing or scaling
        default:
            return AnyView(self
                .resizable()
                .aspectRatio(contentMode: scale?.getScale() ?? .fit))
        }
    }
}
