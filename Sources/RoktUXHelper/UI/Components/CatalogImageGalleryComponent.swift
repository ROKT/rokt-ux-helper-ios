//
//  CatalogImageGalleryComponent.swift
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

struct PassthroughTapView: UIViewRepresentable {
    var onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        view.addGestureRecognizer(UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        ))

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    class Coordinator: NSObject {
        let onTap: (CGPoint) -> Void
        init(onTap: @escaping (CGPoint) -> Void) { self.onTap = onTap }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: sender.view)
            onTap(location)
        }
    }
}

@available(iOS 15, *)
struct HSPageView<Content: View>: View {
    @Binding var page: Int
    let pages: Int
    let content: Content
    @GestureState private var dragState: CGFloat = 0

    init(page: Binding<Int>, pages: Int, @ViewBuilder content: () -> Content) {
        self._page = page
        self.pages = pages
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let dragGesture = DragGesture(minimumDistance: 10)
                 .updating($dragState) { value, state, _ in
                     state = value.translation.width
                 }
                 .onEnded { value in
                     let threshold = geo.size.width/2
                     var newPage = page

                     if value.translation.width < -threshold {
                         newPage += 1
                     } else if value.translation.width > threshold {
                         newPage -= 1
                     }

                     page = max(min(newPage, pages - 1), 0)
                 }

            _VariadicView.Tree(HSStackPager(width: geo.size.width, page: page, dragState: dragState), content: { content })
                .animation(.easeOut(duration: 0.25), value: page)
                .animation(.easeOut(duration: 0.25), value: dragState)

            PassthroughTapView { point in
                let isLeft = point.x < geo.size.width/2

                if isLeft {
                    page = max(page - 1, 0)
                } else {
                    page = min(page + 1, pages - 1)
                }
            }
            .highPriorityGesture(dragGesture)
            .allowsHitTesting(true)
        }
    }

    struct HSStackPager: _VariadicView_UnaryViewRoot {
        let width: CGFloat
        let page: Int
        let dragState: CGFloat

        func body(children: _VariadicView.Children) -> some View {
            HStack(spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    child.frame(width: width)
                }
            }
            .offset(x: -CGFloat(page) * width + CGFloat(dragState))
        }
    }
}

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
    @GestureState private var dragState: CGFloat = 0

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
            if model.showThumbnails {
                thumbnailsView
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
    }

    @State var page = 0

    private var mainImageView: some View {
        let overlayAlignment = indicatorOverlayAlignment(for: breakpointIndex)
        let width = galleryWidth

        return ZStack {
            imageViewComponent(for: model.images[0], styleBinding: $styleState).opacity(0.0)
            HSPageView(page: $page, pages: model.images.count) {
                ForEach(0..<model.images.count, id: \.self) { index in
                    imageViewComponent(for: model.images[index], styleBinding: $styleState)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .overlay(alignment: overlayAlignment) {
            indicatorOverlay(alignment: overlayAlignment)
        }
        .animation(carouselAnimation, value: dragState)
        .onChange(of: page) { newValue in
            model.selectedIndex = newValue
        }
    }

    private var thumbnailsView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: rowPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems),
                       spacing: CGFloat(containerStyle?.gap ?? 8)) {
                    ForEach(Array(model.images.enumerated()), id: \.element.id) { index, imageViewModel in
                        let isSelected = index == model.selectedIndex
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
                            background: model.backgroundForThumbnail(
                                state: styleState,
                                breakpointIndex: breakpointIndex
                            ),
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
                        .id(index)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                model.selectImage(at: index)
                                scrollToThumbnail(at: index, proxy: scrollProxy)
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalInset)
            }
            .onChange(of: model.selectedIndex) { newIndex in
                scrollToThumbnail(at: newIndex, proxy: scrollProxy)
            }
        }
    }

    private func indicatorOverlayAlignment(for breakpointIndex: Int) -> Alignment {
        guard let alignSelf = model.indicatorAlignSelf(for: breakpointIndex) else {
            return .bottom
        }
        let horizontal = HorizontalAlignment.center
        let vertical = alignSelf.asVerticalAlignment.asVerticalType ?? .bottom
        return Alignment(horizontal: horizontal, vertical: vertical)
    }

    @ViewBuilder
    private func indicatorOverlay(alignment: Alignment) -> some View {
        if model.showIndicator,
           let containerViewModel = model.indicatorContainerViewModel(for: breakpointIndex) {
            RowComponent(
                config: config,
                model: containerViewModel,
                parentWidth: $availableWidth,
                parentHeight: $availableHeight,
                styleState: .constant(.default),
                parentOverride: ComponentParentOverride(
                    parentVerticalAlignment: alignment.asVerticalType ?? .center,
                    parentHorizontalAlignment: alignment.asHorizontalType ?? .center,
                    parentBackgroundStyle: passableBackgroundStyle,
                    stretchChildren: false
                )
            )
        }
    }

    private var horizontalInset: CGFloat {
        guard let padding = spacingStyle?.padding else { return 0 }
        let frame = FrameAlignmentProperty.getFrameAlignment(padding)
        return CGFloat(frame.left + frame.right)/2
    }

    private func scrollToThumbnail(at index: Int, proxy: ScrollViewProxy) {
        withAnimation(.easeInOut) {
            proxy.scrollTo(index, anchor: .center)
        }
    }

    private func imageViewComponent(for viewModel: DataImageViewModel,
                                    styleBinding: Binding<StyleState>) -> some View {
        DataImageViewComponent(
            config: config.updateParent(.column),
            model: viewModel,
            parentWidth: $availableWidth,
            parentHeight: $availableHeight,
            styleState: styleBinding,
            parentOverride: ComponentParentOverride(
                parentVerticalAlignment: .center,
                parentHorizontalAlignment: .center,
                parentBackgroundStyle: passableBackgroundStyle,
                stretchChildren: false
            ),
            expandsToContainerOnSelfAlign: false
        )
    }

    private var carouselAnimation: Animation {
        .interactiveSpring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.15)
    }

    private var galleryWidth: CGFloat {
        max(availableWidth ?? parentWidth ?? UIScreen.main.bounds.width, 1)
    }
}
