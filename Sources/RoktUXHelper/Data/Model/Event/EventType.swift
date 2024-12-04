//
//  EventType.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

/// Enum representing different types of platform events
/// Platform events are an essential part of integration and it has to be sent to Rokt via your backend
public enum EventType: String, Codable, CaseIterable {
    /// Triggered when the first offer is displayed and again when the user navigates to a different offer.
    case SignalImpression
    /// Indicates the initialisation of the ROKT
    case SignalInitialize
    /// Triggered when the layout started loading.
    case SignalLoadStart
    /// Triggered when the layout finished loading.
    case SignalLoadComplete
    /// Triggered when the user engages with the offer.
    case SignalGatedResponse
    /// Triggered when the user engages with the offer.
    case SignalResponse
    /// Triggered when the layout is dismissed by the user.
    case SignalDismissal
    /// Triggered when there is an error on RoktUXHelper.
    case SignalSdkDiagnostic
    /// Triggered when user engages with the offer area.
    case SignalActivation
    /// Triggered when the content displays to user.
    case SignalViewed
    /// Triggered when the user clicks catalog response button.
    case SignalCartItemInstantPurchaseInitiated
    /// Triggered when instant purchase succeeds
    case SignalCartItemInstantPurchase
    /// Triggered when instant purchase fails
    case SignalCartItemInstantPurchaseFailure
    /// Not applicable
    case CaptureAttributes
}
