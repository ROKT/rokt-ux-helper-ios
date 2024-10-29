//
//  BNFDataReflector.swift
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

/// Extracts nested property values from entity `Data` given a sequential chain of property keys in `keys`
protocol DataReflector {
    associatedtype U

    func getReflectedValue(data: Mirror, keys: [String]) -> U?
}

struct BNFDataReflector: DataReflector {
    func getReflectedValue(data: Mirror, keys: [String]) -> String? {
        guard let keyToCheck = keys.first else { return nil }

        var targetProperty: Any?

        for child in data.children {
            guard child.label == keyToCheck else { continue }

            if keys.count == 1 {
                targetProperty = child.value

                break
            } else if let valueDict = child.value as? [String: String] {
                // once we hit a dictionary, the assumption is that all remaining keys, EXCLUDING the current key, form a single key
                // we concatenate these using `.` and convert them to a single string

                let remainingKeys = Array(keys.dropFirst())
                let remainingKeysAsString = remainingKeys.joined(separator: BNFSeparator.namespace.rawValue)

                targetProperty = valueDict[remainingKeysAsString]

                break
            } else {
                // recursion to keep digging into nested properties
                let reflectedChildValue = Mirror(reflecting: child.value)
                let stepThroughKeyList = Array(keys.dropFirst())

                targetProperty = getReflectedValue(data: reflectedChildValue, keys: stepThroughKeyList)
            }
        }

        return targetProperty as? String
    }
}
