//
//  LayoutState.swift
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
import SwiftUI
import DcuiSchema

@available(iOS 13.0, *)
class LayoutState: LayoutStateRepresenting {
    
    static let breakPointsSharedKey = "breakPoints"     // BreakPoint
    static let currentProgressKey = "currentProgress"   // Binding<Int>
    static let totalItemsKey = "totalItems"             // Int
    static let layoutType = "layoutCode"                // PlacementLayoutCode
    static let viewableItemsKey = "viewableItems"       // Binding<Int>
    static let layoutSettingsKey = "layoutSettings"     // LayoutSettings
    static let customStateMap = "customStateMap"        // CustomStateMap
    
    private var _items = [String: Any]()
    private let queue = DispatchQueue(label: kSharedDataItemsQueueLabel, attributes: .concurrent)
    let config: RoktUXConfig?
    
    var items: [String: Any] {
        get {
            queue.sync {
                return _items
            }
        }
        set {
            queue.async(flags: .barrier) {
                self._items = newValue
            }
        }
    }
    
    var actionCollection: ActionCollecting
    
    var colorMode: RoktUXConfig.ColorMode? {
        config?.colorMode
    }
    
    var imageLoader: (any ImageLoader)? {
        config?.imageLoader
    }
    
    init(actionCollection: ActionCollecting = ActionCollection(), config: RoktUXConfig? = nil) {
        self.actionCollection = actionCollection
        self.config = config
    }

    func setLayoutType(_ type: PlacementLayoutCode) {
        items[LayoutState.layoutType] = type
    }

    func layoutType() -> PlacementLayoutCode {
        (items[LayoutState.layoutType] as? PlacementLayoutCode) ?? .unknown
    }
    
    func closeOnComplete() -> Bool {
        guard let layoutSettings = items[LayoutState.layoutSettingsKey] as? LayoutSettings,
              let closeOnComplete = layoutSettings.closeOnComplete
        else {
            return true
        }
        return closeOnComplete
    }
    
    func getGlobalBreakpointIndex(_ width: CGFloat?) -> Int {
        guard let width,
              let globalBreakPoints = items[LayoutState.breakPointsSharedKey] as? BreakPoint,
              !globalBreakPoints.isEmpty
        else { return 0 }
        
        let sortedGlobalBreakPoints = globalBreakPoints.sorted { $0.1 < $1.1 }
        var index = 0
        for breakpoint in sortedGlobalBreakPoints {
            if CGFloat(breakpoint.value) > width {
                return index
            }
            index += 1
        }
        
        return index
    }
}
