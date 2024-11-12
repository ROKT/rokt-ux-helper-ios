//
//  Base64Image.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import Combine
import DcuiSchema

@available(iOS 15, *)
struct Base64Image: View {
    let scale: BackgroundImageScale?
    let altString: String
    let base64Image: UIImage

    var body: some View {
        Image(uiImage: base64Image)
            .scaleIfNeeded(scale: scale)
            .accessibilityLabel(altString)
            .accessibilityHidden(altString.isEmpty)
    }
}
