//
//  BNFDataSanitiser.swift
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

protocol DataSanitiser {
    associatedtype T

    func sanitiseDelimiters(data: T) -> T
    func sanitiseNamespace(data: T, namespace: BNFNamespace) -> T
}

struct BNFDataSanitiser: DataSanitiser {
    func sanitiseDelimiters(data: String) -> String {
        data.replacingOccurrences(of: BNFSeparator.startDelimiter.rawValue, with: "")
            .replacingOccurrences(of: BNFSeparator.endDelimiter.rawValue, with: "")
    }

    func sanitiseNamespace(data: String, namespace: BNFNamespace) -> String {
        var inputData = data
        
        if data.contains(namespace.withNamespaceSeparator) {
            inputData = inputData.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        return inputData.replacingOccurrences(of: namespace.withNamespaceSeparator, with: "")
    }
}
