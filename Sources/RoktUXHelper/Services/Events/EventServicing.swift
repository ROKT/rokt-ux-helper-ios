//
//  EventServicing.swift
//  
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

protocol EventServicing: AnyObject {
    var dismissOption: LayoutDismissOptions? { get set }
    func sendSignalLoadStartEvent()
    func sendEventsOnTransformerSuccess()
    func sendSignalActivationEvent()
    func sendEventsOnLoad()
    func sendSlotImpressionEvent(instanceGuid: String, jwtToken: String)
    func sendSignalViewedEvent(instanceGuid: String, jwtToken: String)
    func sendSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool)
    func sendGatedSignalResponseEvent(instanceGuid: String, jwtToken: String, isPositive: Bool)
    func sendDismissalEvent()
    func openURL(url: URL, type: RoktUXOpenURLType, completionHandler: @escaping () -> Void)
    func cartItemInstantPurchase(catalogItem: CatalogItem)
    func cartItemInstantPurchaseSuccess(itemId: String)
    func cartItemInstantPurchaseFailure(itemId: String)
}
