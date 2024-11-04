//
//  SDKOption.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

struct SDKOption: Decodable {

    enum Option: String, Decodable {
        case useDiagnosticEvents
    }

    let key: Option
    let value: Bool

    init?(element: Dictionary<String, Bool>.Element) {
        guard let key = Option(rawValue: element.key) else { return nil }
        self.key = key
        self.value = element.value
    }

    init(key: Option, value: Bool) {
        self.key = key
        self.value = value
    }
}

extension SDKOption {

    static var useDiagnosticEvents: SDKOption {
        .init(key: .useDiagnosticEvents, value: true)
    }
}

extension Sequence where Element == SDKOption {

    var useDiagnosticEvents: Bool {
        first(where: { $0.key == .useDiagnosticEvents })?.value == true
    }
}
