//
//  MarginModifier.swift
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

@available(iOS 15, *)
struct MarginModifier: ViewModifier, SpacingStyleable {
    let spacing: SpacingStylingProperties?
    let applyMargin: Bool

    func body(content: Content) -> some View {
        let frame = applyMargin ? getMargin() : FrameAlignmentProperty.zeroDimension
        content.padding(frame: frame)
    }

}
