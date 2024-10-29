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
    let imageLoader: ImageLoader?
    
    private init(colorMode: ColorMode, imageLoader: ImageLoader?) {
        self.colorMode = colorMode
        self.imageLoader = imageLoader
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
        weak var imageLoader: ImageLoader?
        
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
        public func imageLoader(_ imageLoader: ImageLoader) -> Builder {
            self.imageLoader = imageLoader
            return self
        }
        
        /// Builds the `RoktUXConfig` instance with the specified settings.
        /// - Returns: A configured `RoktUXConfig` instance.
        public func build() -> RoktUXConfig {
            return RoktUXConfig(colorMode: colorMode ?? .system, imageLoader: imageLoader)
        }
    }
}
