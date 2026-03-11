//
//  TestRoktLayoutView.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//

import XCTest
import SwiftUI
import ViewInspector
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestRoktLayoutView: XCTestCase {

    /// When state is .empty we render Color.clear.frame(0,0) instead of EmptyView (appearance-crash fix).
    func test_empty_state_renders_color_clear_not_empty_view() throws {
        let view = RoktLayoutView(
            experienceResponse: "",
            location: "loc",
            config: nil,
            onUXEvent: nil,
            onPlatformEvent: nil
        )
        let vstack = try view.inspect().vStack()
        // With appearance fix, .empty case shows Color.clear; EmptyView is not in the hierarchy.
        XCTAssertNil(try? vstack.find(ViewType.EmptyView.self))
        XCTAssertNoThrow(try vstack.find(ViewType.Color.self))
    }
}
