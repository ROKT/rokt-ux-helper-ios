//
//  PlacementModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

public struct PageModel {
    public let pageId: String?
    public let sessionId: String
    public let pageInstanceGuid: String
    public let layoutPlugins: [LayoutPlugin]?
    var startDate: Date = Date()
    var responseReceivedDate: Date = Date()
    let token: String
    let options: [SDKOption]?
}

public struct LayoutPlugin {
    let pluginInstanceGuid: String
    let breakpoints: BreakPoint?
    let settings: LayoutSettings?
    let layout: LayoutSchemaModel?
    let slots: [SlotModel]
    let targetElementSelector: String?
    let pluginConfigJWTToken: String
    public let pluginId: String?
    let pluginName: String?
}

enum PlacementType: Codable, Hashable {
    case BottomSheet(BottomSheetType)
    case Overlay
    case unSupported
}

enum BottomSheetType: Codable, Hashable {
    case fixed
    case dynamic
}

public typealias BreakPoint = [String: Float]
