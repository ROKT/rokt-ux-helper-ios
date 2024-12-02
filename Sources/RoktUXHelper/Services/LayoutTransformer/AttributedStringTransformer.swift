//
//  AttributedStringTransformer.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI

@available(iOS 15, *)
class AttributedStringTransformer {

    static func convertRichTextHTMLIfExists(
        uiModel: LayoutSchemaViewModel,
        config: RoktUXConfig?,
        colorScheme: ColorScheme? = nil
    ) {
        switch uiModel {
        case .richText(let richTextUIModel):
            richTextUIModel.transformValueToAttributedString(config?.colorMode, colorScheme: nil)
        default:
            guard let parentModel = uiModel.componentViewModel as? DomainMappableParent else { return }
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        }
    }

    static func convertRichTextHTMLInChildren(parent: DomainMappableParent, config: RoktUXConfig?) {
        parent.children?.forEach {
            convertRichTextHTMLIfExists(uiModel: $0, config: config)
        }
    }
}
