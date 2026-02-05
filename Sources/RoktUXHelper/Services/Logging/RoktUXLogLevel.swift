//
//  RoktUXLogLevel.swift
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

/// Log levels for RoktUXHelper, ordered from most to least verbose.
///
/// Use these levels to control the verbosity of console logging output:
/// - `verbose`: Detailed diagnostic information for deep debugging
/// - `debug`: Development-time information like state changes
/// - `info`: General operational events
/// - `warning`: Recoverable issues that don't prevent operation
/// - `error`: Failures that prevent expected behavior
/// - `none`: No logging (default for production)
@objc public enum RoktUXLogLevel: Int, Comparable, Sendable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case none = 5

    public static func < (lhs: RoktUXLogLevel, rhs: RoktUXLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .none: return "NONE"
        }
    }
}
