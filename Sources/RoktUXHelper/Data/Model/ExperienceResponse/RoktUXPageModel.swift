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

public struct RoktUXPageModel {
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
    public let pluginId: String
    let pluginName: String?
}

enum PlacementType: Codable, Hashable {
    case BottomSheet(BottomSheetType)
    case Overlay
    case unSupported
}

/// Defines the behavior type for bottom sheet components
///
/// This enum specifies how a bottom sheet should behave in terms of its height and resizing capabilities.
/// The type determines whether the bottom sheet maintains a fixed height or allows dynamic resizing.
enum BottomSheetType: Codable, Hashable {
    /// A bottom sheet with a fixed, predetermined height.
    ///
    /// The sheet will be sized based on it's content.
    case fixed

    /// A bottom sheet that can dynamically resize e.g. stretch.
    ///
    /// Dynamic requires iOS 16 due to the usage of [custom detents](https://developer.apple.com/documentation/swiftui/custompresentationdetent)
    ///
    /// This type allows the sheet to expand or contract vertically to fit its content.
    /// Users can typically resize the sheet by dragging its edges or through other
    /// interactive controls.
    case dynamic
}

public typealias BreakPoint = [String: Float]
