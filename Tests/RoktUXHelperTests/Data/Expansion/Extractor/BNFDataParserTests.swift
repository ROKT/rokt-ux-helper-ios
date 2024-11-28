//
//  BNFDataParserTests.swift
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

final class BNFDataParserTests: XCTestCase {
    var sut: PropertyChainDataParser!

    override func setUp() {
        super.setUp()

        sut = BNFPropertyChainDataParser()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test_parse_withValidCreativeCopyPropertyChain_returnsCompleteBNFPlaceholder() {
        XCTAssertEqual(

            sut.parse(propertyChain: "%^DATA.creativeCopy.owner.pet.name|Spotty^%"),
            BNFPlaceholder(parseableChains: [BNFKeyAndNamespace(key: "owner.pet.name", namespace: .dataCreativeCopy)],
                           defaultValue: "Spotty")
        )
    }

    func test_parse_withValidCreativeResponsePropertyChain_returnsCompleteBNFPlaceholder() {
        XCTAssertEqual(
            sut.parse(propertyChain: "%^DATA.creativeResponse.owner.pet.name|Spotty^%"),
            BNFPlaceholder(parseableChains: [BNFKeyAndNamespace(key: "owner.pet.name", namespace: .dataCreativeResponse)],
                           defaultValue: "Spotty")
        )
    }

    func test_parse_withoutNamespaceInPropertyChain_returnsEmptyParseableChainsInBNFPlaceholder() {
        XCTAssertEqual(
            sut.parse(propertyChain: "%^house.owner.pet.name|Spotty^%"),
            BNFPlaceholder(parseableChains: [],
                           defaultValue: "Spotty")
        )
    }

    func test_parse_withoutDefaultValueInPropertyChain_returnsNilDefaultValueInBNFPlaceholder() {
        XCTAssertEqual(
            sut.parse(propertyChain: "%^DATA.creativeCopy.owner.pet.name^%"),
            BNFPlaceholder(
                parseableChains: [BNFKeyAndNamespace(key: "owner.pet.name", namespace: .dataCreativeCopy, isMandatory: true)],
                defaultValue: nil
            )
        )
    }
}
