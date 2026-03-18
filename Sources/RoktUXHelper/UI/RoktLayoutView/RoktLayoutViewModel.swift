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

        var optionalView: AnyView? {
            if case let .ready(view) = self { return view }
            return nil
        }

        var isContentVisible: Bool {
            if case .ready = self { return true }
            return false
        }
    }
    @Published var state: State = .empty
    /// Kept when transitioning to .empty so we don't tear down the view (avoids _AppearanceActionModifier / Binding teardown crash).
    @Published var lastViewForEmpty: AnyView?
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
        RoktUXLogger.shared.debug("Embedded view attached to the screen")
        let view = AnyView(injectedView())
        lastViewForEmpty = view
        state = .ready(view)
    }

    /// Closes the embedded view. Keeps lastViewForEmpty in the tree so the view is hidden, not torn down (avoids crash).
    public func closeEmbedded() {
        updateEmbeddedSize(0)
        state = .empty
        RoktUXLogger.shared.debug("User journey ended on Embedded view")
    }

    public func updateEmbeddedSize(_ size: CGFloat) {
        height = size
        RoktUXLogger.shared.debug("Embedded height resized to \(size)")
    }
}
