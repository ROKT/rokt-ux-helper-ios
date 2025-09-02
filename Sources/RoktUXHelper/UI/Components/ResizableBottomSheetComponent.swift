//
//  ResizableBottomSheetComponent.swift
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
struct ResizableBottomSheetComponent: View {
    private let maximumOverDrag = 200.0

    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.safeAreaInsets.top ?? 0
    }

    private var bottomSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.safeAreaInsets.bottom ?? 0
    }

    @SwiftUI.Environment(\.colorScheme) var colorScheme

    let model: BottomSheetViewModel
    let onSizeChange: ((CGFloat) -> Void)?
    var style: BottomSheetStyles? {
        model.defaultStyle?.count ?? -1 > breakpointIndex ? model.defaultStyle?[breakpointIndex] : nil
    }

    @State var breakpointIndex = 0
    @State var lastUpdatedHeight: CGFloat = 0

    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?

    @StateObject var globalScreenSize = GlobalScreenSize()

    @State var minimized: Bool

    // New state variables for styling and movement
    @State private var cornerRadius: CGFloat = 0

    @State private var isClosing = false
    @State private var backgroundAlpha: Double = 0.4

    @State private var isDragging = false
    @State private var defaultVerticalOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var bottomSheetTopYPos: CGFloat = 0

    init(model: BottomSheetViewModel, onSizeChange: ((CGFloat) -> Void)?) {
        self.model = model
        self.onSizeChange = onSizeChange
        self.minimized = model.startMinimized

        // Initialize corner radius from model
        if let defaultStyle = model.defaultStyle,
           !defaultStyle.isEmpty,
           let borderRadius = defaultStyle[0].border?.borderRadius {
            self._cornerRadius = State(initialValue: CGFloat(borderRadius))
        }
    }

    var body: some View {
        ZStack {
            // iOS modal background layer - only show when not minimized
            if !minimized {
                Color.black.opacity(backgroundAlpha)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if model.allowBackdropToClose ?? false {
                            close()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 40, height: 4)
                    )
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { value in
                                isDragging = true
                                dragOffset = value.translation.height

                                if dragOffset < -(maximumOverDrag - bottomSafeArea) {
                                    bottomSheetTopYPos = defaultVerticalOffset - (maximumOverDrag - bottomSafeArea)
                                } else {
                                    bottomSheetTopYPos = defaultVerticalOffset + dragOffset
                                }
                            }
                            .onEnded { _ in
                                isDragging = false

                                withAnimation(.easeOut(duration: 0.2)) {
                                    bottomSheetTopYPos = defaultVerticalOffset
                                    dragOffset = 0
                                }
                            }
                    )

                OuterLayerComponent(layouts: model.children,
                                    style: StylingPropertiesModel(
                                        container: style?.container,
                                        background: nil,
                                        dimension: updateBottomSheetHeight(dimension: style?.dimension),
                                        flexChild: style?.flexChild,
                                        spacing: style?.spacing,
                                        border: style?.border
                                    ),
                                    layoutState: model.layoutState,
                                    eventService: model.eventService,
                                    parentWidth: $availableWidth,
                                    parentHeight: $availableHeight,
                                    onSizeChange: onBottomSheetSizeChange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .readSize(spacing: style?.spacing) { size in
                    availableWidth = size.width
                    availableHeight = size.height

                    // 0 at the start
                    globalScreenSize.width = size.width
                    globalScreenSize.height = size.height
                }
                .environmentObject(globalScreenSize)
                .onChange(of: globalScreenSize.width) { newSize in
                    // run it in background thread for smooth transition
                    DispatchQueue.background.async {
                        breakpointIndex = model.updateBreakpointIndex(for: newSize)
                    }
                }

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: maximumOverDrag)
            }
            .ignoresSafeArea(.all, edges: [.top, .bottom])
            .bounceBasedOnSize()
            .background(backgroundStyle: style?.background, imageLoader: model.imageLoader)
            .clipShape(
                RoundedCorner(radius: cornerRadius, corners: [.topLeft, .topRight])
            )
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: bottomSheetTopYPos)
        }
        .onLoad {
            model.onClose = close
            model.setupLayoutState()
        }
    }

    private func close() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isClosing = true
            bottomSheetTopYPos += (availableHeight ?? UIScreen.main.bounds.height)
            backgroundAlpha = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.model.onCleanup?()
        }
    }

    func onBottomSheetSizeChange(newHeight: CGFloat) {
        lastUpdatedHeight = newHeight

        let screenHeight = UIScreen.main.bounds.height - topSafeArea - bottomSafeArea - 30

        defaultVerticalOffset = screenHeight - lastUpdatedHeight
        bottomSheetTopYPos = defaultVerticalOffset

        // Update this to emit the size required by the overlay - may be best to emit y offset
        onSizeChange?(UIScreen.main.bounds.height)
    }

    // BottomSheet height has to be wrapContent
    private func updateBottomSheetHeight(dimension: DimensionStylingProperties?) -> DimensionStylingProperties? {
        guard let dimension, dimension.height != nil else { return dimension }

            return DimensionStylingProperties(minWidth: dimension.minWidth,
                                              maxWidth: dimension.maxWidth,
                                              width: dimension.width,
                                              minHeight: dimension.minHeight,
                                              maxHeight: dimension.maxHeight,
                                              height: .fit(.wrapContent),
                                              rotateZ: dimension.rotateZ)
    }
}

// MARK: - Custom Shapes

@available(iOS 15, *)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
