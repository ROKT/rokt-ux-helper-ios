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
import Combine
import DcuiSchema
import UIKit

private final class FrameObserverView: UIView {
    var onFrameChange: ((CGRect) -> Void)?
    private var lastFrame: CGRect = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview = superview else { return }
        let convertedFrame = superview.convert(bounds, to: nil)
        guard convertedFrame != lastFrame else { return }
        lastFrame = convertedFrame
        onFrameChange?(convertedFrame)
    }
}

private struct ViewFrameReader: UIViewRepresentable {
    let onChange: (CGRect) -> Void

    func makeUIView(context: Context) -> FrameObserverView {
        let view = FrameObserverView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.onFrameChange = onChange
        return view
    }

    func updateUIView(_ uiView: FrameObserverView, context: Context) {
        uiView.onFrameChange = onChange
    }

    static func dismantleUIView(_ uiView: FrameObserverView, coordinator: ()) {
        uiView.onFrameChange = nil
    }
}

@available(iOS 15, *)
struct CatalogDropdownComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var style: CatalogDropdownStyles? {
        style(for: styleState,
              defaultStyles: model.defaultStyle,
              pressedStyles: model.pressedStyle)
    }

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex: Int = 0
    @State var frameChangeIndex: Int = 0
    @State private var dropdownFrameChangeIndex: Int = 0

    var containerStyle: ContainerStylingProperties? { style?.container }
    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    var borderStyle: BorderStylingProperties? { style?.border }
    var spacingStyle: SpacingStylingProperties? { style?.spacing }
    var backgroundStyle: BackgroundStylingProperties? { style?.background }
    var dropdownListContainerStyle: CatalogDropdownStyles? {
        style(for: styleState,
              defaultStyles: model.dropDownListContainerDefaultStyle,
              pressedStyles: model.dropDownListContainerPressedStyle)
    }
    var dropdownListContainerContainerStyle: ContainerStylingProperties? { dropdownListContainerStyle?.container }
    var dropdownListContainerDimensionStyle: DimensionStylingProperties? { dropdownListContainerStyle?.dimension }
    var dropdownListContainerFlexStyle: FlexChildStylingProperties? { dropdownListContainerStyle?.flexChild }
    var dropdownListContainerBorderStyle: BorderStylingProperties? { dropdownListContainerStyle?.border }
    var dropdownListContainerSpacingStyle: SpacingStylingProperties? { dropdownListContainerStyle?.spacing }
    var dropdownListContainerBackgroundStyle: BackgroundStylingProperties? { dropdownListContainerStyle?.background }
    private var validationFieldKey: String? { model.validatorFieldKey }
    private var validatorRules: [CatalogDropDownValidators] { model.validatorRules }
    private var shouldValidateOnChange: Bool { model.validateOnChange }

    let config: ComponentConfig
    let model: CatalogDropdownViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState
    @State var isHovered: Bool = false
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?
    @State private var isExpanded: Bool = false
    @State private var selectedItemIndex: Int?
    @State private var isPressed: Bool = false
    @State private var isDisabled: Bool = false
    @State private var buttonFrameInGlobal: CGRect = .zero
    @State private var showValidationError: Bool = false
    @State private var isValidatorRegistered: Bool = false

    let parentOverride: ComponentParentOverride?

    var passableBackgroundStyle: BackgroundStylingProperties? {
        backgroundStyle ?? parentOverride?.parentBackgroundStyle
    }

    private var dropdownPassableBackgroundStyle: BackgroundStylingProperties? {
        dropdownListContainerBackgroundStyle ?? passableBackgroundStyle
    }

    private var dropdownParentOverride: ComponentParentOverride? {
        mergedParentOverride(
            base: parentOverride?.updateBackground(dropdownPassableBackgroundStyle),
            container: dropdownListContainerContainerStyle,
            background: dropdownListContainerBackgroundStyle
        )
    }

    private var dropdownMinimumWidth: CGFloat? {
        guard dropdownListContainerDimensionStyle?.width == nil,
              dropdownListContainerDimensionStyle?.minWidth == nil else {
            return nil
        }

        return max(availableWidth ?? 200, 200)
    }

    private var availableWidthBinding: Binding<CGFloat?> {
        Binding(
            get: { availableWidth },
            set: { _ in }
        )
    }

    private var availableHeightBinding: Binding<CGFloat?> {
        Binding(
            get: { availableHeight },
            set: { _ in }
        )
    }

    private func mergedParentOverride(
        base: ComponentParentOverride?,
        container: ContainerStylingProperties?,
        background: BackgroundStylingProperties?
    ) -> ComponentParentOverride? {
        if container == nil && background == nil {
            return base
        }

        return ComponentParentOverride(
            parentVerticalAlignment: container.flatMap {
                columnPrimaryAxisAlignment(justifyContent: $0.justifyContent).asVerticalType
            } ?? base?.parentVerticalAlignment,
            parentHorizontalAlignment: container.flatMap {
                columnPerpendicularAxisAlignment(alignItems: $0.alignItems)
            } ?? base?.parentHorizontalAlignment,
            parentBackgroundStyle: background ?? base?.parentBackgroundStyle,
            stretchChildren: container?.alignItems == .stretch
        )
    }

    private func style(
        for state: StyleState,
        defaultStyles: [CatalogDropdownStyles]?,
        pressedStyles: [CatalogDropdownStyles]?
    ) -> CatalogDropdownStyles? {
        let index = breakpointIndex
        switch state {
        case .pressed:
            return pressedStyles?[safe: index] ?? defaultStyles?[safe: index]
        default:
            return defaultStyles?[safe: index]
        }
    }

    private func dropdownItemStyle(isSelected: Bool) -> CatalogDropdownStyles? {
        if isSelected,
           let selectedStyle = style(for: styleState,
                                     defaultStyles: model.dropDownSelectedItemDefaultStyle,
                                     pressedStyles: model.dropDownSelectedItemPressedStyle) {
            return selectedStyle
        }

        return style(for: styleState,
                     defaultStyles: model.dropDownListItemDefaultStyle,
                     pressedStyles: model.dropDownListItemPressedStyle)
    }

    private func verticalAlignment(for container: ContainerStylingProperties?) -> VerticalAlignmentProperty {
        if let justifyContent = container?.justifyContent?.asVerticalAlignmentProperty {
            return justifyContent
        }
        return .top
    }

    private func horizontalAlignment(for container: ContainerStylingProperties?) -> HorizontalAlignmentProperty {
        if let alignItems = container?.alignItems?.asHorizontalAlignmentProperty {
            return alignItems
        }
        return .start
    }

    private func registerValidatorIfNeeded() {
        guard !isValidatorRegistered,
              let key = validationFieldKey,
              let layoutState = model.layoutState,
              !validatorRules.isEmpty else {
            return
        }

        layoutState.validationCoordinator.registerField(
            key: key,
            owner: self.model,
            validation: { validateSelectionStatus() },
            onStatusChange: { status in
                showValidationError = status == .invalid
            }
        )

        isValidatorRegistered = true
        showValidationError = false
    }

    private func unregisterValidator() {
        guard isValidatorRegistered,
              let key = validationFieldKey,
              let layoutState = model.layoutState else {
            showValidationError = false
            return
        }

        layoutState.validationCoordinator.unregisterField(for: key, owner: self.model)
        isValidatorRegistered = false
        showValidationError = false
    }

    private func notifyValidationOfSelectionChange() {
        guard isValidatorRegistered,
              let key = validationFieldKey,
              let layoutState = model.layoutState else { return }

        if shouldValidateOnChange || showValidationError {
            layoutState.validationCoordinator.validate(field: key)
        }
    }

    private func validateSelectionStatus() -> ValidationStatus {
        guard !validatorRules.isEmpty else { return .valid }

        for rule in validatorRules {
            switch rule {
            case .required:
                if persistedSelectedIndex == nil {
                    return .invalid
                }
            }
        }

        return .valid
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

    private var dropdownContainerVerticalAlignment: VerticalAlignmentProperty {
        if let justifyContent = dropdownListContainerContainerStyle?.justifyContent?.asVerticalAlignmentProperty {
            return justifyContent
        }

        return .top
    }

    private var dropdownContainerHorizontalAlignment: HorizontalAlignmentProperty {
        if let alignItems = dropdownListContainerContainerStyle?.alignItems?.asHorizontalAlignmentProperty {
            return alignItems
        }

        return .start
    }

    private var layoutItemsPublisher: AnyPublisher<[String: Any], Never> {
        model.layoutState?
            .itemsPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
        ?? Empty<[String: Any], Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    var body: some View {
        let base = dropdownButton()
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
                DispatchQueue.background.async {
                    breakpointIndex = model.updateBreakpointIndex(for: newSize)
                    frameChangeIndex += 1
                    dropdownFrameChangeIndex += 1
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
            .onReceive(layoutItemsPublisher) { _ in
                syncSelectedItemFromLayoutState()
            }
        return base
            .overlay(alignment: .topLeading) {
                if isExpanded, buttonFrameInGlobal != .zero {
                    expandedOverlayView()
                        .transition(.opacity)
                }
            }
            .zIndex(isExpanded ? 1000 : 0)
    }

    private func dropdownButton() -> some View {
        VStack(
            alignment: columnPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems),
            spacing: CGFloat(containerStyle?.gap ?? 0)
        ) {
            dropdownButtonPrimaryContent()
            validationErrorView()
        }
        .onAppear {
            registerValidatorIfNeeded()
            syncSelectedItemFromLayoutState()
        }
        .onDisappear {
            unregisterValidator()
        }
    }

    @ViewBuilder
    private func dropdownButtonPrimaryContent() -> some View {
        if hasPersistedSelection,
           selectedItemIndex != nil,
           let closedTemplate = model.closedTemplate {
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

    @ViewBuilder
    private func validationErrorView() -> some View {
        if showValidationError,
           let errorTemplate = model.requiredSelectionErrorTemplate {
            LayoutSchemaComponent(
                config: config,
                layout: errorTemplate,
                parentWidth: $parentWidth,
                parentHeight: $parentHeight,
                styleState: $styleState,
                parentOverride: parentOverride
            )
        }
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
        .onTapGesture(perform: tapHandler)
        .background(
            ViewFrameReader { frame in
                guard frame != .zero else { return }
                DispatchQueue.main.async {
                    if buttonFrameInGlobal != frame {
                        buttonFrameInGlobal = frame
                    }
                }
            }
        )
    }

    @ViewBuilder
    private func dropdownItemView(for index: Int) -> some View {
        let isSelected = persistedSelectedIndex == index
        let itemStyle = dropdownItemStyle(isSelected: isSelected)
        let itemContainerStyle = itemStyle?.container
        let itemDimensionStyle = itemStyle?.dimension
        let itemFlexStyle = itemStyle?.flexChild
        let itemBorderStyle = itemStyle?.border
        let itemSpacingStyle = itemStyle?.spacing
        let itemBackgroundStyle = itemStyle?.background
        let itemParentOverride = mergedParentOverride(base: dropdownParentOverride,
                                                      container: itemContainerStyle,
                                                      background: itemBackgroundStyle)

        LayoutSchemaComponent(
            config: config.updateParent(.column),
            layout: model.openDropdownChildren[index],
            parentWidth: $parentWidth,
            parentHeight: $parentHeight,
            styleState: $styleState,
            parentOverride: itemParentOverride
        )
        .applyLayoutModifier(
            verticalAlignmentProperty: verticalAlignment(for: itemContainerStyle),
            horizontalAlignmentProperty: horizontalAlignment(for: itemContainerStyle),
            spacing: itemSpacingStyle,
            dimension: itemDimensionStyle,
            flex: itemFlexStyle,
            border: itemBorderStyle,
            background: itemBackgroundStyle,
            container: itemContainerStyle,
            parent: .column,
            parentWidth: availableWidthBinding,
            parentHeight: availableHeightBinding,
            parentOverride: itemParentOverride,
            defaultHeight: .wrapContent,
            defaultWidth: .wrapContent,
            isContainer: true,
            containerType: .column,
            frameChangeIndex: .constant(0),
            imageLoader: model.imageLoader
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func expandedDropdown() -> some View {
        VStack(
            alignment: columnPerpendicularAxisAlignment(alignItems: dropdownListContainerContainerStyle?.alignItems),
            spacing: CGFloat(dropdownListContainerContainerStyle?.gap ?? 0)
        ) {
            if !model.openDropdownChildren.isEmpty {
                ForEach(0..<model.openDropdownChildren.count, id: \.self) { index in
                    Button {
                        selectItem(at: index)
                    } label: {
                        dropdownItemView(for: index)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .applyLayoutModifier(
            verticalAlignmentProperty: dropdownContainerVerticalAlignment,
            horizontalAlignmentProperty: dropdownContainerHorizontalAlignment,
            spacing: dropdownListContainerSpacingStyle,
            dimension: dropdownListContainerDimensionStyle,
            flex: dropdownListContainerFlexStyle,
            border: dropdownListContainerBorderStyle,
            background: dropdownListContainerBackgroundStyle,
            container: dropdownListContainerContainerStyle,
            parent: config.parent,
            parentWidth: $parentWidth,
            parentHeight: $parentHeight,
            parentOverride: dropdownParentOverride,
            defaultHeight: .wrapContent,
            defaultWidth: .wrapContent,
            isContainer: true,
            containerType: .column,
            frameChangeIndex: $dropdownFrameChangeIndex,
            imageLoader: model.imageLoader
        )
        .ifLet(dropdownMinimumWidth) { view, minWidth in
            view.frame(minWidth: minWidth, alignment: .leading)
        }
    }

    @ViewBuilder
    private func expandedOverlayView() -> some View {
        let overlayWidth = globalScreenSize.width ?? UIScreen.main.bounds.width
        let overlayHeight = globalScreenSize.height ?? UIScreen.main.bounds.height
        ZStack(alignment: .topLeading) {
            expandedBackground()
                .frame(width: overlayWidth,
                       height: overlayHeight,
                       alignment: .topLeading)
            expandedDropdown()
                .offset(x: buttonFrameInGlobal.minX,
                        y: buttonFrameInGlobal.maxY)
        }
        .frame(width: overlayWidth,
               height: overlayHeight,
               alignment: .topLeading)
        .offset(x: -buttonFrameInGlobal.minX,
                y: -buttonFrameInGlobal.minY)
        .ignoresSafeArea()
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

    private func selectItem(at index: Int) {
        guard index >= 0,
              index < model.openDropdownChildren.count else { return }

        selectedItemIndex = index
        isExpanded = false
        persistSelectedIndex(index)

        guard index < model.catalogItems.count else { return }
        let selectedItem = model.catalogItems[index]
        model.layoutState?.items[LayoutState.activeCatalogItemKey] = selectedItem
        model.layoutState?.publishStateChange()
        notifyValidationOfSelectionChange()
    }

    private func syncSelectedItemFromLayoutState() {
        if let persistedIndex = persistedSelectedIndex {
            guard persistedIndex >= 0, persistedIndex < model.catalogItems.count else {
                persistSelectedIndex(nil)
                if selectedItemIndex != nil {
                    selectedItemIndex = nil
                    notifyValidationOfSelectionChange()
                }
                return
            }

            if selectedItemIndex != persistedIndex {
                selectedItemIndex = persistedIndex
                notifyValidationOfSelectionChange()
            }
            return
        }

        guard let activeItem = model.layoutState?.items[LayoutState.activeCatalogItemKey] as? CatalogItem else {
            if selectedItemIndex != nil {
                selectedItemIndex = nil
                notifyValidationOfSelectionChange()
            }
            return
        }

        if let currentIndex = selectedItemIndex,
           currentIndex < model.catalogItems.count,
           model.catalogItems[currentIndex].catalogItemId == activeItem.catalogItemId {
            return
        }

        if let index = model.catalogItems.firstIndex(where: { $0.catalogItemId == activeItem.catalogItemId }) {
            selectedItemIndex = index
            notifyValidationOfSelectionChange()
        } else {
            if selectedItemIndex != nil {
                selectedItemIndex = nil
                notifyValidationOfSelectionChange()
            }
        }
    }

    private var hasPersistedSelection: Bool {
        persistedSelectedIndex != nil
    }

    private var dropdownStateKey: String {
        if let position = config.position {
            return "dropdown-\(position)"
        }
        return model.id.uuidString
    }

    private var persistedSelectedIndex: Int? {
        guard let layoutState = model.layoutState else { return nil }
        let selections = layoutState.items[LayoutState.catalogDropdownSelectedIndexKey] as? [String: Int]
        return selections?[dropdownStateKey]
    }

    private func persistSelectedIndex(_ index: Int?) {
        guard let layoutState = model.layoutState else { return }

        var items = layoutState.items
        var selections = items[LayoutState.catalogDropdownSelectedIndexKey] as? [String: Int] ?? [:]

        if let index {
            selections[dropdownStateKey] = index
        } else {
            selections.removeValue(forKey: dropdownStateKey)
        }

        if selections.isEmpty {
            items.removeValue(forKey: LayoutState.catalogDropdownSelectedIndexKey)
        } else {
            items[LayoutState.catalogDropdownSelectedIndexKey] = selections
        }

        layoutState.items = items
    }
}
