//
//  ShadowModifier.swift
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
struct ShadowModifier: ViewModifier {
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    // needed by SwiftUI to prevent the shadows from bleeding into its content
    // this is because when `shadow` is applied to a parent (eg. column or row),
    // SwiftUI forces the children to inherit it
    var backgroundColor: ThemeColor?

    // borderRadius must be applied again here to avoid being drawn over
    var borderRadius: Float?

    var shadowOffsetX: Float?
    var shadowOffsetY: Float?
    var shadowColor: ThemeColor?
    var blurRadius: Float?

    var isContainer: Bool

    // only for components with children like Column
    private var backgroundBaseColor: Color {
        // a clear background color will not render any shadow
        guard isContainer else { return .clear }

        if let backgroundColor {
            return Color(hex: backgroundColor.getAdaptiveColor(colorScheme))
        } else {
            return .clear
        }
    }

    // only for components without children like BasicText
    private var viewShadowColor: Color {
        // a clear shadow color will not render
        guard !isContainer else { return .clear }

        return Color(hex: shadowColor?.getAdaptiveColor(colorScheme))
    }

    func body(content: Content) -> some View {
        content
            // container component shadow
            .background {
                backgroundBaseColor
                    .cornerRadius(CGFloat(borderRadius ?? 0))
                    .shadow(
                        color: Color(hex: shadowColor?.getAdaptiveColor(colorScheme)),
                        radius: CGFloat(blurRadius ?? 0),
                        x: CGFloat(shadowOffsetX ?? 0),
                        y: CGFloat(shadowOffsetY ?? 0)
                    )
            }
            // non-container component shadow
            .shadow(
                color: viewShadowColor,
                radius: CGFloat(blurRadius ?? 0),
                x: CGFloat(shadowOffsetX ?? 0),
                y: CGFloat(shadowOffsetY ?? 0)
            )
    }
}
