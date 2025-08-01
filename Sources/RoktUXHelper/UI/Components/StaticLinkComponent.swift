//
//  StaticLinkComponent.swift
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
struct StaticLinkComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var containerStyle: ContainerStylingProperties? { style?.container }
    var backgroundStyle: BackgroundStylingProperties? { style?.background }
    var borderStyle: BorderStylingProperties? { style?.border }
    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    var spacingStyle: SpacingStylingProperties? { style?.spacing }

    let config: ComponentConfig
    let model: StaticLinkViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?
    @State var styleState: StyleState = .default
    @State var isHovered: Bool = false
    @State var isPressed: Bool = false
    @State var isDisabled: Bool = false

    @GestureState private var isPressingDown: Bool = false

    var style: StaticLinkStyles? {
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
    @State var breakpointIndex = 0
    @State var frameChangeIndex: Int = 0

    let parentOverride: ComponentParentOverride?

    var passableBackgroundStyle: BackgroundStylingProperties? {
        backgroundStyle ?? parentOverride?.parentBackgroundStyle
    }

    var verticalAlignmentOverride: VerticalAlignment? {
        return containerStyle?.justifyContent?.asVerticalAlignment.vertical
    }
    var horizontalAlignmentOverride: HorizontalAlignment? {
        return containerStyle?.alignItems?.asHorizontalAlignment.horizontal
    }

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
        build()
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
                verticalAlignmentOverride: verticalAlignmentOverride,
                horizontalAlignmentOverride: horizontalAlignmentOverride,
                defaultHeight: .wrapContent,
                defaultWidth: .wrapContent,
                isContainer: true,
                containerType: .row,
                applyAlignSelf: false,
                applyMargin: false,
                frameChangeIndex: $frameChangeIndex,
                imageLoader: model.imageLoader
            )

            // contentShape extends tappable area outside of children
            .contentShape(Rectangle())
            // alignSelf must apply after the touchable area
            .alignSelf(alignSelf: flexStyle?.alignSelf,
                       parent: config.parent,
                       parentHeight: parentHeight,
                       parentWidth: parentWidth,
                       parentVerticalAlignment: parentOverride?.parentVerticalAlignment,
                       parentHorizontalAlignment: parentOverride?.parentHorizontalAlignment,
                       applyAlignSelf: true)
            // margin must apply after the touchable area and before readSize
            .margin(spacing: spacingStyle, applyMargin: true)
            .readSize(spacing: spacingStyle) { size in
                availableWidth = size.width
                availableHeight = size.height
            }
            .onTapGesture {
                model.handleLink()
            }
            // consecutive gestures to track when long press is held vs released
            .gesture(LongPressGesture()
                .sequenced(before: LongPressGesture(minimumDuration: .infinity))
                .updating($isPressingDown) { value, state, _ in
                    switch value {
                    case .second(true, nil):
                        state = true
                    default:
                        break
                    }
                })
            .onChange(of: isPressingDown) { value in
                if !value {
                    // handle link when long press is released
                    model.handleLink()
                }
            }
            .onLongPressGesture(perform: {
            }, onPressingChanged: { isPressed in
                self.isPressed = isPressed
                updateStyleState()
            })
            .accessibilityAddTraits(.isLink)
    }

    func build() -> some View {
        createContainer()
            .onChange(of: globalScreenSize.width) { newSize in
                // run it in background thread for smooth transition
                DispatchQueue.background.async {
                    breakpointIndex = model.updateBreakpointIndex(for: newSize)
                    frameChangeIndex += 1
                }
            }
    }

    func createContainer() -> some View {
        return HStack(alignment: rowPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems), spacing: 0) {
            if let children = model.children {
                ForEach(children, id: \.self) { child in
                    LayoutSchemaComponent(
                        config: config.updateParent(.row),
                        layout: child,
                        parentWidth: $availableWidth,
                        parentHeight: $availableHeight,
                        styleState: $styleState,
                        parentOverride:
                            ComponentParentOverride(
                                parentVerticalAlignment: rowPerpendicularAxisAlignment(
                                    alignItems: containerStyle?.alignItems
                                ),
                                parentHorizontalAlignment: rowPrimaryAxisAlignment(
                                    justifyContent: containerStyle?.justifyContent
                                ).asHorizontalType,
                                parentBackgroundStyle: passableBackgroundStyle,
                                stretchChildren: containerStyle?.alignItems == .stretch
                            ),
                        expandsToContainerOnSelfAlign: shouldExpandToContainerOnSelfAlign()
                    )
                }
            }
        }
    }

    // if height = fixed or percentage, we need to allow the children to expand. `expandsToContainerOnSelfAlign` will let them use maxHeight=.infinity
    //   since it will only take up its container's finite heigh
    // if height is not specified or fit, we can't use maxHeight=infinity since it will take up all the remaining space in the screen
    private func shouldExpandToContainerOnSelfAlign() -> Bool {
        guard let heightType = style?.dimension?.height else { return false }

        switch heightType {
        case .fixed, .percentage:
            return true
        default:
            return false
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
}
