//
//  AnimationStyle.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema
import Combine
import SwiftUI

struct AnimationStyle {
    var duration: TimeInterval
    var style: BaseStyles
}

extension AnimationStyle {

    init?<S, P>(
        transition: ConditionalStyleTransition<S, P>?,
        transform: (S) -> BaseStyles?
    ) {
        guard let transition, let style = transform(transition.value) else { return nil }
        self.duration = Double(transition.duration)/1000.0
        self.style = style
    }
}
