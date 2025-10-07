//
//  CatalogCombinedCollectionViewModelTests.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
@testable import RoktUXHelper

@available(iOS 15, *)
final class CatalogCombinedCollectionViewModelTests: XCTestCase {

    func test_rebuildChildren_usesBuilderResult() {
        let layoutState = MockLayoutState()
        let firstItem = makeCatalogItem(id: "first")
        let secondItem = makeCatalogItem(id: "second")

        var capturedIdentifiers: [String] = []
        let builder: (CatalogItem) -> [LayoutSchemaViewModel]? = { item in
            capturedIdentifiers.append(item.catalogItemId)
            return [.empty]
        }

        let sut = CatalogCombinedCollectionViewModel(
            children: [],
            defaultStyle: nil,
            layoutState: layoutState,
            childBuilder: builder
        )

        XCTAssertTrue(sut.rebuildChildren(for: firstItem))
        XCTAssertEqual(capturedIdentifiers, ["first"])
        XCTAssertEqual(sut.children, [.empty])

        XCTAssertTrue(sut.rebuildChildren(for: secondItem))
        XCTAssertEqual(capturedIdentifiers, ["first", "second"])
        XCTAssertEqual(sut.children, [.empty])
    }

    func test_rebuildChildren_returnsFalseWhenBuilderReturnsNil() {
        let layoutState = MockLayoutState()
        let catalogItem = makeCatalogItem(id: "test")
        
        let builder: (CatalogItem) -> [LayoutSchemaViewModel]? = { _ in nil }
        
        let sut = CatalogCombinedCollectionViewModel(
            children: [.empty],
            defaultStyle: nil,
            layoutState: layoutState,
            childBuilder: builder
        )
        
        XCTAssertFalse(sut.rebuildChildren(for: catalogItem))
        XCTAssertEqual(sut.children, [.empty]) // Should remain unchanged
    }

    func test_rebuildChildren_returnsFalseWhenBuilderIsNil() {
        let layoutState = MockLayoutState()
        let catalogItem = makeCatalogItem(id: "test")
        
        let sut = CatalogCombinedCollectionViewModel(
            children: [.empty],
            defaultStyle: nil,
            layoutState: layoutState,
            childBuilder: nil
        )
        
        XCTAssertFalse(sut.rebuildChildren(for: catalogItem))
    }

    func test_imageLoader_returnsLayoutStateImageLoader() {
        let mockLayoutState = MockLayoutState()
        let mockImageLoader = MockImageLoader()
        mockLayoutState.imageLoader = mockImageLoader
        
        let sut = CatalogCombinedCollectionViewModel(
            children: nil,
            defaultStyle: nil,
            layoutState: mockLayoutState
        )
        
        XCTAssertIdentical(sut.imageLoader as AnyObject?, mockImageLoader as AnyObject?)
    }

    private func makeCatalogItem(id: String) -> CatalogItem {
        CatalogItem(
            images: [:],
            catalogItemId: id,
            cartItemId: "cart-\(id)",
            instanceGuid: "instance-\(id)",
            title: "title-\(id)",
            description: "description-\(id)",
            price: nil,
            priceFormatted: nil,
            originalPrice: nil,
            originalPriceFormatted: nil,
            currency: "USD",
            signalType: nil,
            url: nil,
            minItemCount: nil,
            maxItemCount: nil,
            preSelectedQuantity: nil,
            providerData: "provider-\(id)",
            urlBehavior: nil,
            positiveResponseText: "positive",
            negativeResponseText: "negative",
            addOns: nil,
            copy: nil,
            linkedProductId: nil,
            token: "token-\(id)"
        )
    }
}
