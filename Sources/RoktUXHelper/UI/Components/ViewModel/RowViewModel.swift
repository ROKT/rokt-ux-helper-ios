//
//  RowUIModel.swift
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
import Combine

@available(iOS 15, *)
class RowViewModel: Identifiable, Hashable, BaseStyleAdaptive, AnimatableStyleHandling {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let stylingProperties: [BasicStateStylingBlock<BaseStyles>]?
    let accessibilityGrouped: Bool
    weak var layoutState: (any LayoutStateRepresenting)?
    let animatableStyle: AnimationStyle?
    let predicates: [WhenPredicate]?
    let globalBreakPoints: BreakPoint?
    let offers: [OfferModel?]
    var width: CGFloat = 0
    var cancellable: AnyCancellable?
    var componentConfig: ComponentConfig?

    @Published var animate: Bool = false

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         stylingProperties: [BasicStateStylingBlock<BaseStyles>]?,
         animatableStyle: AnimationStyle?,
         accessibilityGrouped: Bool,
         layoutState: (any LayoutStateRepresenting)?,
         predicates: [WhenPredicate]?,
         globalBreakPoints: BreakPoint?,
         offers: [OfferModel?]) {
        self.children = children
        self.stylingProperties = stylingProperties
        self.animatableStyle = animatableStyle
        self.accessibilityGrouped = accessibilityGrouped
        self.layoutState = layoutState
        self.predicates = predicates
        self.globalBreakPoints = globalBreakPoints
        self.offers = offers

        animate = shouldApply(width) && !animatableStyle.isNil
        cancellable = layoutState?.itemsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                animate = shouldApply(width) && !animatableStyle.isNil
            }
    }
}
