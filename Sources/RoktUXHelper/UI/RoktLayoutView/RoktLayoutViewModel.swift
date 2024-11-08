//
//  RoktLayoutViewModel.swift
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

@available(iOS 15, *)
class RoktLayoutViewModel: ObservableObject, LayoutLoader {

    enum State {
        case ready(AnyView)
        case empty
    }
    @Published var state: State = .empty
    @Published var height: CGFloat = 0
    private let experienceResponse: String
    private let location: String
    private let config: RoktUXConfig?
    private var onUXEvent: ((RoktUXEvent) -> Void)?
    private var onPlatformEvent: (([String: Any]) -> Void)?
    private var uxHelper: RoktUX = RoktUX()

    init(experienceResponse: String,
         location: String,
         config: RoktUXConfig?,
         onUXEvent: ((RoktUXEvent) -> Void)? = nil,
         onPlatformEvent: (([String: Any]) -> Void)? = nil) {
        self.experienceResponse = experienceResponse
        self.location = location
        self.config = config
        self.onUXEvent = onUXEvent
        self.onPlatformEvent = onPlatformEvent
    }

    func loadLayout() {
        uxHelper.loadLayout(experienceResponse: experienceResponse,
                            layoutLoaders: [location: self],
                            config: config,
                            onRoktUXEvent: { [weak self] event in self?.onUXEvent?(event) },
                            onRoktPlatformEvent: { [weak self] platformEvent in self?.onPlatformEvent?(platformEvent) },
                            onEmbeddedSizeChange: { _, _ in })
    }
}

@available(iOS 15, *)
extension RoktLayoutViewModel: LayoutLoader {

    /// Loads the layout content with the specified view.
    /// Implementation of LayoutLoader.
    /// - Parameters:
    ///   - onSizeChanged: Closure to handle size changes.
    ///   - injectedView: A closure returning the SwiftUI view to embed.
    public func load<Content: View>(onSizeChanged: @escaping ((CGFloat) -> Void),
                                    @ViewBuilder injectedView: @escaping () -> Content) {
        state = .ready(AnyView(injectedView()))
    }

    /// Closes the embedded view.
    public func closeEmbedded() {
        state = .empty
    }

    public func updateEmbeddedSize(_ size: CGFloat) {
        height = size
    }
}
