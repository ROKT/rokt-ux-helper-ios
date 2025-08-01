//
//  CarouselComponent.swift
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
struct CarouselDistributionComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var style: CarouselDistributionStyles? {
        return model.defaultStyle?.count ?? -1 > styleBreakpointIndex ? model.defaultStyle?[styleBreakpointIndex] : nil
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

    let config: ComponentConfig

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState

    @GestureState private var offset: CGFloat = 0

    // states to track paging when we have multiple viewable items
    @ObservedObject private var model: CarouselViewModel

    @State private var carouselHeightMap: [Int: CGFloat] = [:]

    @State var customStateMap: RoktUXCustomStateMap?

    @AccessibilityFocusState private var shouldFocusAccessibility: Bool
    var accessibilityAnnouncement: String {
        String(format: kPageAnnouncement,
               model.currentPage + 1,
               model.totalPages)
    }

    let parentOverride: ComponentParentOverride?

    var passableBackgroundStyle: BackgroundStylingProperties? {
        backgroundStyle ?? parentOverride?.parentBackgroundStyle
    }

    var styleBreakpointIndex: Int {
        let maxStyleIndex = (model.defaultStyle?.count ?? 1) - 1
        return max(min(breakpointIndex, maxStyleIndex), 0)
    }

    var peekThroughBreakpointIndex: Int {
        let maxPeekThroughIndex = (model.peekThroughSize.count) - 1
        return max(min(breakpointIndex, maxPeekThroughIndex), 0)
    }

    init(
        config: ComponentConfig,
        model: CarouselViewModel,
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

    var gap: CGFloat {
        CGFloat(containerStyle?.gap ?? 0)
    }

    var gapOffset: CGFloat {
        getGapOffset()
    }

    var body: some View {
        if model.totalPages > 0 {
            GeometryReader { containerProxy in
                let peekThrough = getPeekThrough(containerProxy.size.width)
                let pageWidth = getPageWidth(width: containerProxy.size.width,
                                             peekThrough: peekThrough)

                let offerWidth = getOfferWidth(pageWidth: pageWidth,
                                               totalOffers: model.totalOffers)

                let peekThroughOffset = getPeekThroughOffset(peekThrough: peekThrough,
                                                             totalPages: model.totalPages)

                let pageOffset = CGFloat(model.currentPage) * -pageWidth
                let indexOffset = CGFloat(model.indexWithinPage) * -offerWidth

                HStack(alignment: rowPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems),
                       spacing: gap) {
                    ForEach(model.pages, id: \.self) { page in
                        HStack(alignment: rowPerpendicularAxisAlignment(alignItems: containerStyle?.alignItems),
                               spacing: gap) {
                            build(page: page,
                                  offerWidth: offerWidth)
                        }
                        .offset(x: (containerProxy.size.width - pageWidth)/2 - peekThrough)
                    }
                }
                .offset(x: pageOffset + indexOffset + offset + peekThroughOffset + gapOffset)
                .gesture(
                    DragGesture()
                        .updating($offset, body: { value, out, _ in
                            out = value.translation.width
                        })
                        .onEnded({ value in
                            let progress = -value.translation.width/offerWidth
                            let roundProgress = Int(progress.rounded())

                            updateStatesOnDragEnded(pages: model.pages,
                                                    roundProgress: roundProgress,
                                                    totalOffers: model.totalOffers,
                                                    totalPages: model.totalPages)
                        })
                )
            }
            .onLoad {
                registerActions()
                shouldFocusAccessibility = true
            }
            .onChange(of: model.currentLeadingOfferIndex) { newValue in
                model.layoutState?.capturePluginViewState(offerIndex: newValue, dismiss: false)
                model.sendViewableImpressionEvents(currentLeadingOffer: newValue)
                shouldFocusAccessibility = true
                UIAccessibility.post(notification: .announcement,
                                     argument: accessibilityAnnouncement)
            }
            .onChange(of: customStateMap) { _ in
                model.layoutState?.capturePluginViewState(offerIndex: nil, dismiss: false)
            }
            .onChange(of: globalScreenSize.width) { newSize in
                DispatchQueue.main.async {
                    // update breakpoint indexes
                    breakpointIndex = model.getGlobalBreakpointIndex(newSize)
                    setViewableItemsForBreakpoint()
                    setRecalculatedCurrentPage()
                    // set viewableItems first then send impressions for offers based on viewableItems
                    // duplicated events will be filtered out
                    model.sendViewableImpressionEvents(currentLeadingOffer: model.currentLeadingOfferIndex)
                    frameChangeIndex += 1
                }
            }
            // workaround to set dynamic height otherwise GeometryReader fills available space
            .frame(height: carouselHeightMap.max(by: {$0.value < $1.value})?.value ?? 0)
        }
    }

    func build(page: [LayoutSchemaViewModel],
               offerWidth: CGFloat) -> some View {
        ForEach(page, id: \.self) { child in
            if let childIndex = model.children?.firstIndex(of: child) {
                LayoutSchemaComponent(config: config.updatePosition(childIndex),
                                      layout: child,
                                      parentWidth: $parentWidth,
                                      parentHeight: $carouselHeightMap[childIndex],
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
                                     containerType: .row,
                                     frameChangeIndex: $frameChangeIndex,
                                     imageLoader: model.imageLoader)
                .frame(width: offerWidth)
                .readSize { size in
                    carouselHeightMap[childIndex] = size.height
                }
                .accessibilityElement(children: .contain)
                .accessibilityFocused($shouldFocusAccessibility)
                .accessibilityLabel(accessibilityAnnouncement)
                .onBecomingViewed { visibilityInfo in
                    if visibilityInfo.isInViewAndCorrectSize {
                        model.sendCreativeViewedEvent(currentOffer: childIndex)
                    }
                }
                .onUserInteraction {
                    model.sendCreativeViewedEvent(currentOffer: childIndex)
                }
            }
        }
    }

    func updateStatesOnDragEnded(pages: [[LayoutSchemaViewModel]],
                                 roundProgress: Int,
                                 totalOffers: Int,
                                 totalPages: Int) {
        if model.viewableItems > 1 {
            let projectedLeadingOffer = model.currentLeadingOfferIndex + roundProgress

            if projectedLeadingOffer + model.viewableItems > totalOffers - 1 {
                // if projected to go above totalOffers, update to last page
                model.currentPage = totalPages - 1
                model.indexWithinPage = pages[model.currentPage].count - model.viewableItems
                model.currentLeadingOfferIndex = totalOffers - model.viewableItems
            } else if projectedLeadingOffer >= 0,
                      model.currentPage <= totalPages - 1 {
                // ensure projectedLeadingOffer above 0 and currentPage below totalPages
                model.currentPage = Int(floor(Double(projectedLeadingOffer/model.viewableItems)))
                model.indexWithinPage = projectedLeadingOffer % model.viewableItems
                model.currentLeadingOfferIndex = projectedLeadingOffer
            }
        } else {
            // ensure currentPage is never below 0 or above totalPages for 1 viewable item
            model.currentPage = max(min(model.currentPage + roundProgress, totalPages - 1), 0)
            model.currentLeadingOfferIndex = model.currentPage
        }
    }

    private func registerActions() {
        model.registerActions()
        model.layoutState?.actionCollection[.toggleCustomState] = toggleCustomState

        model.setupBindings(
            currentProgress: $model.currentPage,
            totalItems: model.children?.count ?? 0,
            viewableItems: $model.viewableItems,
            customStateMap: $customStateMap
        )
    }

    func getGapOffset() -> CGFloat {
        // This calculates the gap offset to add on each drag end
        guard model.currentLeadingOfferIndex != 0, gap != 0 else { return 0 }
        if model.currentPage == model.totalPages - 1 {
            return gap - gap * CGFloat(model.indexWithinPage)
        } else {
            return gap/2 - gap * CGFloat(model.indexWithinPage)
        }
    }

    func getPeekThrough(_ width: CGFloat) -> CGFloat {
        let breakPointPeekThrough = model.peekThroughSize[peekThroughBreakpointIndex]

        // convert PeekThroughSize to actual width
        switch breakPointPeekThrough {
        case .fixed(let peekthrough):
            return CGFloat(peekthrough)
        case .percentage(let percentage):
            return width * CGFloat(percentage/100)
        }
    }

    func getPageWidth(width: CGFloat,
                      peekThrough: CGFloat) -> CGFloat {
        return width - peekThrough * 2
    }

    func getOfferWidth(pageWidth: CGFloat,
                       totalOffers: Int) -> CGFloat {
        return model.viewableItems > 1 && totalOffers > 1
        ? pageWidth/CGFloat(model.viewableItems) - gap
            : pageWidth - gap
    }

    func getPeekThroughOffset(peekThrough: CGFloat,
                              totalPages: Int) -> CGFloat {
        // This calculates the offset we require to apply peek through logic:
        // 1. 1st offer has trailing peek through width=peekThrough*2
        // 2. Last offer has leading peek through width=peekThrough*2
        // 3. In-between offers have both leading and trailing peek through width=peekThrough
        if model.viewableItems > 1 {
            return model.currentLeadingOfferIndex == 0 ? 0 : (model.currentPage == totalPages - 1 ? peekThrough * 2 : peekThrough)
        } else {
            return model.currentPage == 0 ? 0 : (model.currentPage == totalPages - 1 ? peekThrough * 2 : peekThrough)
        }
    }

    private func toggleCustomState(_ customStateId: Any?) {
        var mutatingCustomStateMap: RoktUXCustomStateMap = customStateMap ?? RoktUXCustomStateMap()
        self.customStateMap = mutatingCustomStateMap.toggleValueFor(customStateId)
    }

    func setViewableItemsForBreakpoint() {
        let maxViewableItemsIndex = (model.allBreakpointViewableItems.count) - 1
        let index = max(min(breakpointIndex, maxViewableItemsIndex), 0)

        let viewableItemsFromBreakpoints = Int(model.allBreakpointViewableItems[index])
        // ensure viewableItems doesn't exceed totalOffers
        model.viewableItems = (viewableItemsFromBreakpoints < model.totalOffers) ? viewableItemsFromBreakpoints : model
            .totalOffers
    }

    func setRecalculatedCurrentPage() {
        if model.currentLeadingOfferIndex + model.viewableItems > model.totalOffers - 1 {
            // if projected to go above totalOffers, update to last page
            model.currentPage = model.totalPages - 1
            model.indexWithinPage = model.pages[model.currentPage].count - model.viewableItems
        } else if model.currentLeadingOfferIndex >= 0,
                  model.currentPage <= model.totalPages - 1 {
            // ensure projectedLeadingOffer above 0 and currentPage below totalPages
            model.currentPage = Int(floor(Double(model.currentLeadingOfferIndex/model.viewableItems)))
            model.indexWithinPage = model.currentLeadingOfferIndex % model.viewableItems
        }
    }
}
