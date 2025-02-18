//
//  CatalogStackedCollection.swift
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

@available(iOS 15, *)
class CatalogStackedCollectionViewModel: Identifiable, Hashable, ScreenSizeAdaptive {

    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]
    let defaultStyle: [CatalogStackedCollectionStyles]?
    weak var layoutState: (any LayoutStateRepresenting)?

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }
    init(
        children: [LayoutSchemaViewModel]?,
        defaultStyle: [CatalogStackedCollectionStyles]?,
        layoutState: any LayoutStateRepresenting
    ) {
        self.children = children ?? []
        self.defaultStyle = defaultStyle
        self.layoutState = layoutState
    }
}
