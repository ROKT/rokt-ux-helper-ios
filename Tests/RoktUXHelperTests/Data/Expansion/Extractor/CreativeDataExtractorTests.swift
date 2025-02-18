//
//  CreativeDataExtractorTests.swift
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
final class CreativeDataExtractorTests: XCTestCase {
    var offer: OfferModel!
    var sut: CreativeDataExtractor? = CreativeDataExtractor()

    override func setUp() {
        super.setUp()

        offer = ModelTestData.PageModelData.withBNF().layoutPlugins?.first!.slots[0].offer!
        sut = CreativeDataExtractor()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test_extractDataRepresentedBy_usingValidCreativeCopyPropertyChain_returnsNestedString() {
        XCTAssertNoThrow(try sut?.extractDataRepresentedBy(
            String.self,
            propertyChain: "DATA.creativeCopy.creative.termsAndConditions.link",
            responseKey: nil,
            from: offer
        ))
        XCTAssertEqual(
            try sut?.extractDataRepresentedBy(
                String.self,
                propertyChain: "DATA.creativeCopy.creative.termsAndConditions.link",
                responseKey: nil,
                from: offer
            ),
            .value("my_t_and_cs_link")
        )
    }

    func test_extractDataRepresentedBy_usingValidCreativeResponsePropertyChain_returnsNestedString() {
        XCTAssertNoThrow(try sut?.extractDataRepresentedBy(
            String.self,
            propertyChain: "DATA.creativeResponse.shortSuccessLabel",
            responseKey: "positive",
            from: offer
        ))
        XCTAssertEqual(
            try sut?.extractDataRepresentedBy(
                String.self,
                propertyChain: "DATA.creativeResponse.shortSuccessLabel",
                responseKey: "positive",
                from: offer
            ),
            .value("Short Success Label!")
        )
    }

    func test_extractDataRepresentedBy_usingInvalidPropertyChain_returnsNestedString() {
        XCTAssertNoThrow(try sut?.extractDataRepresentedBy(
            String.self,
            propertyChain: "DATA.creative.missingTestId",
            responseKey: nil,
            from: offer
        ))
        XCTAssertEqual(
            try sut?.extractDataRepresentedBy(
                String.self,
                propertyChain: "DATA.creative.missingTestId",
                responseKey: nil,
                from: offer
            ),
            .value("DATA.creative.missingTestId")
        )
    }

    func test_extractDataRepresentedBy_usingValidCreativeLinkPropertyChain_returnsNestedString() {
        XCTAssertNoThrow(
            try sut?.extractDataRepresentedBy(
                String.self,
                propertyChain: "DATA.creativeLink.privacyPolicy",
                responseKey: nil,
                from: offer
            )
        )
        XCTAssertEqual(
            try sut?.extractDataRepresentedBy(
                String.self,
                propertyChain: "DATA.creativeLink.privacyPolicy",
                responseKey: nil,
                from: offer
            ),
            .value("<a href=\"https://rokt.com\" target=\"_blank\">Privacy Policy Link</a>")
        )
    }
}
