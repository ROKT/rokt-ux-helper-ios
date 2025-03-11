//
//  DataImageCarouselComponent.swift
//  RoktUXHelper
//
//  Copyright 2020 Rokt Pte Ltd
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
struct DataImageCarouselComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    private var style: DataImageCarouselStyles? {
        switch styleState {
        case .hovered:
            model.stylingProperties?[safe: breakpointIndex]?.hovered
        case .pressed:
            model.stylingProperties?[safe: breakpointIndex]?.pressed
        case .disabled:
            model.stylingProperties?[safe: breakpointIndex]?.disabled
        default:
            model.defaultStyle?[safe: breakpointIndex]
        }
    }

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex = 0

    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    var borderStyle: BorderStylingProperties? { style?.border }
    var spacingStyle: SpacingStylingProperties? { style?.spacing }
    var backgroundStyle: BackgroundStylingProperties? { style?.background }
    var containerStyle: ContainerStylingProperties? { style?.container }

    let config: ComponentConfig
    let model: DataImageCarouselViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState
    @Binding var customStateMap: RoktUXCustomStateMap?

    init(
        config: ComponentConfig,
        model: DataImageCarouselViewModel,
        parentWidth: Binding<CGFloat?>,
        parentHeight: Binding<CGFloat?>,
        styleState: Binding<StyleState>,
        parentOverride: ComponentParentOverride?
    ) {
        self.config = config
        self.model = model
        self._parentWidth = parentWidth
        self._parentHeight = parentHeight
        self._styleState = styleState
        self.parentOverride = parentOverride

        _customStateMap = model.layoutState?.items[LayoutState.customStateMap] as? Binding<RoktUXCustomStateMap?> ?? .constant(nil)
    }

    let parentOverride: ComponentParentOverride?

    // Carousel specific states
    @State private var currentImage = 0
    @State private var isAutoScrolling = true
    @State private var opacities: [Double] = []
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?

    var verticalAlignment: VerticalAlignmentProperty {
        if let justifyContent = containerStyle?.alignItems?.asVerticalAlignmentProperty {
            return justifyContent
        } else if let parentAlign = parentOverride?.parentVerticalAlignment?.asVerticalAlignmentProperty {
            return parentAlign
        } else {
            return .top
        }
    }

    var horizontalAlignment: HorizontalAlignmentProperty {
        if let alignItems = containerStyle?.justifyContent?.asHorizontalAlignmentProperty {
            return alignItems
        } else if let parentAlign = parentOverride?.parentHorizontalAlignment?.asHorizontalAlignmentProperty {
            return parentAlign
        } else {
            return .start
        }
    }

    var body: some View {

        if !model.images.isEmpty {
            // Initialize opacities array if needed
            ZStack(
                alignment: .init(
                    horizontal: horizontalAlignment.getHorizontalAlignment(),
                    vertical: verticalAlignment.getVerticalAlignment()
                )
            ) {
                ForEach(0..<model.images.count, id: \.self) { index in
                    imageView(for: model.images[index])
                        .opacity(index < opacities.count ? opacities[index] : 0)
                }

                // Custom progress indicator to be implemented separately
                if model.images.count > 1 {
                    ImageCarouselIndicator(
                        config: config,
                        model: model.indicatorViewModel,
                        styleState: $styleState,
                        parentWidth: $availableWidth,
                        parentHeight: $availableHeight,
                        parentOverride: parentOverride
                    )
                    .onReceive(model.$currentProgress.dropFirst()) { currentProgress in
                        let newPosition = max(currentProgress - 1, 0)
                        if currentImage != newPosition {
                            advanceToNextImage()
                        }
                        let positionKey = CustomStateIdentifiable(position: config.position, key: .imageCarouselPosition)
                        customStateMap?[positionKey] = currentProgress
                        let key = CustomStateIdentifiable(position: config.position, key: .imageCarouselKey(key: model.key))
                        customStateMap?[key] = currentProgress
                        model.layoutState?.publishStateChange()
                    }
                }
            }
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
                expandsToContainerOnSelfAlign: false,
                imageLoader: model.imageLoader
            )
            .onChange(of: globalScreenSize.width) { newSize in
                // run it in background thread for smooth transition
                DispatchQueue.background.async {
                    breakpointIndex = model.updateBreakpointIndex(for: newSize)
                }
            }
            .readSize(spacing: spacingStyle) { size in
                availableWidth = size.width
                availableHeight = size.height
            }
            .onLoad {
                // Initialize opacities array with first image visible
                if opacities.isEmpty {
                    opacities = Array(repeating: 0.0, count: model.images.count)
                    opacities[0] = 1.0
                }
                model.onAppear()
            }
            .onDisappear {
                model.onDisappear()
            }
        } else {
            EmptyView()
        }
    }

    private func imageView(for image: CreativeImage) -> some View {
        AsyncImageView(
            imageUrl: ThemeUrl(light: image.light ?? "", dark: image.dark ?? ""),
            scale: .fit,
            alt: image.alt,
            imageLoader: model.imageLoader,
            isImageValid: .constant(true)
        )
        .frame(maxWidth: .infinity)
        .aspectRatio(contentMode: .fit)
    }

    private func advanceToNextImage() {
        guard !model.images.isEmpty else { return }

        // Fade out current image
        withAnimation(.easeInOut(duration: 0.5)) {
            opacities[currentImage] = 0.0
        }

        // Advance to next image
        currentImage = (currentImage + 1) % model.images.count

        // Fade in new image
        withAnimation(.easeInOut(duration: 0.5)) {
            opacities[currentImage] = 1.0
        }
    }
}
