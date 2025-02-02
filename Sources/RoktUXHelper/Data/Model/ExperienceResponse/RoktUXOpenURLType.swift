//
//  RoktUXOpenURLType.swift
//
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

/// This enum defines whether to open a URL using an internal browser or delegate the task to the device's external browser.
/// - `internally`: Opens the URL within the app's internal browser, typically for in-app web view use cases.
/// - `externally`: Opens the URL using the device's default external browser, like Safari or Chrome.
public enum RoktUXOpenURLType {
    case `internally`(sessionId: String?)
    case externally

    init(_ linkOpenTarget: LinkOpenTarget?, sessionId: String? = nil) {
        switch linkOpenTarget {
        case .externally,
             .passthrough:
            self = .externally
        default:
            self = .internally(sessionId: sessionId)
        }
    }
}
