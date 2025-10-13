//
//  CatalogImageGalleryComponent.swift
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//  See https://rokt.com/sdk-license-2-0/

import SwiftUI
import DcuiSchema

@available(iOS 15, *)
struct CatalogImageGalleryComponent: View {
    @EnvironmentObject private var globalScreenSize: GlobalScreenSize

    private var style: CatalogImageGalleryStyles? {
        model.defaultStyle?[safe: breakpointIndex]
    }

    private var containerStyle: ContainerStylingProperties? { style?.container }
    private var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    private var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    private var borderStyle: BorderStylingProperties? { style?.border }
    private var spacingStyle: SpacingStylingProperties? { style?.spacing }
    private var backgroundStyle: BackgroundStylingProperties? { style?.background }

    let config: ComponentConfig
    @ObservedObject var model: CatalogImageGalleryViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState

    let parentOverride: ComponentParentOverride?

    @State private var breakpointIndex: Int = 0
    @State private var frameChangeIndex: Int = 0
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?
    @State private var selectedIndex: Int = 0

    private var passableBackgroundStyle: BackgroundStylingProperties? {
        backgroundStyle ?? parentOverride?.parentBackgroundStyle
    }

    private var verticalAlignment: VerticalAlignmentProperty {
        if let justifyContent = containerStyle?.justifyContent?.asVerticalAlignmentProperty {
            return justifyContent
        } else if let parentAlign = parentOverride?.parentVerticalAlignment?.asVerticalAlignmentProperty {
            return parentAlign
        } else {
            return .top
        }
    }

    private var horizontalAlignment: HorizontalAlignmentProperty {
        if let alignItems = containerStyle?.alignItems?.asHorizontalAlignmentProperty {
            return alignItems
        } else if let parentAlign = parentOverride?.parentHorizontalAlignment?.asHorizontalAlignmentProperty {
            return parentAlign
        } else {
            return .start
        }
    }

    var body: some View {
        VStack(
            alignment: columnPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems),
            spacing: CGFloat(containerStyle?.gap ?? 16)
        ) {
            mainImageView
            thumbnailsView
        }
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
            DispatchQueue.background.async {
                breakpointIndex = model.updateBreakpointIndex(for: newSize)
                frameChangeIndex += 1
            }
        }
        .onChange(of: model.images) { _ in
            selectedIndex = min(selectedIndex, max(0, model.images.count - 1))
        }
    }

    private var mainImageView: some View {
        ZStack {
            if let currentImage = model.images[safe: selectedIndex] {
                DataImageViewComponent(
                    config: config.updateParent(.column),
                    model: currentImage,
                    parentWidth: $availableWidth,
                    parentHeight: $availableHeight,
                    styleState: $styleState,
                    parentOverride: ComponentParentOverride(
                        parentVerticalAlignment: .center,
                        parentHorizontalAlignment: .center,
                        parentBackgroundStyle: passableBackgroundStyle,
                        stretchChildren: false
                    ),
                    expandsToContainerOnSelfAlign: false
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            handleSwipe(translation: value.translation)
                        }
                )
                .overlay(
                    HStack(spacing: 0) {
                        // Left tap area - go to previous
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                goToPreviousImage()
                            }

                        // Right tap area - go to next
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                goToNextImage()
                            }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var thumbnailsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: rowPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems),
                   spacing: CGFloat(containerStyle?.gap ?? 8)) {
                ForEach(Array(model.images.enumerated()), id: \.element.id) { index, imageViewModel in
                    let isSelected = index == selectedIndex
                    DataImageViewComponent(
                        config: config.updateParent(.row),
                        model: imageViewModel,
                        parentWidth: .constant(nil),
                        parentHeight: .constant(nil),
                        styleState: $styleState,
                        parentOverride: ComponentParentOverride(
                            parentVerticalAlignment: .center,
                            parentHorizontalAlignment: .center,
                            parentBackgroundStyle: passableBackgroundStyle,
                            stretchChildren: false
                        ),
                        expandsToContainerOnSelfAlign: false
                    )
                    .applyLayoutModifier(
                        verticalAlignmentProperty: .center,
                        horizontalAlignmentProperty: .center,
                        spacing: model.thumbnailSpacing(breakpointIndex: breakpointIndex),
                        dimension: model.thumbnailDimension(for: styleState, breakpointIndex: breakpointIndex),
                        flex: nil,
                        border: model.borderForThumbnail(
                            isSelected: isSelected,
                            state: styleState,
                            breakpointIndex: breakpointIndex
                        ),
                        background: model.backgroundForThumbnail(state: styleState, breakpointIndex: breakpointIndex),
                        container: nil,
                        parent: config.parent,
                        parentWidth: .constant(nil),
                        parentHeight: .constant(nil),
                        parentOverride: parentOverride,
                        defaultHeight: .wrapContent,
                        defaultWidth: .wrapContent,
                        expandsToContainerOnSelfAlign: false,
                        isContainer: false,
                        containerType: .row,
                        frameChangeIndex: .constant(0),
                        imageLoader: model.imageLoader
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal, horizontalInset)
        }
    }

    private var horizontalInset: CGFloat {
        guard let padding = spacingStyle?.padding else { return 0 }
        let frame = FrameAlignmentProperty.getFrameAlignment(padding)
        return CGFloat(frame.left + frame.right)/2
    }

    private func handleSwipe(translation: CGSize) {
        if translation.width < -50 {
            // Swipe left - go to next image
            goToNextImage()
        } else if translation.width > 50 {
            // Swipe right - go to previous image
            goToPreviousImage()
        }
    }

    private func goToNextImage() {
        guard selectedIndex < model.images.count - 1 else { return }
        withAnimation(.easeInOut) {
            selectedIndex += 1
        }
    }

    private func goToPreviousImage() {
        guard selectedIndex > 0 else { return }
        withAnimation(.easeInOut) {
            selectedIndex -= 1
        }
    }
}
