//
//  ScrollableColumnComponent.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import DcuiSchema

@available(iOS 15, *)
struct ScrollableColumnComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    let config: ComponentConfig
    let model: ColumnViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?
    @State private var contentHeight: CGFloat?
    @State private var contentMaxHeight: CGFloat?
    @State private var contentAlignment: Alignment = .center // SwiftUI default frame alignment

    var style: ColumnStyle? {
        switch styleState {
        case .hovered:
            return model.hoveredStyle?.count ?? -1 > breakpointIndex ? model.hoveredStyle?[breakpointIndex] : nil
        case .pressed:
            return model.pressedStyle?.count ?? -1 > breakpointIndex ? model.pressedStyle?[breakpointIndex] : nil
        case .disabled:
            return model.disabledStyle?.count ?? -1 > breakpointIndex ? model.disabledStyle?[breakpointIndex] : nil
        default:
            return model.defaultStyle?.count ?? -1 > breakpointIndex ? model.defaultStyle?[breakpointIndex] : nil
        }
    }

    @State var breakpointIndex: Int = 0

    var containerStyle: ContainerStylingProperties? { style?.container }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }

    let parentOverride: ComponentParentOverride?

    var verticalAlignment: VerticalAlignmentProperty {
        if let justifyContent = containerStyle?.justifyContent?.asVerticalAlignmentProperty {
            return justifyContent
        } else if let parentAlign = parentOverride?.parentVerticalAlignment?.asVerticalAlignmentProperty {
            return parentAlign
        } else {
            return .top
        }
    }

    var horizontalAlignment: HorizontalAlignmentProperty {
        if let alignItems = containerStyle?.alignItems?.asHorizontalAlignmentProperty {
            return alignItems
        } else if let parentAlign = parentOverride?.parentHorizontalAlignment?.asHorizontalAlignmentProperty {
            return parentAlign
        } else {
            return .start
        }
    }

    var weightProperties: WeightModifier.Properties {
        WeightModifier.Properties(weight: flexStyle?.weight,
                                  parent: .column,
                                  verticalAlignment: verticalAlignment.getAlignment(),
                                  horizontalAlignment: horizontalAlignment.getAlignment())
    }

    var body: some View {
        ScrollView(.vertical) {
            ColumnComponent(config: config,
                            model: model,
                            parentWidth: $parentWidth,
                            parentHeight: $parentHeight,
                            styleState: $styleState,
                            parentOverride: parentOverride)
            .readSize(weightProperties: weightProperties) { newSizeWithMax, newAlignment in
                if let newMaxHeight = newSizeWithMax.maxHeight {
                    contentMaxHeight = newMaxHeight
                } else {
                    contentHeight = newSizeWithMax.size.height
                }
                contentAlignment = newAlignment
            }
        }
        .frame(maxHeight: contentMaxHeight, alignment: contentAlignment)
        .frame(height: contentHeight, alignment: contentAlignment)
    }
}
