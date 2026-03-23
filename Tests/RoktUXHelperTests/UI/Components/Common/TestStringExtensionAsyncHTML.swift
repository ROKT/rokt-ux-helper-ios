//
//  TestStringExtensionAsyncHTML.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
import SwiftUI
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestStringExtensionAsyncHTML: XCTestCase {

    // MARK: - Sync overload (existing behavior preserved)

    func test_sync_htmlToAttributedString_plain_text() throws {
        let result = try "Hello World".htmlToAttributedString(
            textColorHex: nil,
            uiFont: nil,
            linkStyles: nil,
            colorScheme: .light
        )
        XCTAssertTrue(result.string.contains("Hello World"))
    }

    func test_sync_htmlToAttributedString_bold_html() throws {
        let result = try "<b>Bold</b>".htmlToAttributedString(
            textColorHex: nil,
            uiFont: UIFont.systemFont(ofSize: 14),
            linkStyles: nil,
            colorScheme: .light
        )
        XCTAssertTrue(result.string.contains("Bold"))

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
    }

    func test_sync_htmlToAttributedString_with_font_color() throws {
        let result = try "Colored".htmlToAttributedString(
            textColorHex: "#FF0000",
            uiFont: nil,
            linkStyles: nil,
            colorScheme: .light
        )
        XCTAssertTrue(result.string.contains("Colored"))
    }

    // MARK: - Async overload (loadFromHTML path)

    func test_async_htmlToAttributedString_returns_result() {
        let expectation = expectation(description: "loadFromHTML completes")

        "Hello Async".htmlToAttributedString(
            textColorHex: nil,
            uiFont: nil,
            linkStyles: nil,
            colorScheme: .light
        ) { result in
            XCTAssertNotNil(result)
            XCTAssertTrue(result!.string.contains("Hello Async"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_async_htmlToAttributedString_bold_html() {
        let expectation = expectation(description: "loadFromHTML bold completes")

        "<b>AsyncBold</b>".htmlToAttributedString(
            textColorHex: nil,
            uiFont: UIFont.systemFont(ofSize: 14),
            linkStyles: nil,
            colorScheme: .light
        ) { result in
            XCTAssertNotNil(result)
            XCTAssertTrue(result!.string.contains("AsyncBold"))

            let font = result!.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_async_htmlToAttributedString_italic_html() {
        let expectation = expectation(description: "loadFromHTML italic completes")

        "<i>AsyncItalic</i>".htmlToAttributedString(
            textColorHex: nil,
            uiFont: UIFont.systemFont(ofSize: 14),
            linkStyles: nil,
            colorScheme: .light
        ) { result in
            XCTAssertNotNil(result)
            XCTAssertTrue(result!.string.contains("AsyncItalic"))

            let font = result!.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_async_htmlToAttributedString_with_font_color() {
        let expectation = expectation(description: "loadFromHTML color completes")

        "ColorText".htmlToAttributedString(
            textColorHex: "#00FF00",
            uiFont: nil,
            linkStyles: nil,
            colorScheme: .light
        ) { result in
            XCTAssertNotNil(result)
            XCTAssertTrue(result!.string.contains("ColorText"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_async_htmlToAttributedString_empty_string() {
        let expectation = expectation(description: "loadFromHTML empty completes")

        "".htmlToAttributedString(
            textColorHex: nil,
            uiFont: nil,
            linkStyles: nil,
            colorScheme: .light
        ) { result in
            XCTAssertNotNil(result)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_async_htmlToAttributedString_complex_html() {
        let expectation = expectation(description: "loadFromHTML complex completes")
        let html = "<b>Bold</b> and <i>italic</i> with <u>underline</u>"

        html.htmlToAttributedString(
            textColorHex: "#AABBCC",
            uiFont: UIFont.systemFont(ofSize: 16),
            linkStyles: nil,
            colorScheme: .light
        ) { result in
            XCTAssertNotNil(result)
            XCTAssertTrue(result!.string.contains("Bold"))
            XCTAssertTrue(result!.string.contains("italic"))
            XCTAssertTrue(result!.string.contains("underline"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_async_htmlToAttributedString_completes_on_main_thread() {
        let expectation = expectation(description: "completion on main thread")

        "Thread check".htmlToAttributedString(
            textColorHex: nil,
            uiFont: nil,
            linkStyles: nil,
            colorScheme: .light
        ) { _ in
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    // MARK: - Parity between sync and async

    func test_sync_and_async_produce_same_text_content() {
        let expectation = expectation(description: "parity check")
        let html = "<b>Parity</b> test <i>content</i>"

        let syncResult = try? html.htmlToAttributedString(
            textColorHex: nil,
            uiFont: UIFont.systemFont(ofSize: 14),
            linkStyles: nil,
            colorScheme: .light
        )

        html.htmlToAttributedString(
            textColorHex: nil,
            uiFont: UIFont.systemFont(ofSize: 14),
            linkStyles: nil,
            colorScheme: .light
        ) { asyncResult in
            XCTAssertNotNil(syncResult)
            XCTAssertNotNil(asyncResult)
            XCTAssertEqual(syncResult!.string, asyncResult!.string)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }
}
