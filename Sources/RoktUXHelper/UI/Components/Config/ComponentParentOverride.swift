//
//  ComponentParentOverride.swift
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
struct ComponentParentOverride {
    let parentVerticalAlignment: VerticalAlignment?
    let parentHorizontalAlignment: HorizontalAlignment?
    let parentBackgroundStyle: BackgroundStylingProperties?
    let stretchChildren: Bool?

    func updateBackground(_ backgroundStyle: BackgroundStylingProperties?) -> ComponentParentOverride {
        return ComponentParentOverride(parentVerticalAlignment: parentVerticalAlignment,
                                       parentHorizontalAlignment: parentHorizontalAlignment,
                                       parentBackgroundStyle: backgroundStyle,
                                       stretchChildren: stretchChildren)
    }
}
