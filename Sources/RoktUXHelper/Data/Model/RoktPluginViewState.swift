//
//  RoktPluginViewState.swift
//  Pods
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

@objc public class RoktPluginViewState: NSObject {
    public let pluginId: String
    public var offerIndex: Int?
    public var isPluginDismissed: Bool?
    public var customStateMap: RoktUXCustomStateMap?

    /// Shortcut initialiser that, when only given a pluginId, defaults to standard, initial plugin view states
    public convenience init(pluginId: String) {
        self.init(pluginId: pluginId,
                  offerIndex: 0,
                  isPluginDismissed: false,
                  customStateMap: nil)
    }

    public init(pluginId: String,
                offerIndex: Int? = nil,
                isPluginDismissed: Bool? = nil,
                customStateMap: RoktUXCustomStateMap? = nil) {
        self.pluginId = pluginId
        self.offerIndex = offerIndex
        self.isPluginDismissed = isPluginDismissed
        self.customStateMap = customStateMap
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? RoktPluginViewState else { return false }

        return (self.pluginId == rhs.pluginId &&
                self.offerIndex == rhs.offerIndex &&
                self.isPluginDismissed == rhs.isPluginDismissed &&
                self.customStateMap == rhs.customStateMap)
    }
}
