//
//  OneByOneComponent.swift
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
struct OneByOneComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var style: OneByOneDistributionStyles? {
        return model.defaultStyle?.count ?? -1 > breakpointIndex ? model.defaultStyle?[breakpointIndex] : nil
    }

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex = 0
    @State var frameChangeIndex: Int = 0

    var containerStyle: ContainerStylingProperties? { style?.container }
    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    var borderStyle: BorderStylingProperties? { style?.border }
    var spacingStyle: SpacingStylingProperties? { style?.spacing }
    var backgroundStyle: BackgroundStylingProperties? { style?.background }

    var transition: DcuiSchema.Transition? { model.transition }

    let config: ComponentConfig
    let model: OneByOneViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState

    @State var currentOffer: Int
    @State private var toggleTransition = false
    @State var customStateMap: RoktUXCustomStateMap?

    @AccessibilityFocusState private var shouldFocusAccessibility: Bool
    var accessibilityAnnouncement: String {
        String(format: kOneByOneAnnouncement,
               currentOffer + 1,
               model.children?.count ?? 1)
    }

    let parentOverride: ComponentParentOverride?

    var passableBackgroundStyle: BackgroundStylingProperties? {
        backgroundStyle ?? parentOverride?.parentBackgroundStyle
    }

    init(
        config: ComponentConfig,
        model: OneByOneViewModel,
        parentWidth: Binding<CGFloat?>,
        parentHeight: Binding<CGFloat?>,
        styleState: Binding<StyleState>,
        parentOverride: ComponentParentOverride?
    ) {
        self.config = config
        _parentWidth = parentWidth
        _parentHeight = parentHeight
        _styleState = styleState

        self.parentOverride = parentOverride
        self.model = model
        _currentOffer = State(wrappedValue: model.initialCurrentIndex ?? 0)
        _customStateMap = State(wrappedValue: model.initialCustomStateMap ?? RoktUXCustomStateMap())
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
        if let children = model.children, !children.isEmpty {
            Group {
                LayoutSchemaComponent(config: config.updatePosition(currentOffer),
                                      layout: children[currentOffer],
                                      parentWidth: $parentWidth,
                                      parentHeight: $parentHeight,
                                      styleState: $styleState,
                                      parentOverride: parentOverride?.updateBackground(passableBackgroundStyle))
                .applyLayoutModifier(verticalAlignmentProperty: verticalAlignment,
                                     horizontalAlignmentProperty: horizontalAlignment,
                                     spacing: spacingStyle,
                                     dimension: dimensionStyle,
                                     flex: flexStyle,
                                     border: borderStyle,
                                     background: backgroundStyle,
                                     parent: config.parent,
                                     parentWidth: $parentWidth,
                                     parentHeight: $parentHeight,
                                     parentOverride: parentOverride?.updateBackground(passableBackgroundStyle),
                                     defaultHeight: .wrapContent,
                                     defaultWidth: .wrapContent,
                                     isContainer: true,
                                     frameChangeIndex: $frameChangeIndex,
                                     imageLoader: model.imageLoader)
                .opacity(getOpacity())
                .onLoad {
                    registerActions()
                    toggleTransition = true
                    model.sendImpressionEvents(currentOffer: currentOffer)
                    shouldFocusAccessibility = true
                }
                .onChange(of: currentOffer) { newValue in
                    model.layoutState?.capturePluginViewState(offerIndex: newValue, dismiss: false)
                    transitionIn()
                    model.sendImpressionEvents(currentOffer: newValue)
                    shouldFocusAccessibility = true
                    UIAccessibility.post(notification: .announcement,
                                         argument: accessibilityAnnouncement)
                }
                .onChange(of: customStateMap) { _ in
                    model.layoutState?.capturePluginViewState(offerIndex: nil, dismiss: false)
                }
                .onChange(of: globalScreenSize.width) { newSize in
                    // run it in background thread for smooth transition
                    DispatchQueue.background.async {
                        breakpointIndex = model.updateBreakpointIndex(for: newSize)
                        frameChangeIndex += 1
                    }
                }
                .onBecomingViewed(currentOffer: currentOffer) {
                    model.sendCreativeViewedEvent(currentOffer: currentOffer)
                }
                .onUserInteraction {
                    model.sendCreativeViewedEvent(currentOffer: currentOffer)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityFocused($shouldFocusAccessibility)
            .accessibilityLabel(accessibilityAnnouncement)
        }
    }

    func registerActions() {
        model.layoutState?.actionCollection[.nextOffer] = goToNextOffer
        model.layoutState?.actionCollection[.toggleCustomState] = toggleCustomState
        model.setupBindings(
            currentProgess: $currentOffer,
            customStateMap: $customStateMap,
            totalItems: model.children?.count ?? 0
        )
    }

    func goToNextOffer(_: Any? = nil) {
        if currentOffer + 1 < model.children?.count ?? 0 {
            transitionToNextOffer()
        } else if model.layoutState?.closeOnComplete() == true {
            // when on last offer AND closeOnComplete is true
            if case .embeddedLayout = model.layoutState?.layoutType() {
                model.sendDismissalCollapsedEvent()
            } else {
                model.sendDismissalNoMoreOfferEvent()
            }

            exit()
        }
    }

    func exit() {
        model.layoutState?.actionCollection[.close](nil)
    }

    func transitionIn() {
        switch transition {
        case .fadeInOut(let settings):
            let duration = Double(settings.duration)/1000/2
            withAnimation(
                .easeIn(duration: Double(duration))
            ) {
                toggleTransition = true
            }
        default:
            return
        }
    }

    func transitionToNextOffer() {
        switch transition {
        case .fadeInOut(let settings):
            let duration = Double(settings.duration)/1000/2
            withAnimation(.easeOut(duration: duration)) {
                toggleTransition = false
            }

            // Wait to complete fade out of previous offer
            // Must not run on `main` as that prevents `@State` from changing
            DispatchQueue.background.asyncAfter(deadline: .now() + duration) {
                self.customStateMap = RoktUXCustomStateMap()
                self.currentOffer = currentOffer + 1
            }
        default:
            self.customStateMap = RoktUXCustomStateMap()
            self.currentOffer = currentOffer + 1
        }
    }

    private func toggleCustomState(_ customStateId: Any?) {
        var mutatingCustomStateMap: RoktUXCustomStateMap = customStateMap ?? RoktUXCustomStateMap()
        self.customStateMap = mutatingCustomStateMap.toggleValueFor(customStateId)
        model.publishStateChange()
    }

    func getOpacity() -> Double {
        switch transition {
        case .fadeInOut:
            return toggleTransition ? 1 : 0
        default:
            return 1
        }
    }
}
