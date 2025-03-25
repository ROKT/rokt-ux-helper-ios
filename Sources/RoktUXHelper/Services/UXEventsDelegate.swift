//
//  UXEventsDelegate.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

protocol UXEventsDelegate: AnyObject {
    func onOfferEngagement(_ layoutId: String)
    func onPositiveEngagement(_ layoutId: String)
    func onPlacementInteractive(_ layoutId: String)
    func onPlacementReady(_ layoutId: String)
    func onPlacementClosed(_ layoutId: String)
    func onPlacementCompleted(_ layoutId: String)
    func onPlacementFailure(_ layoutId: String)
    func onFirstPositiveEngagement(
        sessionId: String,
        pluginInstanceGuid: String,
        jwtToken: String,
        layoutId: String
    )
    func openURL(url: String,
                 id: String,
                 layoutId: String,
                 type: RoktUXOpenURLType,
                 onClose: @escaping (String) -> Void,
                 onError: @escaping (String, Error?) -> Void)
    
    func onCartItemInstantPurchase(_ layoutId: String, catalogItem: CatalogItem)
}
