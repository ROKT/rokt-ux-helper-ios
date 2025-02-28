//
//  ImageViewComponent.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import Combine
import DcuiSchema

@available(iOS 15, *)
struct StaticImageViewComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    private var style: BaseStyles? {
        switch styleState {
        case .hovered:
            model.stylingProperties?[safe: breakpointIndex]?.hovered
        case .pressed:
            model.stylingProperties?[safe: breakpointIndex]?.pressed
        case .disabled:
            model.stylingProperties?[safe: breakpointIndex]?.disabled
        default:
            model.stylingProperties?[safe: breakpointIndex]?.default
        }
    }

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex = 0

    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    var borderStyle: BorderStylingProperties? { style?.border }
    var spacingStyle: SpacingStylingProperties? { style?.spacing }
    var backgroundStyle: BackgroundStylingProperties? { style?.background }

    let config: ComponentConfig
    let model: StaticImageViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState

    @State private var isImageValid = true

    let parentOverride: ComponentParentOverride?
    let expandsToContainerOnSelfAlign: Bool

    var verticalAlignment: VerticalAlignmentProperty {
        parentOverride?.parentVerticalAlignment?.asVerticalAlignmentProperty ?? .center
    }

    var horizontalAlignment: HorizontalAlignmentProperty {
        parentOverride?.parentHorizontalAlignment?.asHorizontalAlignmentProperty ?? .center
    }

    var body: some View {
        if isImageValid && hasUrlForColorScheme() {
            build()
                .applyLayoutModifier(
                    verticalAlignmentProperty: verticalAlignment,
                    horizontalAlignmentProperty: horizontalAlignment,
                    spacing: spacingStyle,
                    dimension: dimensionStyle,
                    flex: flexStyle,
                    border: borderStyle,
                    background: backgroundStyle,
                    parent: config.parent,
                    parentWidth: $parentWidth,
                    parentHeight: $parentHeight,
                    parentOverride: parentOverride,
                    defaultHeight: .wrapContent,
                    defaultWidth: .wrapContent,
                    expandsToContainerOnSelfAlign: expandsToContainerOnSelfAlign,
                    imageLoader: model.imageLoader
                )
                .onChange(of: globalScreenSize.width) { newSize in
                    // run it in background thread for smooth transition
                    DispatchQueue.background.async {
                        breakpointIndex = model.updateBreakpointIndex(for: newSize)
                    }
                }
        } else {
            EmptyView()
        }
    }

    func build() -> some View {
        AsyncImageView(
            imageUrl: toThemeUrl(model.url),
            scale: .fit,
            alt: model.alt,
            imageLoader: model.imageLoader,
            isImageValid: $isImageValid
        )
    }

    func toThemeUrl(_ url: StaticImageUrl?) -> ThemeUrl? {
        guard let url else { return nil}
        return ThemeUrl(light: url.light, dark: url.dark ?? url.light)
    }

    func hasUrlForColorScheme() -> Bool {
        (model.url?.light.isEmpty == false && colorScheme == .light) ||
        (
            (model.url?.dark?.isEmpty == false || (model.url?.dark == nil && model.url?.light.isEmpty == false)) &&
            colorScheme == .dark
        )
    }
}
