//
//  MockEventProcessor.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import Combine
@testable import RoktUXHelper

@available(iOS 13.0, *)
class MockEventProcessor: EventProcessing {
    var publisher: PassthroughSubject<EventRequest, Never> = .init()
    var handler: ((EventRequest) -> Void)?
    
    init(handler: ((EventRequest) -> Void)? = nil) {
        self.handler = handler
    }
    
    func handle(event: EventRequest) {
        handler?(event)
    }
}
