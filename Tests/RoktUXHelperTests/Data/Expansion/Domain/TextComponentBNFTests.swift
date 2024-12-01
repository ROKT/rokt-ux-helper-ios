//
//  TextComponentBNFTests.swift
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
final class TextComponentBNFTests: XCTestCase {
    func test_parsesCurrentAndTotalOffers() {
        let originalString = "Offer %^STATE.IndicatorPosition^% of %^STATE.TotalOffers^%"
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, "Offer 2 of 4")
    }
    
    func test_parsesCurrentAndTotalOffersWithNewNames() {
        let originalString = "Offer %^STATE.indicatorPosition^% of %^STATE.totalOffers^%"
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, "Offer 2 of 4")
    }

    func test_parsesAndRetainsTags() {
        let originalString = "Offer <b>%^STATE.IndicatorPosition^%</b> of <u>%^STATE.TotalOffers^%</u>"
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, "Offer <b>2</b> of <u>4</u>")
    }

    func test_multipleValidStates_returnsFirstMatch() {
        let originalString = "%^STATE.TotalOffers|STATE.IndicatorPosition^%"
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, "4")
    }

    func test_invalidStates_returnsEmptyString() {
        let originalString = "%^STATE.InvalidKey|^%"
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, "")
    }

    func test_invalidStates_usesDefaultValue() {
        let originalString = "%^STATE.InvalidKey|Default^%"
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, "Default")
    }

    func test_invalidStates_withIncompleteDelimiters_usesDefaultValueIncludingDelimiter() {
        let originalString = "%^STATE.SomeInvalidKey|^% %^STATE.SecondInvalidKey|^% SomeDefaultValue^%"
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")

        XCTAssertEqual(result, "  SomeDefaultValue^%")
    }

    func test_parsesSecondMatchTotalOffers() {
        let originalString = "%^STATE.InvalidKey1|STATE.IndicatorPosition^%/%^STATE.InvalidKey2|STATE.TotalOffers^%"
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, "2/4")
    }
    
    func test_nsattributedstring_parsesCurrentAndTotalOffers() {
        let originalString = NSAttributedString(string: "Offer %^STATE.IndicatorPosition^% of %^STATE.TotalOffers^%")
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, NSAttributedString(string: "Offer 2 of 4"))
    }
    
    func test_invalidStates_nsattributedstring_returnsEmptyString() {
        let originalString = NSAttributedString(string: "%^STATE.InvalidKey|^%")
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")
        
        XCTAssertEqual(result, NSAttributedString(string: ""))
    }
    
    func test_invalidStates_nsattributedstring_withIncompleteDelimiters_usesDefaultValueIncludingDelimiter() {
        let originalString =
            NSAttributedString(string: "%^STATE.SomeInvalidKey|^% %^STATE.SecondInvalidKey|^% SomeDefaultValue^%")
        let result = TextComponentBNFHelper.replaceStates(originalString, currentOffer: "2", totalOffers: "4")

        XCTAssertEqual(result, NSAttributedString(string: "  SomeDefaultValue^%"))
    }

}
