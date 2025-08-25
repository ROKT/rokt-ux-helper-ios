//
//  CGRect+Extension.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI

@available(iOS 15, *)
extension CGRect {
    func intersectPercent(_ geoProxy: GeometryProxy) -> CGFloat {
        let geometrySpace = geoProxy.frame(in: .global)
        guard intersects(geometrySpace) else { return 0 }
        guard geometrySpace.width > 0 && geometrySpace.height > 0 else { return 0 }
        let intersection = intersection(geometrySpace)
        return (intersection.width * intersection.height)/(geometrySpace.width * geometrySpace.height)
    }

    func intersectPercentWithFrame(_ frame: CGRect) -> CGFloat {
        guard intersects(frame) else { return 0 }
        guard self.width > 0 && self.height > 0 else { return 0 }
        let intersection = intersection(frame)
        return (intersection.width * intersection.height)/(self.width * self.height)
    }
}
