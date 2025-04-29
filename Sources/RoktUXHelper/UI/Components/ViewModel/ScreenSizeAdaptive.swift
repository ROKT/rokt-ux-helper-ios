//
//  ScreenSizeAdaptive.swift
//
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

@available(iOS 13.0, *)
protocol ScreenSizeAdaptive {

    associatedtype Item

    var defaultStyle: [Item]? { get }
    var layoutState: (any LayoutStateRepresenting)? { get }

    func updateBreakpointIndex(for newSize: CGFloat?) -> Int
}

@available(iOS 13.0, *)
extension ScreenSizeAdaptive {

    func updateBreakpointIndex(for newSize: CGFloat?) -> Int {
        let index = min(
            layoutState?.getGlobalBreakpointIndex(newSize) ?? 0,
            (defaultStyle?.count ?? 1) - 1
        )
        return index >= 0 ? index : 0
    }
}

@available(iOS 13.0, *)
protocol BaseStyleAdaptive: ScreenSizeAdaptive where Item == BaseStyles {
    var stylingProperties: [BasicStateStylingBlock<Item>]? { get }
    var defaultStyle: [Item]? { get }
}

@available(iOS 13.0, *)
extension BaseStyleAdaptive {

    var defaultStyle: [Item]? {
        stylingProperties?.map(\.default)
    }
}
