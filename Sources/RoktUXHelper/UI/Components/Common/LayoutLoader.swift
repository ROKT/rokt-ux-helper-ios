//
//  LayoutLoader.swift
//  RoktUXHelper
//
//  Copyright 2020 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import SwiftUI

/// A type with methods for loading and updating embedded layouts.
@available(iOS 15.0, *)
public protocol LayoutLoader {

    /// Loads the layout content with the specified view.
    /// - Parameters:
    ///   - onSizeChanged: Closure to handle size changes.
    ///   - injectedView: A closure returning the SwiftUI view to embed.
    func load<Content: View>(
        onSizeChanged: @escaping ((CGFloat) -> Void),
        @ViewBuilder injectedView: @escaping () -> Content
    )

    /// Updates the size of the embedded view.
    /// - Parameter size: The new height for the embedded view.
    func updateEmbeddedSize(_ size: CGFloat)

    /// Closes the embedded view.
    func closeEmbedded()
}
