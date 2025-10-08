//
//  CatalogCombinedCollectionViewModel.swift
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
class CatalogCombinedCollectionViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    typealias Item = CatalogCombinedCollectionStyles

    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let defaultStyle: [CatalogCombinedCollectionStyles]?
    weak var layoutState: (any LayoutStateRepresenting)?
    private let childBuilder: ((CatalogItem) -> [LayoutSchemaViewModel]?)?

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }
    init(
        children: [LayoutSchemaViewModel]?,
        defaultStyle: [CatalogCombinedCollectionStyles]?,
        layoutState: any LayoutStateRepresenting,
        childBuilder: ((CatalogItem) -> [LayoutSchemaViewModel]?)? = nil
    ) {
        self.children = children
        self.defaultStyle = defaultStyle
        self.layoutState = layoutState
        self.childBuilder = childBuilder
    }

    @discardableResult
    func rebuildChildren(for catalogItem: CatalogItem) -> Bool {
        guard let newChildren = childBuilder?(catalogItem) else { return false }
        children = newChildren
        return true
    }

    static func == (lhs: CatalogCombinedCollectionViewModel, rhs: CatalogCombinedCollectionViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
