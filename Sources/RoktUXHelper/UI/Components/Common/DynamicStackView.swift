//
//  DynamicStackView.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct DynamicStackView<V: View>: View {
    enum Axis {
        case vertical(HorizontalAlignment)
        case horizontal(VerticalAlignment)
    }
    let axis: Axis
    let spacing: CGFloat
    var content: () -> V

    var body: some View {
        switch axis {
        case .vertical(let horizontalAlignment):
            VStack(
                alignment: horizontalAlignment,
                spacing: spacing
            ) {
                content()
            }
        case .horizontal(let verticalAlignment):
            HStack(
                alignment: verticalAlignment,
                spacing: spacing
            ) {
                content()
            }
        }
    }
}
