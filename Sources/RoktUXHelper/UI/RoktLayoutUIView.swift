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
    var roktEmbeddedSwiftUIView: UIView?

    var topConstaint: NSLayoutConstraint?
    var leadingConstaint: NSLayoutConstraint?
    var trailingConstaint: NSLayoutConstraint?
    var heightConstaint: NSLayoutConstraint?
    // The default is -1 as 0 is a valid state. -1 means embedded view is not loaded correctly
    private var latestHeight: CGFloat = -1
    private var uxHelper: RoktUX?
    private var experienceResponse: String?
    private var location: String?
    private var config: RoktUXConfig?
    private var onUXEvent: ((RoktUXEvent) -> Void)?
    private var onPlatformEvent: (([String: Any]) -> Void)?
    private var onEmbeddedSizeChange: ((CGFloat) -> Void)?
    private var semaphore = DispatchSemaphore(value: 1)

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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if let experienceResponse, semaphore.wait(timeout: .now()) == .success {
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
            onEmbeddedSizeChange: { location, size in
                if location == self.location {
                    onEmbeddedSizeChange?(size)
                }
            }
        )
    }

    private func decideTranslatesAutoresizingMask() {
        // translateAutoresizingMaskIntoConstraints only when view doesn't have any constraints.
        if !self.constraints.isEmpty {
            self.translatesAutoresizingMaskIntoConstraints = false
        } else {
            self.translatesAutoresizingMaskIntoConstraints = true
        }
    }

    private func cleanupEmbeddedView() {
        subviews.forEach({ $0.removeFromSuperview() })
        removeEmbeddedLayoutConstraint(topConstaint)
        removeEmbeddedLayoutConstraint(leadingConstaint)
        removeEmbeddedLayoutConstraint(trailingConstaint)
        removeEmbeddedLayoutConstraint(heightConstaint)
    }

    private func addEmbeddedLayoutConstraints(embeddedView: UIView) {
        topConstaint = NSLayoutConstraint(item: self, attribute: .top,
                                          relatedBy: .equal, toItem: embeddedView,
                                          attribute: .top, multiplier: 1, constant: 0)
        leadingConstaint = NSLayoutConstraint(item: self, attribute: .leading,
                                              relatedBy: .equal, toItem: embeddedView,
                                              attribute: .leading, multiplier: 1, constant: 0)
        trailingConstaint = NSLayoutConstraint(item: self, attribute: .trailing,
                                               relatedBy: .equal, toItem: embeddedView,
                                               attribute: .trailing, multiplier: 1, constant: 0)
        heightConstaint = NSLayoutConstraint(item: self, attribute: .height,
                                             relatedBy: .equal, toItem: nil,
                                             attribute: .notAnAttribute, multiplier: 1, constant: 0)
        addEmbeddedLayoutConstraint(topConstaint)
        addEmbeddedLayoutConstraint(leadingConstaint)
        addEmbeddedLayoutConstraint(trailingConstaint)
        addEmbeddedLayoutConstraint(heightConstaint)
    }

    private func addEmbeddedLayoutConstraint(_ layoutConstraint: NSLayoutConstraint?) {
        if let layoutConstraint {
            self.addConstraint(layoutConstraint)
        }
    }

    private func removeEmbeddedLayoutConstraint(_ layoutConstraint: NSLayoutConstraint?) {
        if let layoutConstraint {
            self.removeConstraint(layoutConstraint)
        }
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
        cleanupEmbeddedView()

        let vc = ResizableHostingController(rootView: AnyView(injectedView()))
        let swiftuiView = vc.view!
        self.roktEmbeddedSwiftUIView = swiftuiView

        parentViewControllers?.addChild(vc)
        swiftuiView.translatesAutoresizingMaskIntoConstraints = false

        decideTranslatesAutoresizingMask()

        addSubview(swiftuiView)

        self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: self.frame.width, height: 0)

        addEmbeddedLayoutConstraints(embeddedView: swiftuiView)

        vc.didMove(toParent: parentViewControllers)
    }

    /// Updates the size of the embedded view.
    /// - Parameter size: The new height for the embedded view.
    public func updateEmbeddedSize(_ size: CGFloat) {
        if roktEmbeddedSwiftUIView != nil {
            for cons in self.constraints where cons.firstAttribute == NSLayoutConstraint.Attribute.height {
                cons.constant = size
                cons.isActive = true
            }
            self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: self.frame.width, height: size)
            roktEmbeddedSwiftUIView?.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: size)
            latestHeight = size
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
