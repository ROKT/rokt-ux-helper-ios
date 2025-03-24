//
//  XCTestCase+Extension.swift
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

import Foundation
import XCTest

@available(iOS 15, *)

extension XCTestCase {
    func waitForViewController(
        _ jsonFilename: String,
        timeout: TimeInterval = 0.1,
        _ onComplete: ((UIViewController) -> Void)? = nil
    ) {
        // Create a RoktLayoutUIView
        let testViewController = TestViewController
            .createVC(ModelTestData.PageModelData.getJsonString(jsonFilename: jsonFilename))
        
        let expectation = XCTestExpectation(description: "Wait for SwiftUI rendering")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            onComplete?(testViewController)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 0.05)
    }
    
}
