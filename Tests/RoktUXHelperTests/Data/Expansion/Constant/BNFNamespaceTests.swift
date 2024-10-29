//
//  BNFNamespaceTests.swift
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

final class BNFNamespaceTests: XCTestCase {
    func test_withNamespaceSeparator_returnsConcatenatedString() {
        let spaces: [BNFNamespace] = [.dataCreativeCopy, .dataCreativeResponse, .state]

        XCTAssertEqual(spaces[0].withNamespaceSeparator, "DATA.creativeCopy.")
        XCTAssertEqual(spaces[1].withNamespaceSeparator, "DATA.creativeResponse.")
        XCTAssertEqual(spaces[2].withNamespaceSeparator, "STATE.")
    }
}
