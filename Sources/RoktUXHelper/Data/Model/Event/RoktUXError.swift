//
//  RoktUXHError.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

public enum RoktUXError: Error {
    case experienceResponseMapping
    case imageLoading(reason: String)
    case loadLayoutGeneric(sessionId: String)
    case loadLayoutEmpty(sessionId: String)
    case layoutTransform(pluginId: String?, sessionId: String)
    case unknown
}
