//
//  ImageCarouselIndicatorViewModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

@available(iOS 15, *)
class ImageCarouselIndicatorViewModel:
    Hashable,
    Identifiable,
    ObservableObject,
    BaseStyleAdaptive {

    let id: UUID = UUID()

    private let positions: Int
    private let duration: Int32
    let stylingProperties: [BasicStateStylingBlock<BaseStyles>]?

    let indicatorStyle: [BasicStateStylingBlock<BaseStyles>]?
    let seenIndicatorStyle: [BasicStateStylingBlock<BaseStyles>]?
    let activeIndicatorStyle: [BasicStateStylingBlock<BaseStyles>]?
    let shouldDisplayProgress: Bool

    @Published var availableWidth: CGFloat?
    @Published var availableHeight: CGFloat?
    @Published var breakpointIndex: Int = 0
    @Published var styleState: StyleState = .default

    weak var layoutState: (any LayoutStateRepresenting)?
    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    lazy var rowViewModels: [RowViewModel] = createRowViewModels()

    init(
        positions: Int,
        duration: Int32,
        stylingProperties: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?,
        indicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?,
        seenIndicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?,
        activeIndicatorStyle: [BasicStateStylingBlock<DataImageCarouselIndicatorStyles>]?,
        layoutState: (any LayoutStateRepresenting)?,
        shouldDisplayProgress: Bool
    ) {
        self.positions = positions
        self.duration = duration
        self.stylingProperties = stylingProperties?.mapToBaseStyles(BaseStyles.init)
        self.indicatorStyle = indicatorStyle?.mapToBaseStyles(BaseStyles.init)
        self.seenIndicatorStyle = seenIndicatorStyle?.mapToBaseStyles(BaseStyles.init)
        self.activeIndicatorStyle = activeIndicatorStyle?.mapToBaseStyles(BaseStyles.init)
        self.layoutState = layoutState
        self.shouldDisplayProgress = shouldDisplayProgress
    }

    private func createRowViewModels() -> [RowViewModel] {
        var rowViewModels: [RowViewModel] = []
        for i in 0..<positions {
            guard let activeStyle = activeIndicatorStyle?[safe: breakpointIndex] else {
                continue
            }

            rowViewModels.append(
                ImageCarouselIndicatorItemViewModel(
                    index: Int32(i + 1),
                    duration: duration,
                    progressStyle: activeStyle,
                    inactiveStyle: indicatorStyle,
                    activeStyle: seenIndicatorStyle,
                    layoutState: layoutState,
                    shouldDisplayProgress: shouldDisplayProgress
                )
            )
        }
        return rowViewModels
    }

    func shouldUpdate(_ size: CGSize) {
        if availableWidth != size.width {
            availableWidth = size.width
        }
        if availableHeight != size.height {
            availableHeight = size.height
        }
    }

    func shouldUpdateBreakpoint(_ width: CGFloat?) {
        let index = max(min(layoutState?.getGlobalBreakpointIndex(width) ?? 0,
                            (defaultStyle?.count ?? 1) - 1), 0)
        if index != breakpointIndex {
            breakpointIndex = index
        }
    }
}
