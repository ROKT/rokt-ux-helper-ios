//
//  BNFPayloadExpanderTests.swift
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

@available(iOS 15, *)
final class BNFPayloadExpanderTests: XCTestCase {
    var sut: BNFPayloadExpander? = BNFPayloadExpander()

    override func setUp() {
        super.setUp()

        sut = BNFPayloadExpander()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test_expand_withValidBNF_updatesNestedValues() throws {
        let bnfPageModel = ModelTestData.PageModelData.withBNF()

        let layoutTransformer = LayoutTransformer(layoutPlugin: (bnfPageModel.layoutPlugins?.first!)!)

        let firstSlot = bnfPageModel.layoutPlugins?.first?.slots[0]
        guard let innerLayout = firstSlot?.layoutVariant?.layoutVariantSchema else {
            XCTFail("inner layout does not exist")
            return
        }

        let transformedUIModel = try layoutTransformer.transform(innerLayout, context: .outer([]))

        sut?.expand(
            layoutVariant: transformedUIModel,
            parent: nil,
            creativeParent: nil,
            using: firstSlot?.offer,
            dataSourceIndex: 0,
            usesDataSourceIndex: true
        )

        if case .column(let bnfColumn) = transformedUIModel,
           case .basicText(let textModel) = bnfColumn.children?[0] {
            XCTAssertEqual(textModel.boundValue, "my_t_and_cs_link ")
        } else {
            XCTFail("Could not parse BNF layouts test data")
        }

        // chain of offer descriptions
        if case .column(let bnfColumn) = transformedUIModel,
           case .richText(let textModel) = bnfColumn.children?[1] {
            XCTAssertEqual(textModel.boundValue, "My Offer TitleOffer description goes heremy_t_and_cs_link")
        } else {
            XCTFail("Could not parse BNF layouts test data")
        }
    }
}
