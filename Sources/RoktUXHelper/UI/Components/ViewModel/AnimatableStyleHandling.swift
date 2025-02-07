//
//  AnimatableStyleHandling.swift
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

@available(iOS 13.0, *)
protocol AnimatableStyleHandling: PredicateHandling, ObservableObject {
    var width: CGFloat { get set }

    var animate: Bool { get set }
    var cancellable: AnyCancellable? { get set }

    func subscribeToAnimation()
}

@available(iOS 13.0, *)
extension AnimatableStyleHandling {
    func subscribeToAnimation() {
        cancellable = layoutState?.itemsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] newCustomStateMap in
                guard let self else { return }
                animate = shouldApply(width)
            }
    }
}
