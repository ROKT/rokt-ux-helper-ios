//
//  TestPlaceHolder.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15.0, *)
struct TestPlaceHolder: View {
    let layout: LayoutSchemaViewModel
    var layoutState: LayoutState
    var eventService: EventService?

    init(
        layout: LayoutSchemaViewModel,
        layoutState: LayoutState = LayoutState(),
        eventService: EventService? = nil
    ) {
        self.layout = layout
        self.layoutState = layoutState
        self.eventService = eventService
    }

    var body: some View {
        EmbeddedComponent(
            layout: layout,
            layoutState: layoutState,
            eventService: eventService,
            onLoad: nil,
            onSizeChange: nil
        )
    }
}

@available(iOS 15.0, *)
extension TestPlaceHolder {

    static func make(
        layoutSettings: LayoutSettings? = nil,
        eventHandler: @escaping ((RoktEventRequest) -> Void) = { _ in },
        eventDelegate: UXEventsDelegate = MockUXHelper(),
        layoutMaker: (LayoutState, EventService) throws -> LayoutSchemaViewModel
    ) throws -> Self {
        let layoutState = LayoutState()
        layoutState.items[LayoutState.layoutSettingsKey] = layoutSettings
        let eventService = get_mock_event_processor(uxEventDelegate: eventDelegate, eventHandler: eventHandler)
        return TestPlaceHolder(
            layout: try layoutMaker(layoutState, eventService),
            layoutState: layoutState,
            eventService: eventService
        )
    }
}
