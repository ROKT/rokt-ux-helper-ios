//
//  RoktUIEvent.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

public class RoktUXEvent {

    /// Triggered when the user engages with the offer
    public class OfferEngagement: RoktUXEvent {
        public let layoutId: String?

        /// Initializes an OfferEngagement event.
        /// - Parameter layoutId: The identifier of the layout.
        init(layoutId: String?) {
            self.layoutId = layoutId
        }
    }
    
    
    
    
    /// Triggered when the user positively engages with the offer for the first time
    public class FirstPositiveEngagement: RoktUXEvent {
        public var sessionId: String
        public var pageInstanceGuid: String
        public var jwtToken: String
        public let layoutId: String?

        /// Initializes a FirstPositiveEngagement event.
        /// - Parameters:
        ///   - sessionId: The session identifier.
        ///   - pageInstanceGuid: The page instance GUID.
        ///   - jwtToken: The JWT token.
        ///   - layoutId: The identifier of the layout.
        init(sessionId: String, pageInstanceGuid: String, jwtToken: String, layoutId: String?) {
            self.sessionId = sessionId
            self.pageInstanceGuid = pageInstanceGuid
            self.jwtToken = jwtToken
            self.layoutId = layoutId
        }
    }
    
    /// Triggered when the user positively engages with the offer
    public class PositiveEngagement: RoktUXEvent {
        public let layoutId: String?
        
        /// Initializes a PositiveEngagement event.
        /// - Parameter layoutId: The identifier of the layout.
        init(layoutId: String?) {
            self.layoutId = layoutId
        }
    }

    /// Triggered when a layout has been rendered and is interactable
    public class LayoutInteractive: RoktUXEvent {
        public let layoutId: String?

        /// Initializes a LayoutInteractive event.
        /// - Parameter layoutId: The identifier of the layout.
        init(layoutId: String?) {
            self.layoutId = layoutId
        }
    }

    /// Triggered when a layout is ready to display but has not rendered content yet
    public class LayoutReady: RoktUXEvent {
        public let layoutId: String?
        
        /// Initializes a LayoutReady event.
        /// - Parameter layoutId: The identifier of the layout.
        init(layoutId: String?) {
            self.layoutId = layoutId
        }
    }

    /// Triggered when a layout is closed by the user
    public class LayoutClosed: RoktUXEvent {
        public let layoutId: String?

        /// Initializes a LayoutClosed event.
        /// - Parameter layoutId: The identifier of the layout.
        init(layoutId: String?) {
            self.layoutId = layoutId
        }
    }

    /// Triggered when the offer progression reaches the end and no more offers are available to display
    public class LayoutCompleted: RoktUXEvent {
        public let layoutId: String?

        /// Initializes a LayoutCompleted event.
        /// - Parameter layoutId: The identifier of the layout.
        init(layoutId: String?) {
            self.layoutId = layoutId
        }
    }

    /// Triggered when a layout could not be displayed due to some failure
    public class LayoutFailure: RoktUXEvent {
        public let layoutId: String?

        /// Initializes a LayoutFailure event.
        /// - Parameter layoutId: The identifier of the layout.
        init(layoutId: String?) {
            self.layoutId = layoutId
        }
    }
    
    /// Triggered when a link needs to be opened
    public class OpenUrl: RoktUXEvent {
        public let url: String
        public let id: String
        public let type: OpenURLType
        public let onClose: ((String) -> Void)?
        public let onError: ((String, Error?) -> Void)?
        
        /// Initializes an OpenUrl event.
        /// - Parameters:
        ///   - url: The URL to open.
        ///   - id: The identifier associated with the URL.
        ///   - type: The type of the URL.
        ///   - onClose: Closure to handle URL close event.
        ///   - onError: Closure to handle URL error event.
        init(url: String,
             id: String,
             type: OpenURLType,
             onClose: @escaping (String) -> Void,
             onError: @escaping (String, Error?) -> Void) {
            self.url = url
            self.id = id
            self.type = type
            self.onClose = onClose
            self.onError = onError
        }
    }
}
