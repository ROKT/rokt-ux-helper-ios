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

fileprivate extension BaseStyles {
    static let wrapContentStyle = BaseStyles(
        dimension: .init(
            minWidth: nil,
            maxWidth: nil,
            width: .fit(.wrapContent),
            minHeight: nil,
            maxHeight: nil,
            height: .fit(.wrapContent),
            rotateZ: nil
        )
    )
}

@available(iOS 15, *)
class ImageCarouselIndicatorItemViewModel: RowViewModel {
    init(
        index: Int32,
        duration: Int32,
        activeStyle: BasicStateStylingBlock<BaseStyles>,
        indicatorStyle: [BasicStateStylingBlock<BaseStyles>]?,
        seenStyle: [BasicStateStylingBlock<BaseStyles>]?,
        layoutState: (any LayoutStateRepresenting)?,
        shouldDisplayProgress: Bool
    ) {
        func whenNode(
            index: Int32,
            condition: OrderableWhenCondition,
            style: [BasicStateStylingBlock<BaseStyles>]?,
            layoutState: (any LayoutStateRepresenting)?,
            child: RowViewModel? = nil
        ) -> LayoutSchemaViewModel {

            var children = [LayoutSchemaViewModel]()
            if let child {
                children.append(.row(child))
            }

            let row = RowViewModel(
                children: children,
                stylingProperties: style,
                animatableStyle: nil,
                accessibilityGrouped: false,
                layoutState: layoutState,
                predicates: nil,
                globalBreakPoints: nil,
                offers: []
            )

            return .when(WhenViewModel(
                children: [.row(row)],
                predicates: [.customState(.init(key: .imageCarouselPosition, condition: condition, value: index))],
                transition: nil,
                offers: [],
                globalBreakPoints: nil,
                layoutState: layoutState
            ))
        }

        let progressStyle: [BasicStateStylingBlock<BaseStyles>] = [
            .init(
                default: BaseStyles(
                    background: activeStyle.default.background,
                    container: nil,
                    dimension: .init(
                        minWidth: nil,
                        maxWidth: nil,
                        width: shouldDisplayProgress ? .fixed(0) : activeStyle.default.dimension?.width,
                        minHeight: nil,
                        maxHeight: nil,
                        height: activeStyle.default.dimension?.height,
                        rotateZ: nil
                    )
                ),
                pressed: nil,
                hovered: nil,
                disabled: nil
            )
        ]

        let progressViewModel = RowViewModel(
            children: nil,
            stylingProperties: progressStyle,
            animatableStyle: shouldDisplayProgress ? .init(duration: Double(duration)/1000.0, style: activeStyle.default) : nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: nil,
            globalBreakPoints: nil,
            offers: []
        )

        let activeStylingProperties: [BasicStateStylingBlock<BaseStyles>]? = [
            .init(
                default: BaseStyles(
                    background: indicatorStyle?[0].default.background,
                    border: activeStyle.default.border,
                    container: activeStyle.default.container,
                    dimension: activeStyle.default.dimension,
                    flexChild: activeStyle.default.flexChild,
                    spacing: activeStyle.default.spacing,
                    text: activeStyle.default.text
                ),
                pressed: nil,
                hovered: nil,
                disabled: nil
            )
        ]

        let whenSeen = whenNode(index: index, condition: .isBelow, style: seenStyle, layoutState: layoutState)
        let whenActive = whenNode(
            index: index,
            condition: .is,
            style: activeStylingProperties,
            layoutState: layoutState,
            child: progressViewModel
        )
        let whenNotSeen = whenNode(index: index, condition: .isAbove, style: indicatorStyle, layoutState: layoutState)

        super.init(
            children: [whenSeen, whenActive, whenNotSeen],
            stylingProperties: [
                .init(
                    default: .wrapContentStyle,
                    pressed: nil,
                    hovered: nil,
                    disabled: nil
                )
            ],
            animatableStyle: nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: nil,
            globalBreakPoints: nil,
            offers: []
        )
    }
}
