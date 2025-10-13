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
//

import Foundation
import DcuiSchema

@available(iOS 15, *)
final class CatalogImageGalleryViewModel: ObservableObject, ScreenSizeAdaptive, Identifiable, Hashable {
    typealias Item = CatalogImageGalleryStyles

    let id: UUID = UUID()
    weak var layoutState: (any LayoutStateRepresenting)?

    @Published var images: [DataImageViewModel]

    let defaultStyle: [CatalogImageGalleryStyles]?
    private let thumbnailStyleBlock: [BasicStateStylingBlock<DataImageStyles>]?
    private let selectedThumbnailStyleBlock: [BasicStateStylingBlock<DataImageStyles>]?
    private let thumbnailRowStyleBlock: [BasicStateStylingBlock<RowStyle>]?

    let scrollGradientLength: Double?
    let leftScrollIcon: StaticImageViewModel?
    let rightScrollIcon: StaticImageViewModel?

    init(
        images: [DataImageViewModel],
        defaultStyle: [CatalogImageGalleryStyles]?,
        thumbnailStyle: [BasicStateStylingBlock<DataImageStyles>]?,
        selectedThumbnailStyle: [BasicStateStylingBlock<DataImageStyles>]?,
        thumbnailRowStyle: [BasicStateStylingBlock<RowStyle>]?,
        scrollGradientLength: Double?,
        leftScrollIcon: StaticImageViewModel?,
        rightScrollIcon: StaticImageViewModel?,
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
    }

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
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
}
