//
//  BaseStyles.swift
//
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

struct BaseStyles: Codable, Hashable {
    let background: BackgroundStylingProperties?
    let border: BorderStylingProperties?
    let container: ContainerStylingProperties?
    let dimension: DimensionStylingProperties?
    let flexChild: FlexChildStylingProperties?
    let spacing: SpacingStylingProperties?
    let text: TextStylingProperties?

    init(
        background: BackgroundStylingProperties? = nil,
        border: BorderStylingProperties? = nil,
        container: ContainerStylingProperties? = nil,
        dimension: DimensionStylingProperties? = nil,
        flexChild: FlexChildStylingProperties? = nil,
        spacing: SpacingStylingProperties? = nil,
        text: TextStylingProperties? = nil
    ) {
        self.background = background
        self.border = border
        self.container = container
        self.dimension = dimension
        self.flexChild = flexChild
        self.spacing = spacing
        self.text = text
    }
}

@available(iOS 13, *)
extension BaseStyles {

    static func union(_ style: BaseStyles?, diff: BaseStyles?) -> Self? {
        guard let diff else { return style }
        return .init(
            background: try? StyleTransformer.updatedBackground(style?.background, newStyle: diff.background),
            border: try? StyleTransformer.updatedBorder(style?.border, newStyle: diff.border),
            container: try? StyleTransformer.updatedContainer(style?.container, newStyle: diff.container),
            dimension: StyleTransformer.updatedDimension(style?.dimension, newStyle: diff.dimension),
            flexChild: StyleTransformer.updatedFlexChild(style?.flexChild, newStyle: diff.flexChild),
            spacing: StyleTransformer.updatedSpacing(style?.spacing, newStyle: diff.spacing),
            text: try? StyleTransformer.updatedText(style?.text, newStyle: diff.text)
        )
    }
}

@available(iOS 13, *)
extension BaseStyles {
    init(_ style: StaticImageStyles) {
        self.init(
            background: style.background,
            border: style.border,
            dimension: style.dimension,
            flexChild: style.flexChild,
            spacing: style.spacing
        )
    }

    init(_ style: RowStyle) {
        self.init(
            background: style.background,
            border: style.border,
            container: style.container,
            dimension: style.dimension,
            flexChild: style.flexChild,
            spacing: style.spacing
        )
    }

    init(_ style: ScrollableRowStyle) {
        self.init(
            background: style.background,
            border: style.border,
            container: style.container,
            dimension: style.dimension,
            flexChild: style.flexChild,
            spacing: style.spacing
        )
    }

    init(_ style: DataImageCarouselStyles) {
        self.init(
            background: style.background,
            border: style.border,
            container: style.container,
            dimension: style.dimension,
            flexChild: style.flexChild,
            spacing: style.spacing
        )
    }

    init(_ style: DataImageCarouselIndicatorStyles) {
        self.init(
            background: style.background,
            border: style.border,
            container: style.container,
            dimension: style.dimension,
            flexChild: style.flexChild,
            spacing: style.spacing
        )
    }

    init(_ style: CatalogImageGalleryStyles) {
        self.init(
            background: style.background,
            border: style.border,
            container: style.container,
            dimension: style.dimension,
            flexChild: style.flexChild,
            spacing: style.spacing
        )
    }

    init(_ style: CatalogImageGalleryIndicatorStyles) {
        self.init(
            background: style.background,
            border: style.border,
            container: style.container,
            dimension: style.dimension,
            flexChild: style.flexChild,
            spacing: style.spacing
        )
    }
}

extension BasicStateStylingBlock where StyleProperties: Codable {
    func mapToBaseStyles(_ transform: (StyleProperties) -> BaseStyles) -> BasicStateStylingBlock<BaseStyles> {
        BasicStateStylingBlock<BaseStyles>(
            default: transform(`default`),
            pressed: pressed.map(transform),
            hovered: hovered.map(transform),
            disabled: disabled.map(transform)
        )
    }
}

extension Collection {
    func mapToBaseStyles<T: Codable>(_ transform: (T) -> BaseStyles) -> [BasicStateStylingBlock<BaseStyles>]
    where Element == BasicStateStylingBlock<T> {
        self.map { $0.mapToBaseStyles(transform) }
    }
}
