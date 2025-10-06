//
//  CatalogDropdownComponent.swift
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
struct CatalogDropdownComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var style: CatalogDropdownStyles? {
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
    let model: CatalogDropdownViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState
    @State var isHovered: Bool = false
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?
    @State private var isExpanded: Bool = false
    @State private var buttonHeight: CGFloat = 0
    @State private var selectedItemIndex: Int?
    @State private var isPressed: Bool = false
    @State private var isDisabled: Bool = false

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

    var body: some View {
        ZStack(alignment: .topLeading) {
            dropdownButton()
                .zIndex(1)

            if isExpanded {
                expandedBackground()
                    .zIndex(0)

                expandedDropdown()
                    .zIndex(2)
            }
        }
        .accessibilityAddTraits(.isButton)
        .onHover { isHovered in
            self.isHovered = isHovered
            updateStyleState()
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
            // run it in background thread for smooth transition
            DispatchQueue.background.async {
                breakpointIndex = model.updateBreakpointIndex(for: newSize)
                frameChangeIndex += 1
            }
        }
        .contentShape(Rectangle())
        .alignSelf(alignSelf: flexStyle?.alignSelf,
                   parent: config.parent,
                   parentHeight: parentHeight,
                   parentWidth: parentWidth,
                   parentVerticalAlignment: parentOverride?.parentVerticalAlignment,
                   parentHorizontalAlignment: parentOverride?.parentHorizontalAlignment,
                   applyAlignSelf: true)
        .margin(spacing: spacingStyle, applyMargin: true)
        .readSize(spacing: spacingStyle) { size in
            availableWidth = size.width
            availableHeight = size.height
        }
    }

    private func dropdownButton() -> some View {
        VStack(
            alignment: columnPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems),
            spacing: CGFloat(containerStyle?.gap ?? 0)
        ) {
            if let selectedIndex = selectedItemIndex, let closedTemplate = model.closedTemplate {
                dropdownButtonContent(
                    layout: closedTemplate,
                    tapHandler: { toggleDropdownExpansion() }
                )
            } else if let closedDefaultTemplate = model.closedDefaultTemplate {
                dropdownButtonContent(
                    layout: closedDefaultTemplate,
                    tapHandler: { toggleDropdownExpansion() }
                )
            }
        }
        .onAppear(perform: syncSelectedItemFromLayoutState)
    }

    private func dropdownButtonContent(
        layout: LayoutSchemaViewModel,
        tapHandler: @escaping () -> Void
    ) -> some View {
        LayoutSchemaComponent(
            config: config,
            layout: layout,
            parentWidth: $parentWidth,
            parentHeight: $parentHeight,
            styleState: $styleState,
            parentOverride: parentOverride
        )
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { updateButtonHeight(with: geometry.size.height) }
                    .onChange(of: geometry.size.height) { updateButtonHeight(with: $0) }
            }
        )
        .onTapGesture(perform: tapHandler)
    }

    @ViewBuilder
    private func expandedDropdown() -> some View {
        VStack(spacing: 0) {
            if !model.openDropdownChildren.isEmpty {
                ForEach(0..<model.openDropdownChildren.count, id: \.self) { index in
                    Button {
                        selectItem(at: index)
                    } label: {
                        LayoutSchemaComponent(
                            config: config,
                            layout: model.openDropdownChildren[index],
                            parentWidth: $parentWidth,
                            parentHeight: $parentHeight,
                            styleState: $styleState,
                            parentOverride: parentOverride
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .frame(minWidth: max(availableWidth ?? 200, 200), alignment: .leading)
        .offset(y: buttonHeight)
    }

    @ViewBuilder
    private func expandedBackground() -> some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .onTapGesture {
                isExpanded = false
            }
    }

    private func updateStyleState() {
      if isDisabled {
          styleState = .disabled
      } else {
          if isPressed {
              styleState = .pressed
          } else if isHovered {
              styleState = .hovered
          } else {
              styleState = .default
          }
      }
    }

    private func toggleDropdownExpansion() {
        isExpanded.toggle()
    }

    private func updateButtonHeight(with height: CGFloat) {
        guard buttonHeight != height else { return }
        buttonHeight = height
    }

    private func selectItem(at index: Int) {
        guard index >= 0,
              index < model.openDropdownChildren.count else { return }

        selectedItemIndex = index
        isExpanded = false

        guard index < model.catalogItems.count else { return }
        let selectedItem = model.catalogItems[index]
        model.layoutState?.items[LayoutState.activeCatalogItemKey] = selectedItem
        print("Selected item with ID: \(selectedItem.catalogItemId) and title: \(selectedItem.title)")
    }

    private func syncSelectedItemFromLayoutState() {
        guard let activeItem = model.layoutState?.items[LayoutState.activeCatalogItemKey] as? CatalogItem else {
            return
        }

        if let currentIndex = selectedItemIndex,
           currentIndex < model.catalogItems.count,
           model.catalogItems[currentIndex].catalogItemId == activeItem.catalogItemId {
            return
        }

        if let index = model.catalogItems.firstIndex(where: { $0.catalogItemId == activeItem.catalogItemId }) {
            selectedItemIndex = index
        }
    }
}
