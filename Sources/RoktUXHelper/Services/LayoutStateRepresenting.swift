//
//  LayoutStateRepresenting.swift
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
import Combine

@available(iOS 13.0, *)
protocol LayoutStateRepresenting: Hashable, Equatable, AnyObject {
    var items: [String: Any] { get set }
    var itemsPublisher: CurrentValueSubject<[String: Any], Never> { get }
    var actionCollection: ActionCollecting { get set }
    var imageLoader: RoktUXImageLoader? { get }
    var colorMode: RoktUXConfig.ColorMode? { get }
    var config: RoktUXConfig? { get }
    var initialPluginViewState: RoktPluginViewState? { get }

    func setLayoutType(_ type: RoktUXPlacementLayoutCode)
    func layoutType() -> RoktUXPlacementLayoutCode
    func closeOnComplete() -> Bool
    func getGlobalBreakpointIndex(_ width: CGFloat?) -> Int
    func capturePluginViewState(offerIndex: Int?, dismiss: Bool?)
    func publishStateChange()
}
