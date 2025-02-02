//
//  RoktUIConfig.swift
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

/// Configuration class for Rokt UX.
public struct RoktUXConfig {
    /// The color mode for the UX.
    let colorMode: ColorMode
    /// Optional image loader for the UX.
    let imageLoader: RoktUXImageLoader?
    /// A Boolean value that determines whether debug logging is enabled.
    let loggingEnabled: Bool

    private init(
        colorMode: ColorMode,
        imageLoader: RoktUXImageLoader?,
        loggingEnabled: Bool
    ) {
        self.colorMode = colorMode
        self.imageLoader = imageLoader
        self.loggingEnabled = loggingEnabled
    }

    /// Enum representing the color modes available.
    public enum ColorMode: Int {
        /// Application is in Light Mode.
        case light
        /// Application is in Dark Mode.
        case dark
        /// Application defaults to System Color Mode.
        case system
    }

    /// Builder class for constructing `RoktUXConfig`
    public class Builder: NSObject {
        var colorMode: ColorMode?
        weak var imageLoader: RoktUXImageLoader?
        var loggingEnabled: Bool?

        /// Sets the color mode for the configuration.
        /// - Parameter colorMode: The color mode to be set.
        /// - Returns: The builder instance for chaining.
        public func colorMode(_ colorMode: ColorMode) -> Builder {
            self.colorMode = colorMode
            return self
        }

        /// Sets the image loader for the configuration.
        /// - Parameter imageLoader: The image loader to be set.
        /// - Returns: The builder instance for chaining.
        public func imageLoader(_ imageLoader: RoktUXImageLoader) -> Builder {
            self.imageLoader = imageLoader
            return self
        }

        /// Enables or disables debug logging for the RoktUXConfig.
        /// - Parameter enable: A Boolean value indicating whether debug logging should be enabled.
        /// - Returns: The Builder instance with the updated logging configuration.
        public func enableLogging(_ enable: Bool) -> Builder {
            self.loggingEnabled = enable
            return self
        }

        /// Builds the `RoktUXConfig` instance with the specified settings.
        /// - Returns: A configured `RoktUXConfig` instance.
        public func build() -> RoktUXConfig {
            RoktUXConfig(
                colorMode: colorMode ?? .system,
                imageLoader: imageLoader,
                loggingEnabled: loggingEnabled ?? false
            )
        }
    }
}

extension RoktUXConfig {
    func debugLog(_ message: String) {
        if loggingEnabled {
            debugPrint(message)
        }
    }
}
