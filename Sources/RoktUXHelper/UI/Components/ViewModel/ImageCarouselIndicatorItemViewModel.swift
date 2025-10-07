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
        progressStyle: BasicStateStylingBlock<BaseStyles>,
        inactiveStyle: [BasicStateStylingBlock<BaseStyles>]?,
        activeStyle: [BasicStateStylingBlock<BaseStyles>]?,
        layoutState: (any LayoutStateRepresenting)?,
        shouldDisplayProgress: Bool
    ) {
        let progressViewModel = RowViewModel(
            children: nil,
            stylingProperties: [
                .init(
                    default: BaseStyles(
                        background: progressStyle.default.background,
                        container: nil,
                        dimension: .init(
                            minWidth: nil,
                            maxWidth: nil,
                            width: shouldDisplayProgress ? .fixed(0) : progressStyle.default.dimension?.width,
                            minHeight: nil,
                            maxHeight: nil,
                            height: progressStyle.default.dimension?.height,
                            rotateZ: nil
                        )
                    ),
                    pressed: nil,
                    hovered: nil,
                    disabled: nil
                )
            ],
            animatableStyle: shouldDisplayProgress ? .init(duration: Double(duration)/1000.0, style: progressStyle.default) : nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: nil,
            globalBreakPoints: nil,
            offers: []
        )

        let activeRowItem = RowViewModel(
            children: [.row(progressViewModel)],
            stylingProperties: activeStyle,
            animatableStyle: nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: nil,
            globalBreakPoints: nil,
            offers: []
        )

        let inactiveRowItem = RowViewModel(
            children: [],
            stylingProperties: inactiveStyle,
            animatableStyle: nil,
            accessibilityGrouped: false,
            layoutState: layoutState,
            predicates: nil,
            globalBreakPoints: nil,
            offers: []
        )

        let whenActive = WhenViewModel(
            children: [.row(activeRowItem)],
            predicates: [.customState(.init(key: .imageCarouselPosition, condition: .is, value: index))],
            transition: nil,
            offers: [],
            globalBreakPoints: nil,
            layoutState: layoutState
        )

        let whenInActive = WhenViewModel(
            children: [.row(inactiveRowItem)],
            predicates: [.customState(.init(key: .imageCarouselPosition, condition: .isNot, value: index))],
            transition: nil,
            offers: [],
            globalBreakPoints: nil,
            layoutState: layoutState
        )

        super.init(
            children: [.when(whenActive), .when(whenInActive)],
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
