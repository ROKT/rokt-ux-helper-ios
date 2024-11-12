//
//  RoktLayout.swift
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

import UIKit
import SwiftUI

/// A UIView class for loading and displaying Rokt UX layouts.
/// The RoktLayoutUIView class provides multiple initialization options,
/// allowing for configuration flexibility. You can initialize it with an experienceResponse
/// and optional configuration parameters such as RoktUXConfig, ImageLoader, and event handlers.
@available(iOS 15, *)
@objc public class RoktLayoutUIView: UIView {
    private(set) var roktEmbeddedSwiftUIView: UIView?
    private var uxHelper: RoktUX?
    private var experienceResponse: String?
    private var location: String?
    private var config: RoktUXConfig?
    private var onUXEvent: ((RoktUXEvent) -> Void)?
    private var onPlatformEvent: (([String: Any]) -> Void)?
    private var onEmbeddedSizeChange: ((CGFloat) -> Void)?
    private var hasLoadedLayout = false
    private lazy var heightConstraint: NSLayoutConstraint = .init(item: self,
                                                                  attribute: .height,
                                                                  relatedBy: .equal,
                                                                  toItem: nil,
                                                                  attribute: .notAnAttribute,
                                                                  multiplier: 1,
                                                                  constant: 0)

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Initializes a new instance with the specified parameters.
    /// - Parameters:
    ///   - experienceResponse: The response string from the experience.
    ///   - location: The name of the layout element selector.
    ///   - config: Configuration for Rokt UX.
    ///   - onUXEvent: Closure to handle UX events.
    ///   - onPlatformEvent: Closure to handle platform events.
    ///   - onEmbeddedSizeChange: Closure to handle changes in embedded layout size.
    public init(experienceResponse: String,
                location: String,
                config: RoktUXConfig? = nil,
                onUXEvent: ((RoktUXEvent) -> Void)?,
                onPlatformEvent: (([String: Any]) -> Void)?,
                onEmbeddedSizeChange: ((CGFloat) -> Void)? = nil) {
        self.location = location
        self.experienceResponse = experienceResponse
        self.config = config
        self.onUXEvent = onUXEvent
        self.onPlatformEvent = onPlatformEvent
        self.onEmbeddedSizeChange = onEmbeddedSizeChange
        super.init(frame: .zero)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if let experienceResponse, !hasLoadedLayout {
            hasLoadedLayout = true
            loadLayout(
                experienceResponse: experienceResponse,
                location: location,
                config: config,
                onUXEvent: onUXEvent,
                onPlatformEvent: onPlatformEvent,
                onEmbeddedSizeChange: onEmbeddedSizeChange
            )
        }
    }

    /// Loads the layout with the specified parameters.
    /// - Parameters:
    ///   - experienceResponse: The response string from the experience.
    ///   - location: The name of the layout element selector.
    ///   - config: Configuration for Rokt UX.
    ///   - onUXEvent: Closure to handle UX events.
    ///   - onPlatformEvent: Closure to handle platform events.
    ///   - onEmbeddedSizeChange: Closure to handle changes in embedded layout size.
    public func loadLayout(experienceResponse: String,
                           location: String?,
                           config: RoktUXConfig? = nil,
                           onUXEvent: ((RoktUXEvent) -> Void)?,
                           onPlatformEvent: (([String: Any]) -> Void)?,
                           onEmbeddedSizeChange: ((CGFloat) -> Void)? = nil) {
        uxHelper = RoktUX()
        uxHelper?.loadLayout(
            experienceResponse: experienceResponse,
            layoutLoaders: [location ?? "": self],
            config: config,
            onRoktUXEvent: { event in onUXEvent?(event) },
            onRoktPlatformEvent: { platformEvent in onPlatformEvent?(platformEvent) },
            onEmbeddedSizeChange: { [weak self] location, size in
                if location == self?.location {
                    onEmbeddedSizeChange?(size)
                }
            }
        )
    }

    private func addEmbeddedLayoutConstraints(embeddedView: UIView) {
        NSLayoutConstraint.activate([
            embeddedView.topAnchor.constraint(equalTo: topAnchor),
            embeddedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            embeddedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            embeddedView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])
    }
}

@available(iOS 15, *)
extension RoktLayoutUIView: LayoutLoader {

    /// Loads the layout content with the specified parameters.
    /// - Parameters:
    ///   - onSizeChanged: Closure to handle size changes.
    ///   - injectedView: A closure returning the SwiftUI view to embed.
    public func load<Content>(onSizeChanged: @escaping ((CGFloat) -> Void),
                              injectedView: @escaping () -> Content) where Content: View {
        roktEmbeddedSwiftUIView?.removeFromSuperview()
        let vc = ResizableHostingController(rootView: AnyView(injectedView()))
        guard let swiftUIView = vc.view else { return }

        self.roktEmbeddedSwiftUIView = swiftUIView
        parentViewControllers?.addChild(vc)
        swiftUIView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(swiftUIView)
        addEmbeddedLayoutConstraints(embeddedView: swiftUIView)
        vc.didMove(toParent: parentViewControllers)
    }

    /// Updates the size of the embedded view.
    /// - Parameter size: The new height for the embedded view.
    public func updateEmbeddedSize(_ size: CGFloat) {
        if roktEmbeddedSwiftUIView != nil {
            heightConstraint.constant = size
        }
    }

    /// Closes the embedded view and notifies the size change.
    public func closeEmbedded() {
        // change the size to zero
        updateEmbeddedSize(0)
        // remove view from superView
        roktEmbeddedSwiftUIView?.removeFromSuperview()
        roktEmbeddedSwiftUIView = nil
        // notify the changes
        onEmbeddedSizeChange?(0)
    }
}
