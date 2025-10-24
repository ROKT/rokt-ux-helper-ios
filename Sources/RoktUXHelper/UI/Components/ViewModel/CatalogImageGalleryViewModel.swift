//
//  CatalogImageGalleryViewModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Combine
import Foundation
import DcuiSchema

@available(iOS 15, *)
final class CatalogImageGalleryViewModel: ObservableObject, ScreenSizeAdaptive, Identifiable, Hashable {
    typealias Item = CatalogImageGalleryStyles

    let id: UUID = UUID()
    weak var layoutState: (any LayoutStateRepresenting)?

    @Published var images: [DataImageViewModel] {
        didSet {
            clampSelectedIndex()
        }
    }

    @Published private(set) var selectedIndex: Int = 0

    let defaultStyle: [CatalogImageGalleryStyles]?
    private let thumbnailStyleBlock: [BasicStateStylingBlock<DataImageStyles>]?
    private let selectedThumbnailStyleBlock: [BasicStateStylingBlock<DataImageStyles>]?
    private let thumbnailRowStyleBlock: [BasicStateStylingBlock<RowStyle>]?

    let scrollGradientLength: Double?
    let leftScrollIcon: StaticImageViewModel?
    let rightScrollIcon: StaticImageViewModel?

    private let indicatorStyleBlocks: [BasicStateStylingBlock<BaseStyles>]?
    private let activeIndicatorStyleBlocks: [BasicStateStylingBlock<BaseStyles>]?
    private let seenIndicatorStyleBlocks: [BasicStateStylingBlock<BaseStyles>]?
    private let progressIndicatorContainerBlocks: [BasicStateStylingBlock<BaseStyles>]?

    init(
        images: [DataImageViewModel],
        defaultStyle: [CatalogImageGalleryStyles]?,
        thumbnailStyle: [BasicStateStylingBlock<DataImageStyles>]?,
        selectedThumbnailStyle: [BasicStateStylingBlock<DataImageStyles>]?,
        thumbnailRowStyle: [BasicStateStylingBlock<RowStyle>]?,
        scrollGradientLength: Double?,
        leftScrollIcon: StaticImageViewModel?,
        rightScrollIcon: StaticImageViewModel?,
        indicatorStyle: [BasicStateStylingBlock<CatalogImageGalleryIndicatorStyles>]?,
        activeIndicatorStyle: [BasicStateStylingBlock<CatalogImageGalleryIndicatorStyles>]?,
        seenIndicatorStyle: [BasicStateStylingBlock<CatalogImageGalleryIndicatorStyles>]?,
        progressIndicatorContainer: [BasicStateStylingBlock<CatalogImageGalleryIndicatorStyles>]?,
        layoutState: (any LayoutStateRepresenting)?
    ) {
        self.layoutState = layoutState
        self.images = images
        self.defaultStyle = defaultStyle
        self.thumbnailStyleBlock = thumbnailStyle
        self.selectedThumbnailStyleBlock = selectedThumbnailStyle
        self.thumbnailRowStyleBlock = thumbnailRowStyle
        self.scrollGradientLength = scrollGradientLength
        self.leftScrollIcon = leftScrollIcon
        self.rightScrollIcon = rightScrollIcon
        self.indicatorStyleBlocks = indicatorStyle?.mapToBaseStyles(BaseStyles.init)
        self.activeIndicatorStyleBlocks = activeIndicatorStyle?.mapToBaseStyles(BaseStyles.init)
        self.seenIndicatorStyleBlocks = seenIndicatorStyle?.mapToBaseStyles(BaseStyles.init)
        self.progressIndicatorContainerBlocks = progressIndicatorContainer?.mapToBaseStyles(BaseStyles.init)
        clampSelectedIndex()
    }

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    var selectedImage: DataImageViewModel? {
        images[safe: selectedIndex]
    }

    var showThumbnails: Bool {
        thumbnailRowStyleBlock != nil
    }

    var showIndicator: Bool {
        progressIndicatorContainerBlocks != nil
    }

    var canSelectNextImage: Bool {
        selectedIndex < images.count - 1
    }

    var canSelectPreviousImage: Bool {
        selectedIndex > 0
    }

    func selectImage(at index: Int) {
        guard images.indices.contains(index), index != selectedIndex else { return }
        selectedIndex = index
    }

    func selectNextImage() {
        guard canSelectNextImage else { return }
        selectedIndex += 1
    }

    func selectPreviousImage() {
        guard canSelectPreviousImage else { return }
        selectedIndex -= 1
    }

    func dotViewModel(for index: Int, breakpointIndex: Int) -> RowViewModel {
        let style: BaseStyles? = {
            if index == selectedIndex {
                return activeIndicatorStyleBlocks?[safe: breakpointIndex]?.default
            } else if index < selectedIndex {
                return seenIndicatorStyleBlocks?[safe: breakpointIndex]?.default
                    ?? indicatorStyleBlocks?[safe: breakpointIndex]?.default
            } else {
                return indicatorStyleBlocks?[safe: breakpointIndex]?.default
            }
        }()

        let stylingProperties: [BasicStateStylingBlock<BaseStyles>]? = style.map {
            [
                BasicStateStylingBlock(
                    default: $0,
                    pressed: nil,
                    hovered: nil,
                    disabled: nil
                )
            ]
        }

        return RowViewModel(
            children: nil,
            stylingProperties: stylingProperties,
            animatableStyle: nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: nil,
            globalBreakPoints: nil,
            offers: []
        )
    }

    func indicatorContainerViewModel(for breakpointIndex: Int) -> RowViewModel? {
        guard let containerBlocks = progressIndicatorContainerBlocks else { return nil }
        let children = images.indices.map { index in
            LayoutSchemaViewModel.row(dotViewModel(for: index, breakpointIndex: breakpointIndex))
        }
        return RowViewModel(
            children: children,
            stylingProperties: containerBlocks,
            animatableStyle: nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: nil,
            globalBreakPoints: nil,
            offers: []
        )
    }

    func indicatorAlignSelf(for breakpointIndex: Int) -> FlexAlignment? {
        progressIndicatorContainerBlocks?[safe: breakpointIndex]?.default.flexChild?.alignSelf
    }

    func thumbnailDimension(
        for state: StyleState = .default,
        breakpointIndex: Int = 0
    ) -> DimensionStylingProperties? {
        style(for: state, breakpointIndex: breakpointIndex)?.dimension
            ?? thumbnailStyleBlock?[safe: breakpointIndex]?.default.dimension
    }

    func borderForThumbnail(
        isSelected: Bool,
        state: StyleState = .default,
        breakpointIndex: Int = 0
    ) -> BorderStylingProperties? {
        if isSelected {
            return style(for: state, in: selectedThumbnailStyleBlock, breakpointIndex: breakpointIndex)?.border
                ?? selectedThumbnailStyleBlock?[safe: breakpointIndex]?.default.border
        }
        return style(for: state, breakpointIndex: breakpointIndex)?.border
            ?? thumbnailStyleBlock?[safe: breakpointIndex]?.default.border
    }

    func backgroundForThumbnail(
        state: StyleState = .default,
        breakpointIndex: Int = 0
    ) -> BackgroundStylingProperties? {
        style(for: state, breakpointIndex: breakpointIndex)?.background
            ?? thumbnailStyleBlock?[safe: breakpointIndex]?.default.background
    }

    func thumbnailSpacing(breakpointIndex: Int = 0) -> SpacingStylingProperties? {
        thumbnailRowStyleBlock?[safe: breakpointIndex]?.default.spacing
    }

    private func style(for state: StyleState, breakpointIndex: Int = 0) -> DataImageStyles? {
        style(for: state, in: thumbnailStyleBlock, breakpointIndex: breakpointIndex)
    }

    private func style(
        for state: StyleState,
        in block: [BasicStateStylingBlock<DataImageStyles>]?,
        breakpointIndex: Int = 0
    ) -> DataImageStyles? {
        guard let block, let styleBlock = block[safe: breakpointIndex] else { return nil }
        switch state {
        case .hovered:
            return styleBlock.hovered ?? styleBlock.default
        case .pressed:
            return styleBlock.pressed ?? styleBlock.default
        case .disabled:
            return styleBlock.disabled ?? styleBlock.default
        default:
            return styleBlock.default
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CatalogImageGalleryViewModel, rhs: CatalogImageGalleryViewModel) -> Bool {
        lhs.id == rhs.id
    }

    private func clampSelectedIndex() {
        guard !images.isEmpty else {
            selectedIndex = 0
            return
        }
        if selectedIndex > images.count - 1 {
            selectedIndex = images.count - 1
        }
    }
}
