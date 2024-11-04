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

protocol LayoutStateRepresenting: Hashable, Equatable {
    var items: [String: Any] { get set }
    var actionCollection: ActionCollecting { get set }
    var imageLoader: ImageLoader? { get }
    var colorMode: RoktUXConfig.ColorMode? { get }
    var config: RoktUXConfig? { get }

    func setLayoutType(_ type: PlacementLayoutCode)
    func layoutType() -> PlacementLayoutCode
    func closeOnComplete() -> Bool
    func getGlobalBreakpointIndex(_ width: CGFloat?) -> Int
}
