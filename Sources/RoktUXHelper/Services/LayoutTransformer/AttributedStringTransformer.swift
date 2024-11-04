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
        case .overlay(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .bottomSheet(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .row(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .scrollableRow(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .column(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .scrollableColumn(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .zStack(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .oneByOne(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .carousel(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .progressControl(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .groupDistribution(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .when(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .creativeResponse(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .toggleButton(let parentModel):
            convertRichTextHTMLInChildren(parent: parentModel, config: config)
        case .richText(let richTextUIModel):
            richTextUIModel.transformValueToAttributedString(config?.colorMode, colorScheme: nil)
        default:
            break
        }
    }

    static func convertRichTextHTMLInChildren(parent: DomainMappableParent, config: RoktUXConfig?) {
        guard let children = parent.children, !children.isEmpty else { return }

        children.forEach { convertRichTextHTMLIfExists(uiModel: $0, config: config) }
    }
}
