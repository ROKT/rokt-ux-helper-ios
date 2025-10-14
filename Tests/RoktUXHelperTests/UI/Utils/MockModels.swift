//
//  MockModels.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
@testable import RoktUXHelper
import DcuiSchema

let mockPluginInstanceGuid = "pluginInstanceGuid"
let mockPluginConfigJWTToken = "plugin-config-token"
let mockPluginId = "pluginId"
let mockPluginName = "pluginName"
let mockPageId = "pageId"
let mockPageInstanceGuid = "pageInstanceGuid"

func get_mock_layout_plugin(pluginInstanceGuid: String = "",
                            breakpoints: BreakPoint? = nil,
                            settings: LayoutSettings? = nil,
                            layout: LayoutSchemaModel? = nil,
                            slots: [SlotModel] = [],
                            targetElementSelector: String? = "",
                            pluginConfigJWTToken: String = "",
                            pluginId: String = "",
                            pluginName: String? = "") -> LayoutPlugin {
    return LayoutPlugin(pluginInstanceGuid: pluginInstanceGuid,
                        breakpoints: breakpoints,
                        settings: settings,
                        layout: layout,
                        slots: slots,
                        targetElementSelector: targetElementSelector,
                        pluginConfigJWTToken: pluginConfigJWTToken,
                        pluginId: pluginId,
                        pluginName: pluginName)
}

func get_mock_uistate(currentProgress: Int = 0,
                      totalOffers: Int = 1,
                      position: Int? = nil,
                      width: CGFloat = 100,
                      isDarkMode: Bool = false,
                      customStateMap: RoktUXCustomStateMap? = nil) -> WhenComponentUIState {
    return WhenComponentUIState(currentProgress: currentProgress,
                                totalOffers: totalOffers,
                                position: position,
                                width: width,
                                isDarkMode: isDarkMode,
                                customStateMap: customStateMap)
}

@available(iOS 13.0, *)
func get_mock_event_processor(startDate: Date = Date(),
                              catalogItems: [CatalogItem] = [],
                              responseReceivedDate: Date = Date(),
                              uxEventDelegate: UXEventsDelegate = MockUXHelper(),
                              useDiagnosticEvents: Bool = false,
                              eventHandler: @escaping (RoktEventRequest) -> Void = { _ in }) -> EventService {
    return EventService(pageId: mockPageId,
                        pageInstanceGuid: mockPageInstanceGuid,
                        sessionId: "session",
                        pluginInstanceGuid: mockPluginInstanceGuid,
                        pluginId: mockPluginId, 
                        pluginName: mockPluginName,
                        startDate: startDate,
                        catalogItems: catalogItems,
                        uxEventDelegate: uxEventDelegate,
                        processor: MockEventProcessor(handler: eventHandler),
                        responseReceivedDate: responseReceivedDate,
                        pluginConfigJWTToken: mockPluginConfigJWTToken,
                        useDiagnosticEvents: useDiagnosticEvents)
}

extension OfferModel {
    static func mock(
        campaignId: String = "",
        referralCreativeId: String = "",
        instanceGuid: String = "",
        copy: [String: String] = [:],
        images: [String: CreativeImage]? = nil,
        responseOptionList: ResponseOptionList? = nil,
        token: String = ""
    ) -> Self {
        .init(
            campaignId: campaignId,
            creative: .init(
                referralCreativeId: referralCreativeId,
                instanceGuid: instanceGuid,
                copy: copy,
                images: images,
                links: [:],
                responseOptionsMap: responseOptionList,
                jwtToken: token
            ),
            catalogItems: nil
        )
    }
}

extension CatalogItem {
    static func mock(
        catalogItemId: String = "catalogItemId",
        images: [String: CreativeImage]? = nil
    ) -> Self {
        let imageMap = images ?? [
            "catalogItemImage0": CreativeImage(
                light: "https://www.rokt.com",
                dark: nil,
                alt: nil,
                title: nil
            )
        ]
        return .init(
            images: imageMap,
            catalogItemId: catalogItemId,
            cartItemId: "cartItemId",
            instanceGuid: "catalogInstanceGuid",
            title: "Catalog Title",
            description: "Catalog Description",
            price: 14.99,
            priceFormatted: "$14.99",
            originalPrice: 14.99,
            originalPriceFormatted: "$14.99",
            currency: "USD",
            signalType: "mockSignalType",
            url: "https://www.example.com",
            minItemCount: 1,
            maxItemCount: 10,
            preSelectedQuantity: 1,
            providerData: "861425",
            urlBehavior: "mockUrlBehavior",
            positiveResponseText: "Add to order",
            negativeResponseText: "Dismiss",
            addOns: ["addon1", "addon2"],
            copy: ["key1": "value1", "key2": "value2"],
            linkedProductId: "linked",
            token: "catalog1Token"
        )
    }
}
