//
//  DataExtracting.swift
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

protocol DataExtracting {
    associatedtype MappingSource: DomainMappingSource

    func extractDataRepresentedBy<T>(
        _ type: T.Type,
        propertyChain: String,
        responseKey: String?,
        from data: MappingSource?
    ) throws -> DataBinding<T>
}

enum DataBinding<T>: Hashable where T: Hashable {
    case value(T)
    case state(T)
}

enum DataBindingStateKeys {
    static let indicatorPosition = "IndicatorPosition"
    static let totalOffers = "TotalOffers"

    static func isIndicatorPosition(_ key: String) -> Bool {
        key.caseInsensitiveCompare(DataBindingStateKeys.indicatorPosition) == .orderedSame
    }

    static func isTotalOffers(_ key: String) -> Bool {
        key.caseInsensitiveCompare(DataBindingStateKeys.totalOffers) == .orderedSame
    }

    static func isValidKey(_ key: String) -> Bool {
        isIndicatorPosition(key) || isTotalOffers(key)
    }
}
