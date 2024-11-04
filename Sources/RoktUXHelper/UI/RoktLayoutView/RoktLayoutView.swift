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
    @StateObject private var viewModel: RoktLayoutViewModel

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
        self._viewModel = .init(
            wrappedValue: RoktLayoutViewModel(
                experienceResponse: experienceResponse,
                location: location,
                config: config,
                onUXEvent: onUXEvent,
                onPlatformEvent: onPlatformEvent
            )
        )
    }

    public var body: some View {
        VStack {
            switch viewModel.state {
            case let .ready(view):
                view
            case .empty:
                EmptyView()
            }
        }
        .onAppear {
            viewModel.loadLayout()
        }
    }
}
