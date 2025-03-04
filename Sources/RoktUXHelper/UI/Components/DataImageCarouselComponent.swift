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
    @State private var timer: Timer?
    @State private var isAutoScrolling = true
    @State private var opacities: [Double] = []
    @State private var timerPublisher = Timer.publish(every: 3.0, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?

    // Indicator styles
    private var indicatorStyle: DataImageCarouselIndicatorStyles? {
        return model.indicatorStyle?.count ?? -1 > breakpointIndex ? model.indicatorStyle?[breakpointIndex].default : nil
    }

    private var seenIndicatorStyle: DataImageCarouselIndicatorStyles? {
        return model.seenIndicatorStyle?.count ?? -1 > breakpointIndex ? model.seenIndicatorStyle?[breakpointIndex].default : nil
    }

    private var activeIndicatorStyle: DataImageCarouselIndicatorStyles? {
        return model.activeIndicatorStyle?.count ?? -1 > breakpointIndex ? model.activeIndicatorStyle?[breakpointIndex]
            .default : nil
    }

    private var progressIndicatorContainerStyle: DataImageCarouselIndicatorStyles? {
        return model.progressIndicatorContainer?.count ?? -1 > breakpointIndex ? model
            .progressIndicatorContainer?[breakpointIndex].default : nil
    }

    var verticalAlignment: VerticalAlignmentProperty {
        parentOverride?.parentVerticalAlignment?.asVerticalAlignmentProperty ?? .center
    }

    var horizontalAlignment: HorizontalAlignmentProperty {
        parentOverride?.parentHorizontalAlignment?.asHorizontalAlignmentProperty ?? .center
    }

    var body: some View {

        if !model.images.isEmpty {
            VStack(spacing: 0) {
                // Initialize opacities array if needed
                ZStack {
                    ForEach(0..<model.images.count, id: \.self) { index in
                        imageView(for: model.images[index])
                            .opacity(index < opacities.count ? opacities[index] : 0)
                    }
                }
                .frame(
                    minHeight: getFixedHeight(),
                    maxHeight: getMaxHeight()
                )
                .onAppear {
                    // Initialize opacities array with first image visible
                    if opacities.isEmpty {
                        opacities = Array(repeating: 0.0, count: model.images.count)
                        opacities[0] = 1.0
                    }
                    setupTimer()
                }
                .onDisappear {
                    stopTimer()
                }

                // Custom progress indicator to be implemented separately
                if model.images.count > 1 {
                    ImageCarouselIndicator(
                        config: config,
                        model: model.indicatorViewModel,
                        styleState: $styleState,
                        parentWidth: $parentWidth,
                        parentHeight: $parentHeight,
                        parentOverride: parentOverride
                    )
                    .onReceive(model.$currentProgress.dropFirst()) { currentProgress in
                        let key = CustomStateIdentifiable(position: 0, key: "creativeImage")
                        customStateMap?[key] = currentProgress
                        model.layoutState?.publishStateChange()
                    }
                    .onLoad {
                        model.onAppear()
                    }
                    .onDisappear {
                        model.onDisappear()
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

    private func setupTimer() {
        stopTimer()

        // Only setup timer if there are multiple images and duration is greater than 0
        if model.images.count > 1 && model.duration > 0 {
            // Create a timer publisher with the specified duration
            timerPublisher = Timer.publish(every: TimeInterval(model.duration)/1000.0, on: .main, in: .common)
            timerCancellable = timerPublisher.connect()

            // Subscribe to the timer publisher
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(model.duration)/1000.0, repeats: true) { _ in
                if self.isAutoScrolling {
                    self.advanceToNextImage()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerCancellable?.cancel()
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

    private func getFixedHeight() -> CGFloat? {
        if let height = dimensionStyle?.height, case .fixed(let value) = height {
            return CGFloat(value ?? 0)
        }
        return nil
    }

    private func getMaxHeight() -> CGFloat? {
        if let height = dimensionStyle?.height {
            switch height {
            case .fixed(let value):
                return CGFloat(value ?? 0)
            case .percentage:
                // Percentage height is handled by applyLayoutModifier
                return nil
            case .fit(let fitProperty):
                if fitProperty == .fitHeight {
                    return parentHeight
                }
                return nil
            }
        }
        return nil
    }
}
