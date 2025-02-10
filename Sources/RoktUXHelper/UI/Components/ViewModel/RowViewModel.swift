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
class RowViewModel: Identifiable, Hashable, ScreenSizeAdaptive, AnimatableStyleHandling {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?
    let stylingProperties: [BasicStateStylingBlock<BaseStyles>]?
    let accessibilityGrouped: Bool
    weak var layoutState: (any LayoutStateRepresenting)?
    let animatableStyle: AnimationStyle?
    let predicates: [WhenPredicate]?
    let globalBreakPoints: BreakPoint?
    let slots: [SlotOfferModel]
    var width: CGFloat = 0
    var cancellable: AnyCancellable?

    @Published var animate: Bool = false

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    var defaultStyle: [BaseStyles]? {
        stylingProperties?.map(\.default)
    }

    init(children: [LayoutSchemaViewModel]?,
         stylingProperties: [BasicStateStylingBlock<BaseStyles>]?,
         animatableStyle: AnimationStyle?,
         accessibilityGrouped: Bool,
         layoutState: (any LayoutStateRepresenting)?,
         predicates: [WhenPredicate]?,
         globalBreakPoints: BreakPoint?,
         slots: [SlotOfferModel]) {
        self.children = children
        self.stylingProperties = stylingProperties
        self.animatableStyle = animatableStyle
        self.accessibilityGrouped = accessibilityGrouped
        self.layoutState = layoutState
        self.predicates = predicates
        self.globalBreakPoints = globalBreakPoints
        self.slots = slots

        animate = shouldApply(width)
        subscribeToAnimation()
    }
}
