//
//  BNFCatalogDataExtractorTests.swift
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

import XCTest
@testable import RoktUXHelper

@available(iOS 13, *)
final class BNFCatalogDataExtractorTests: XCTestCase {
    var catalogItem: CatalogItem!
    var sut: BNFCatalogDataExtractor? = BNFCatalogDataExtractor()

    override func setUp() {
        super.setUp()

        catalogItem = ModelTestData.CatalogPageModelData.withBNF().layoutPlugins?.first!.slots[0].offer!.catalogItems?.first
        sut = BNFCatalogDataExtractor()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test_extractDataRepresentedBy_usingValidCreativeCopyPropertyChain_returnsNestedString() {
        XCTAssertEqual(
            try sut?.extractDataRepresentedBy(String.self, propertyChain: "DATA.catalogItem.title", responseKey: nil, from: catalogItem),
            .value("Catalog Title")
        )
    }

    func test_extractDataRepresentedBy_usingValidCreativeResponsePropertyChain_returnsNestedString() {
        XCTAssertEqual(
            try sut?.extractDataRepresentedBy(String.self, propertyChain: "DATA.catalogItem.description", responseKey: nil, from: catalogItem),
            .value("Catalog Description")
        )
    }

    func test_extractDataRepresentedBy_usingInvalidPropertyChain_returnsNestedString() {
        XCTAssertEqual(
            try sut?.extractDataRepresentedBy(String.self, propertyChain: "DATA.catalog.missingTestId", responseKey: nil, from: catalogItem),
            .value("DATA.catalog.missingTestId")
        )
    }

    func test_extractDataRepresentedBy_usingValidCreativeLinkPropertyChain_returnsNestedString() {
        XCTAssertEqual(
            try sut?.extractDataRepresentedBy(String.self, propertyChain: "DATA.catalogItem.originalPriceFormatted", responseKey: nil, from: catalogItem),
            .value("$14.99")
        )
    }
}
