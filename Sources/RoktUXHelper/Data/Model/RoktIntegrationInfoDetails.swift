//
//  SDKConfig.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import UIKit

private enum Constants {
    static let framework: String = "Swift"
    static let kBundleShort: String = "CFBundleShortVersionString"
    static let layoutSchemaVersion: String = "2.4.0"
    static let name: String = "UX Helper iOS"
    static let platform: String = "iOS"
    static let version: String = "0.1.0"
}

public struct RoktIntegrationInfo: Encodable {
    static var shared: RoktIntegrationInfo = .init(integration: .init())

    public let integration: RoktIntegrationInfoDetails

    /// Method to convert SDK info to a JSON string
    public var jsonString: String {
        guard let jsonData = try? JSONEncoder().encode(self),
              let string = String(data: jsonData, encoding: .utf8) else { return "" }
        return string
    }

    /// Method to convert SDK info to a JSON dictionary
    public var json: [String: Any] {
        (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}

public struct RoktIntegrationInfoDetails: Codable {
    let deviceType: String
    let deviceModel: String
    let deviceLocale: String
    let framework: String
    let layoutSchemaVersion: String
    let name: String
    let version: String
    let operatingSystem: String
    let operatingSystemVersion: String
    let packageVersion: String?
    let packageName: String?
    let platform: String

    init(
        deviceType: String = UIDevice.current.userInterfaceIdiom.string,
        deviceModel: String = UIDevice.modelName,
        deviceLocale: String = Locale.current.identifier,
        framework: String = Constants.framework,
        layoutSchemaVersion: String = Constants.layoutSchemaVersion,
        name: String = Constants.name,
        operatingSystem: String = UIDevice.current.systemName,
        operatingSystemVersion: String = UIDevice.current.systemVersion,
        platform: String = UIDevice.current.systemName,
        packageVersion: String? = Bundle.main.infoDictionary?[Constants.kBundleShort] as? String,
        packageName: String? = Bundle.main.bundleIdentifier,
        version: String = Constants.version
    ) {
        self.deviceType = deviceType
        self.deviceModel = deviceModel
        self.deviceLocale = deviceLocale
        self.framework = framework
        self.layoutSchemaVersion = layoutSchemaVersion
        self.name = name
        self.operatingSystem = operatingSystem
        self.operatingSystemVersion = operatingSystemVersion
        self.platform = platform
        self.packageVersion = packageVersion
        self.packageName = packageName
        self.version = version
    }
}

private extension UIUserInterfaceIdiom {
    var string: String {
        switch self {
        case .unspecified:
            "unspecified"
        case .phone:
            "Phone"
        case .pad:
            "Tablet"
        case .tv:
            "TV"
        case .carPlay:
            "CarPlay"
        case .mac:
            "Mac"
        case .vision:
            "Vision"
        @unknown default:
            "unknown"
        }
    }
}
