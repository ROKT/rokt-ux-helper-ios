//
//  RoktUXS2SExperienceResponse.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

@available(iOS 13, *)
public class RoktUXS2SExperienceResponse: Decodable, PluginResponse {
    let sessionId: String
    let pageContext: RoktUXPageContext
    let options: [SDKOption]?

    var plugins: [PluginWrapperModel]?

    enum CodingKeys: String, CodingKey {
        case sessionId
        case pageContext
        case plugins
        case options
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        sessionId = try container.decode(String.self, forKey: .sessionId)
        pageContext = try container.decode(RoktUXPageContext.self, forKey: .pageContext)
        plugins = try container.decodeIfPresent([PluginWrapperModel].self, forKey: .plugins)
        options = try container.decodeIfPresent([String: Bool].self, forKey: .options)?.compactMap(SDKOption.init)
    }

    func getPageModel() -> RoktUXPageModel? {
        guard let outerLayer = getOuterLayoutSchema(plugins: plugins),
              outerLayer.layout != nil && getAllInnerlayoutSchema(plugins: plugins) != nil
        else { return nil }

        return RoktUXPageModel(
            pageId: pageContext.pageId,
            sessionId: sessionId,
            pageInstanceGuid: pageContext.pageInstanceGuid,
            layoutPlugins: getPlugins(plugins: plugins),
            eventData: [],
            token: pageContext.token,
            options: options
        )
    }
}
