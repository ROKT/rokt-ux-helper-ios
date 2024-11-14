//
//  CatalogStackedCollectionComponent.swift
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
struct CatalogStackedCollectionComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var style: CatalogStackedCollectionStyles? {
        switch styleState {
        default:
            return model.defaultStyle?.count ?? -1 > breakpointIndex ? model.defaultStyle?[breakpointIndex] : nil
        }
    }

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex: Int = 0
    @State var frameChangeIndex: Int = 0

    var containerStyle: ContainerStylingProperties? { style?.container }
    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    var borderStyle: BorderStylingProperties? { style?.border }
    var spacingStyle: SpacingStylingProperties? { style?.spacing }
    var backgroundStyle: BackgroundStylingProperties? { style?.background }

    let config: ComponentConfig
    let model: CatalogStackedCollectionViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?

    let parentOverride: ComponentParentOverride?

    var passableBackgroundStyle: BackgroundStylingProperties? {
        backgroundStyle ?? parentOverride?.parentBackgroundStyle
    }

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

    var accessibilityBehavior: AccessibilityChildBehavior {
        model.accessibilityGrouped ? .combine : .contain
    }

    var body: some View {
        build()
            .applyLayoutModifier(
                verticalAlignmentProperty: verticalAlignment,
                horizontalAlignmentProperty: horizontalAlignment,
                spacing: spacingStyle,
                dimension: dimensionStyle,
                flex: flexStyle,
                border: borderStyle,
                background: backgroundStyle,
                container: containerStyle,
                parent: config.parent,
                parentWidth: $parentWidth,
                parentHeight: $parentHeight,
                parentOverride: parentOverride?.updateBackground(passableBackgroundStyle),
                defaultHeight: .wrapContent,
                defaultWidth: .wrapContent,
                isContainer: true,
                containerType: .column,
                frameChangeIndex: $frameChangeIndex,
                imageLoader: model.imageLoader
            )
            .readSize(spacing: spacingStyle) { size in
                availableWidth = size.width
                availableHeight = size.height
            }
            .onChange(of: globalScreenSize.width) { newSize in
                // run it in background thread for smooth transition
                DispatchQueue.background.async {
                    breakpointIndex = model.updateBreakpointIndex(for: newSize)
                    frameChangeIndex += 1
                }
            }
            .accessibilityElement(children: accessibilityBehavior)
    }

    private func build() -> some View {
        // `alignment` = children edge alignment in the horizontal direction
        DynamicStackView(
            axis: model.template == .column ? .vertical(columnPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems)) : .horizontal(rowPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems)),
            spacing: CGFloat(containerStyle?.gap ?? 0)
        ) {
            ForEach(model.children, id: \.self) { child in
                LayoutSchemaComponent(
                    config: config.updateParent(.column),
                    layout: child,
                    parentWidth: $availableWidth,
                    parentHeight: $availableHeight,
                    styleState: $styleState,
                    parentOverride: ComponentParentOverride(
                        parentVerticalAlignment: columnPrimaryAxisAlignment(
                            justifyContent: containerStyle?.justifyContent
                        ).asVerticalType,
                        parentHorizontalAlignment: columnPerpendicularAxisAlignment(
                            alignItems: containerStyle?.alignItems
                        ),
                        parentBackgroundStyle: passableBackgroundStyle,
                        stretchChildren: containerStyle?.alignItems == .stretch
                    )
                )
            }
        }
    }
}

@available(iOS 13.0, *)
struct DynamicStackView<V: View>: View {
    enum Axis {
        case vertical(HorizontalAlignment)
        case horizontal(VerticalAlignment)
    }
    let axis: Axis
    let spacing: CGFloat
    var content: () -> V

    var body: some View {
        switch axis {
        case .vertical(let horizontalAlignment):
            VStack(
                alignment: horizontalAlignment,
                spacing: spacing
            ) {
                content()
            }
        case .horizontal(let verticalAlignment):
            HStack(
                alignment: verticalAlignment,
                spacing: spacing
            ) {
                content()
            }
        }
    }
}
