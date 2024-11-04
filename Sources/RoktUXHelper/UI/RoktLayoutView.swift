//
//  RoktLayoutView.swift
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

import SwiftUI

/// A SwiftUI view for loading and displaying Rokt UX layouts.
/// The RoktLayoutView class provides multiple initialization options, allowing for configuration flexibility.
/// You can initialize it by passing required bindings and parameters like experienceResponse, optional config, ImageLoader, and event handlers.
@available(iOS 15, *)
public struct RoktLayoutView: View {
    private let experienceResponse: String
    private let location: String
    var config: RoktUXConfig?
    var onUXEvent: ((RoktUXEvent) -> Void)?
    var onPlatformEvent: (([String: Any]) -> Void)?
    private var uxHelper: RoktUX?

    @State private var injectedView: AnyView?
    @State private var layoutInitialized = false
    @State private var isVisible = true

    /// Initializes a new instance with the specified parameters.
    /// - Parameters:
    ///   - experienceResponse: The response string from the experience.
    ///   - location: The name of the layout element selector.
    ///   - config: Configuration for Rokt UX.
    ///   - onUXEvent: Closure to handle UX events.
    ///   - onPlatformEvent: Closure to handle platform events.
    public init(experienceResponse: String,
                location: String,
                config: RoktUXConfig? = nil,
                onUXEvent: ((RoktUXEvent) -> Void)?,
                onPlatformEvent: (([String: Any]) -> Void)?) {
        self.experienceResponse = experienceResponse
        self.location = location
        self.config = config
        self.onUXEvent = onUXEvent
        self.onPlatformEvent = onPlatformEvent
        self.uxHelper = RoktUX()
    }

    public var body: some View {
        VStack {
            if layoutInitialized && isVisible,
               let injectedView {
                injectedView
            }
        }
        .onAppear {
            loadLayout()
        }
    }

    private func loadLayout() {
        uxHelper?.loadLayout(experienceResponse: experienceResponse,
                             layoutLoaders: [location: self],
                             config: config,
                             onRoktUXEvent: { event in onUXEvent?(event) },
                             onRoktPlatformEvent: { platformEvent in onPlatformEvent?(platformEvent) },
                             onEmbeddedSizeChange: {_, _ in})
    }
}

@available(iOS 15, *)
extension RoktLayoutView: LayoutLoader {

    /// Loads the layout content with the specified view.
    /// Implementation of LayoutLoader.
    /// - Parameters:
    ///   - onSizeChanged: Closure to handle size changes.
    ///   - injectedView: A closure returning the SwiftUI view to embed.
    public func load<Content: View>(onSizeChanged: @escaping ((CGFloat) -> Void),
                                    @ViewBuilder injectedView: @escaping () -> Content) {
        self.injectedView = AnyView(injectedView())
        layoutInitialized = true
    }

    /// Closes the embedded view.
    public func closeEmbedded() {
        isVisible = false
    }

    public func updateEmbeddedSize(_ size: CGFloat) {}
}
