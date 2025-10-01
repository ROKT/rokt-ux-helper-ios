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
import Combine

@available(iOS 13.0, *)
class LayoutState: LayoutStateRepresenting {

    static let breakPointsSharedKey = "breakPoints" // BreakPoint
    static let currentProgressKey = "currentProgress" // Binding<Int>
    static let totalItemsKey = "totalItems" // Int
    static let layoutType = "layoutCode" // PlacementLayoutCode
    static let viewableItemsKey = "viewableItems" // Binding<Int>
    static let layoutSettingsKey = "layoutSettings" // LayoutSettings
    static let customStateMap = "customStateMap" // CustomStateMap
    static let activeCatalogItemKey = "activeCatalogItem" // CatalogItem
    static let fullOfferKey = "fullOffer" // OfferModel

    private var _items = [String: Any]()
    private(set) var itemsPublisher: CurrentValueSubject<[String: Any], Never> = .init([:])
    private let queue = DispatchQueue(label: kSharedDataItemsQueueLabel, attributes: .concurrent)
    let config: RoktUXConfig?

    var items: [String: Any] {
        get {
            queue.sync {
                return _items
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                guard let self else { return }
                self._items = newValue
                self.itemsPublisher.send(newValue)
            }
        }
    }

    var actionCollection: ActionCollecting

    var colorMode: RoktUXConfig.ColorMode? {
        config?.colorMode
    }

    var imageLoader: (any RoktUXImageLoader)? {
        config?.imageLoader
    }

    public let initialPluginViewState: RoktPluginViewState?
    private let pluginId: String?
    private let onPluginViewStateChange: ((RoktPluginViewState) -> Void)?

    init(actionCollection: ActionCollecting = ActionCollection(),
         config: RoktUXConfig? = nil,
         pluginId: String? = nil,
         initialPluginViewState: RoktPluginViewState? = nil,
         onPluginViewStateChange: ((RoktPluginViewState) -> Void)? = nil) {
        self.actionCollection = actionCollection
        self.config = config
        self.pluginId = pluginId
        self.initialPluginViewState = initialPluginViewState
        self.onPluginViewStateChange = onPluginViewStateChange
    }

    func capturePluginViewState(offerIndex: Int?, dismiss: Bool?) {
        guard let pluginId else { return }
        let currentProgress: Binding<Int>? = items[LayoutState.currentProgressKey] as? Binding<Int>
        let customStateMap: Binding<RoktUXCustomStateMap?>? = items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?>
        onPluginViewStateChange?(RoktPluginViewState(pluginId: pluginId,
                                                     offerIndex: offerIndex ?? currentProgress?.wrappedValue,
                                                     isPluginDismissed: dismiss,
                                                     customStateMap: customStateMap?.wrappedValue))
    }

    func setLayoutType(_ type: RoktUXPlacementLayoutCode) {
        items[LayoutState.layoutType] = type
    }

    func layoutType() -> RoktUXPlacementLayoutCode {
        (items[LayoutState.layoutType] as? RoktUXPlacementLayoutCode) ?? .unknown
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

    func publishStateChange() {
        itemsPublisher.send(items)
    }
}
