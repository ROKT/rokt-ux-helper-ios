//
//  LayoutTransformer.swift
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
struct LayoutTransformer<Expander: PayloadExpander, Extractor: DataExtractor> where Expander.T == OfferModel {
    let layoutPlugin: LayoutPlugin
    let expander: Expander
    let extractor: Extractor
    let layoutState: LayoutState
    let eventService: EventDiagnosticServicing?

    init(
        layoutPlugin: LayoutPlugin,
        expander: Expander = BNFPayloadExpander(),
        extractor: Extractor = BNFDataExtractor(),
        layoutState: LayoutState = LayoutState(),
        eventService: EventDiagnosticServicing? = nil
    ) {
        self.layoutPlugin = layoutPlugin
        self.expander = expander
        self.extractor = extractor
        self.layoutState = layoutState
        self.eventService = eventService
    }

    func transform() throws -> LayoutSchemaViewModel? {
        guard let layout = layoutPlugin.layout else { return nil}

        let transformedUIModels = try transform(layout)

        for (slotIndex, slot) in layoutPlugin.slots.enumerated() {
            expander.expand(
                layoutVariant: transformedUIModels,
                parent: nil,
                creativeParent: nil,
                using: slot.offer,
                dataSourceIndex: slotIndex,
                usesDataSourceIndex: nil
            )
        }

        AttributedStringTransformer.convertRichTextHTMLIfExists(uiModel: transformedUIModels, config: layoutState.config)

        return transformedUIModels
    }

    func transform<T: Codable>(_ layout: T, slot: SlotOfferModel? = nil) throws -> LayoutSchemaViewModel {
        if let layout = layout as? LayoutSchemaModel {
            return try transform(layout, slot: slot)
        } else if let layout = layout as? AccessibilityGroupedLayoutChildren {
            return try transform(layout, slot: slot)
        } else {
            return .empty
        }
    }

    func transform(_ layout: LayoutSchemaModel, slot: SlotOfferModel? = nil) throws -> LayoutSchemaViewModel {
        switch layout {
        case .row(let rowModel):
            return .row(try getRow(rowModel.styles, children: transformChildren(rowModel.children, slot: slot)))
        case .column(let columnModel):
            return .column(try getColumn(
                columnModel.styles,
                children: transformChildren(columnModel.children, slot: slot)
            ))
        case .zStack(let zStackModel):
            return .zStack(try getZStack(zStackModel.styles,
                                         children: transformChildren(zStackModel.children, slot: slot)))
        case .basicText(let basicTextModel): return .basicText(try getBasicText(basicTextModel))
        case .staticImage(let imageModel): return .staticImage(try getStaticImage(imageModel))
        case .richText(let richTextModel):
            return .richText(try getRichText(richTextModel))

        case .dataImage(let imageModel): return .dataImage(try getDataImage(imageModel, slot: slot))
        case .progressIndicator(let progressIndicatorModel):
            return .progressIndicator(try getProgressIndicatorUIModel(progressIndicatorModel))
        case .creativeResponse(let model):
            return try getCreativeResponse(responseKey: model.responseKey,
                                           openLinks: model.openLinks,
                                           styles: model.styles,
                                           children: transformChildren(model.children, slot: slot),
                                           slot: slot)
        case .oneByOneDistribution(let oneByOneModel):
            return .oneByOne(try getOneByOne(oneByOneModel: oneByOneModel))
        case .overlay(let overlayModel):
            return .overlay(try getOverlay(overlayModel.styles,
                                           allowBackdropToClose: overlayModel.allowBackdropToClose,
                                           children: transformChildren(overlayModel.children, slot: slot)))
        case .bottomSheet(let bottomSheetModel):
            return .bottomSheet(try getBottomSheet(bottomSheetModel.styles,
                                                   allowBackdropToClose: bottomSheetModel.allowBackdropToClose,
                                                   children: transformChildren(bottomSheetModel.children, slot: slot)))
        case .when(let whenModel):
            return .when(getWhenNode(children: try transformChildren(whenModel.children, slot: slot),
                                     predicates: whenModel.predicates,
                                     transition: whenModel.transition))
        case .staticLink(let staticLinkModel):
            return .staticLink(try getStaticLink(src: staticLinkModel.src,
                                                 open: staticLinkModel.open,
                                                 styles: staticLinkModel.styles,
                                                 children: transformChildren(staticLinkModel.children, slot: slot)))
        case .closeButton(let closeButtonModel):
            return .closeButton(try getCloseButton(styles: closeButtonModel.styles,
                                                   children: transformChildren(closeButtonModel.children, slot: slot)))
        case .carouselDistribution(let carouselModel):
            return .carousel(try getCarousel(carouselModel: carouselModel))
        case .groupedDistribution(let groupedModel):
            return .groupDistribution(try getGroupedDistribution(groupedModel: groupedModel))
        case .progressControl(let progressControlModel):
            return .progressControl(try getProgressControl(styles: progressControlModel.styles,
                                                           direction: progressControlModel.direction,
                                                           children: transformChildren(progressControlModel.children,
                                                                                       slot: slot)))
        case .accessibilityGrouped(let accessibilityGroupedModel):
            return try getAccessibilityGrouped(child: accessibilityGroupedModel.child,
                                               slot: slot)
        case .scrollableColumn(let columnModel):
            return .scrollableColumn(try getScrollableColumn(columnModel.styles,
                                                             children:
                                                                transformChildren(columnModel.children, slot: slot)))
        case .scrollableRow(let rowModel):
            return .scrollableRow(try getScrollableRow(rowModel.styles,
                                                       children: transformChildren(rowModel.children, slot: slot)))
        case .toggleButtonStateTrigger(let buttonModel):
            return .toggleButton(try getToggleButton(customStateKey: buttonModel.customStateKey,
                                                     styles: buttonModel.styles,
                                                     children: transformChildren(buttonModel.children,
                                                                                 slot: slot)))
        case .catalogStackedCollection(let model):
            return .catalogStackedCollection(
                try getCatalogStackedCollectionModel(
                    model: model,
                    slot: slot
                )
            )
        case .catalogResponseButton(let model):
            return .catalogResponseButton(
                try getCatalogResponseButtonModel(
                    style: model.styles,
                    children: transformChildren(model.children, slot: slot),
                    slot: slot
                )
            )
        }
    }

    func transform(
        _ layout: AccessibilityGroupedLayoutChildren,
        slot: SlotOfferModel? = nil
    ) throws -> LayoutSchemaViewModel {
        switch layout {
        case .row(let rowModel):
            .row(try getRow(rowModel.styles, children: transformChildren(rowModel.children, slot: slot)))
        case .column(let columnModel):
            .column(
                try getColumn(
                    columnModel.styles,
                    children: transformChildren(columnModel.children, slot: slot)
                )
            )
        case .zStack(let zStackModel):
            .zStack(
                try getZStack(
                    zStackModel.styles,
                    children: transformChildren(zStackModel.children, slot: slot)
                )
            )
        }
    }

    func transformChildren<T: Codable>(_ layouts: [T]?, slot: SlotOfferModel?) throws -> [LayoutSchemaViewModel]? {
        guard let layouts else { return nil }

        var children: [LayoutSchemaViewModel] = []

        try layouts.forEach { layout in
            children.append(try transform(layout, slot: slot))
        }

        return children
    }

    // attach inner layout into outer layout and transform to UI Model
    func getOneByOne(oneByOneModel: OneByOneDistributionModel<WhenPredicate>) throws -> OneByOneViewModel {
        var children: [LayoutSchemaViewModel] = []

        try layoutPlugin.slots.forEach { slot in
            if let innerLayout = slot.layoutVariant?.layoutVariantSchema {
                children.append(try transform(innerLayout, slot: slot.toSlotOfferModel()))
            }
        }
        let updateStyles = try StyleTransformer.updatedStyles(oneByOneModel.styles?.elements?.own)
        return OneByOneViewModel(children: children,
                                 defaultStyle: updateStyles.compactMap {$0.default},
                                 transition: oneByOneModel.transition,
                                 eventService: eventService,
                                 slots: layoutPlugin.slots,
                                 layoutState: layoutState)
    }

    func getCarousel(carouselModel: CarouselDistributionModel<WhenPredicate>) throws -> CarouselViewModel {
        var children: [LayoutSchemaViewModel] = []

        try layoutPlugin.slots.forEach { slot in
            if let innerLayout = slot.layoutVariant?.layoutVariantSchema {
                children.append(try transform(innerLayout, slot: slot.toSlotOfferModel()))
            }
        }
        let updateStyles = try StyleTransformer.updatedStyles(carouselModel.styles?.elements?.own)
        return CarouselViewModel(children: children,
                                 defaultStyle: updateStyles.compactMap {$0.default},
                                 viewableItems: carouselModel.viewableItems,
                                 peekThroughSize: carouselModel.peekThroughSize,
                                 eventService: eventService,
                                 slots: layoutPlugin.slots,
                                 layoutState: layoutState)
    }

    func getGroupedDistribution(
        groupedModel: GroupedDistributionModel<WhenPredicate>
    ) throws -> GroupedDistributionViewModel {
        var children: [LayoutSchemaViewModel] = []

        try layoutPlugin.slots.forEach { slot in
            if let innerLayout = slot.layoutVariant?.layoutVariantSchema {
                children.append(try transform(innerLayout, slot: slot.toSlotOfferModel()))
            }
        }
        let updateStyles = try StyleTransformer.updatedStyles(groupedModel.styles?.elements?.own)
        return GroupedDistributionViewModel(children: children,
                                            defaultStyle: updateStyles.compactMap {$0.default},
                                            viewableItems: groupedModel.viewableItems,
                                            transition: groupedModel.transition,
                                            eventService: eventService,
                                            slots: layoutPlugin.slots,
                                            layoutState: layoutState)
    }

    // MARK: Component Models

    func getStaticImage(_ imageModel: StaticImageModel<WhenPredicate>) throws -> StaticImageViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(imageModel.styles?.elements?.own)
        return StaticImageViewModel(url: imageModel.url,
                                    alt: imageModel.alt,
                                    defaultStyle: updateStyles.compactMap {$0.default},
                                    pressedStyle: updateStyles.compactMap {$0.pressed},
                                    hoveredStyle: updateStyles.compactMap {$0.hovered},
                                    disabledStyle: updateStyles.compactMap {$0.disabled},
                                    layoutState: layoutState)
    }

    func getStaticLink(src: String,
                       open: LinkOpenTarget,
                       styles: LayoutStyle<StaticLinkElements,
                                           ConditionalStyleTransition<StaticLinkTransitions, WhenPredicate>>?,
                       children: [LayoutSchemaViewModel]?) throws -> StaticLinkViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return StaticLinkViewModel(children: children,
                                   src: src,
                                   open: open,
                                   defaultStyle: updateStyles.compactMap {$0.default},
                                   pressedStyle: updateStyles.compactMap {$0.pressed},
                                   hoveredStyle: updateStyles.compactMap {$0.hovered},
                                   disabledStyle: updateStyles.compactMap {$0.disabled},
                                   layoutState: layoutState,
                                   eventService: eventService)
    }

    func getCloseButton(styles: LayoutStyle<CloseButtonElements,
                                            ConditionalStyleTransition<CloseButtonTransitions, WhenPredicate>>?,
                        children: [LayoutSchemaViewModel]?) throws -> CloseButtonViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return CloseButtonViewModel(children: children,
                                    defaultStyle: updateStyles.compactMap {$0.default},
                                    pressedStyle: updateStyles.compactMap {$0.pressed},
                                    hoveredStyle: updateStyles.compactMap {$0.hovered},
                                    disabledStyle: updateStyles.compactMap {$0.disabled},
                                    layoutState: layoutState,
                                    eventService: eventService)
    }

    func getProgressControl(styles: LayoutStyle<ProgressControlElements,
                                                ConditionalStyleTransition<ProgressControlTransitions, WhenPredicate>>?,
                            direction: ProgressionDirection,
                            children: [LayoutSchemaViewModel]?) throws -> ProgressControlViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return ProgressControlViewModel(children: children,
                                        defaultStyle: updateStyles.compactMap {$0.default},
                                        pressedStyle: updateStyles.compactMap {$0.pressed},
                                        hoveredStyle: updateStyles.compactMap {$0.hovered},
                                        disabledStyle: updateStyles.compactMap {$0.disabled},
                                        direction: direction,
                                        layoutState: layoutState)
    }

    func getDataImage(_ imageModel: DataImageModel<WhenPredicate>, slot: SlotOfferModel?) throws -> DataImageViewModel {
        let creativeImage = slot?.offer?.creative.images?[imageModel.imageKey]
        let updateStyles = try StyleTransformer.updatedStyles(imageModel.styles?.elements?.own)
        return DataImageViewModel(image: creativeImage,
                                  defaultStyle: updateStyles.compactMap {$0.default},
                                  pressedStyle: updateStyles.compactMap {$0.pressed},
                                  hoveredStyle: updateStyles.compactMap {$0.hovered},
                                  disabledStyle: updateStyles.compactMap {$0.disabled},
                                  layoutState: layoutState)
    }

    func getBasicText(_ basicTextModel: BasicTextModel<WhenPredicate>) throws -> BasicTextViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(basicTextModel.styles?.elements?.own)
        return BasicTextViewModel(value: basicTextModel.value,
                                  defaultStyle: updateStyles.compactMap {$0.default},
                                  pressedStyle: updateStyles.compactMap {$0.pressed},
                                  hoveredStyle: updateStyles.compactMap {$0.hovered},
                                  disabledStyle: updateStyles.compactMap {$0.disabled},
                                  layoutState: layoutState,
                                  diagnosticService: eventService)
    }

    func getRichText(_ richTextModel: RichTextModel<WhenPredicate>) throws -> RichTextViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(richTextModel.styles?.elements?.own)
        let updateLinkStyles = try StyleTransformer.updatedStyles(richTextModel.styles?.elements?.link)
        return RichTextViewModel(value: richTextModel.value,
                                 defaultStyle: updateStyles.compactMap {$0.default},
                                 linkStyle: updateLinkStyles.compactMap {$0.default},
                                 openLinks: richTextModel.openLinks,
                                 layoutState: layoutState,
                                 eventService: eventService)
    }

    func getColumn(_ styles: LayoutStyle<ColumnElements, ConditionalStyleTransition<ColumnTransitions, WhenPredicate>>?,
                   children: [LayoutSchemaViewModel]?,
                   accessibilityGrouped: Bool = false) throws -> ColumnViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return ColumnViewModel(children: children,
                               defaultStyle: updateStyles.compactMap {$0.default},
                               pressedStyle: updateStyles.compactMap {$0.pressed},
                               hoveredStyle: updateStyles.compactMap {$0.hovered},
                               disabledStyle: updateStyles.compactMap {$0.disabled},
                               accessibilityGrouped: accessibilityGrouped,
                               layoutState: layoutState)
    }

    func getScrollableColumn(_ styles: LayoutStyle<ScrollableColumnElements,
                                                   ConditionalStyleTransition<ScrollableColumnTransitions, WhenPredicate>>?,
                             children: [LayoutSchemaViewModel]?,
                             accessibilityGrouped: Bool = false) throws -> ColumnViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return ColumnViewModel(children: children,
                               defaultStyle: updateStyles.compactMap {
            StyleTransformer.convertToColumnStyles($0.default)
        },
                               pressedStyle: updateStyles.compactMap {
            StyleTransformer.convertToColumnStyles($0.pressed)
        },
                               hoveredStyle: updateStyles.compactMap {
            StyleTransformer.convertToColumnStyles($0.hovered)
        },
                               disabledStyle: updateStyles.compactMap {
            StyleTransformer.convertToColumnStyles($0.disabled)
        },
                               accessibilityGrouped: accessibilityGrouped,
                               layoutState: layoutState)
    }

    func getRow(_ styles: LayoutStyle<RowElements, ConditionalStyleTransition<RowTransitions, WhenPredicate>>?,
                children: [LayoutSchemaViewModel]?,
                accessibilityGrouped: Bool = false) throws -> RowViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)

        return RowViewModel(children: children,
                            defaultStyle: updateStyles.compactMap {$0.default},
                            pressedStyle: updateStyles.compactMap {$0.pressed},
                            hoveredStyle: updateStyles.compactMap {$0.hovered},
                            disabledStyle: updateStyles.compactMap {$0.disabled},
                            accessibilityGrouped: accessibilityGrouped,
                            layoutState: layoutState)
    }

    func getScrollableRow(_ styles: LayoutStyle<ScrollableRowElements,
                                                ConditionalStyleTransition<ScrollableRowTransitions, WhenPredicate>>?,
                          children: [LayoutSchemaViewModel]?,
                          accessibilityGrouped: Bool = false) throws -> RowViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)

        return RowViewModel(children: children,
                            defaultStyle: updateStyles.compactMap {
            StyleTransformer.convertToRowStyles($0.default)
        },
                            pressedStyle: updateStyles.compactMap {
            StyleTransformer.convertToRowStyles($0.pressed)
        },
                            hoveredStyle: updateStyles.compactMap {
            StyleTransformer.convertToRowStyles($0.hovered)
        },
                            disabledStyle: updateStyles.compactMap {
            StyleTransformer.convertToRowStyles($0.disabled)
        },
                            accessibilityGrouped: accessibilityGrouped,
                            layoutState: layoutState)
    }

    func getZStack(_ styles: LayoutStyle<ZStackElements, ConditionalStyleTransition<ZStackTransitions, WhenPredicate>>?,
                   children: [LayoutSchemaViewModel]?,
                   accessibilityGrouped: Bool = false) throws -> ZStackViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return ZStackViewModel(children: children,
                               defaultStyle: updateStyles.compactMap {$0.default},
                               pressedStyle: updateStyles.compactMap {$0.pressed},
                               hoveredStyle: updateStyles.compactMap {$0.hovered},
                               disabledStyle: updateStyles.compactMap {$0.disabled},
                               accessibilityGrouped: accessibilityGrouped,
                               layoutState: layoutState)
    }

    func getAccessibilityGrouped(child: AccessibilityGroupedLayoutChildren,
                                 slot: SlotOfferModel? = nil) throws -> LayoutSchemaViewModel {
        switch child {
        case .column(let columnModel):
            return .column(try getColumn(columnModel.styles,
                                         children: transformChildren(columnModel.children, slot: slot),
                                         accessibilityGrouped: true))
        case .row(let rowModel):
            return .row(try getRow(rowModel.styles,
                                   children: transformChildren(rowModel.children, slot: slot),
                                   accessibilityGrouped: true))
        case .zStack(let zStackModel):
            return .zStack(try getZStack(zStackModel.styles,
                                         children: transformChildren(zStackModel.children, slot: slot),
                                         accessibilityGrouped: true))
        }
    }

    func getOverlay(_ styles: LayoutStyle<OverlayElements,
                                          ConditionalStyleTransition<OverlayTransitions, WhenPredicate>>?,
                    allowBackdropToClose: Bool?,
                    children: [LayoutSchemaViewModel]?) throws -> OverlayViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        let updateWrapperStyles = try StyleTransformer.updatedStyles(styles?.elements?.wrapper)
        return OverlayViewModel(children: children,
                                allowBackdropToClose: allowBackdropToClose,
                                defaultStyle: updateStyles.compactMap {$0.default},
                                wrapperStyle: updateWrapperStyles.compactMap {$0.default},
                                eventService: eventService,
                                layoutState: layoutState)
    }

    func getBottomSheet(_ styles: LayoutStyle<BottomSheetElements,
                                              ConditionalStyleTransition<BottomSheetTransitions, WhenPredicate>>?,
                        allowBackdropToClose: Bool?,
                        children: [LayoutSchemaViewModel]?) throws -> BottomSheetViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return BottomSheetViewModel(children: children,
                                    allowBackdropToClose: allowBackdropToClose,
                                    defaultStyle: updateStyles.compactMap {$0.default},
                                    eventService: eventService,
                                    layoutState: layoutState)
    }

    func getCreativeResponse(responseKey: String,
                             openLinks: LinkOpenTarget?,
                             styles: LayoutStyle<CreativeResponseElements,
                                                 ConditionalStyleTransition<CreativeResponseTransitions, WhenPredicate>>?,
                             children: [LayoutSchemaViewModel]?,
                             slot: SlotOfferModel?) throws -> LayoutSchemaViewModel {
        guard let responseOptionsMap = slot?.offer?.creative.responseOptionsMap,
              (responseKey == BNFNamespace.CreativeResponseKey.positive.rawValue
               && responseOptionsMap.positive != nil)
                ||
                (responseKey == BNFNamespace.CreativeResponseKey.negative.rawValue
                 && responseOptionsMap.negative != nil)
        else {
            return .empty
        }

        return .creativeResponse(try getCreativeResponseUIModel(responseKey: responseKey,
                                                                openLinks: openLinks,
                                                                styles: styles,
                                                                children: children,
                                                                slot: slot))
    }

    func getCreativeResponseUIModel(responseKey: String,
                                    openLinks: LinkOpenTarget?,
                                    styles: LayoutStyle<CreativeResponseElements,
                                                        ConditionalStyleTransition<CreativeResponseTransitions, WhenPredicate>>?,
                                    children: [LayoutSchemaViewModel]?,
                                    slot: SlotOfferModel?) throws -> CreativeResponseViewModel {
        var responseOption: ResponseOption?
        var creativeResponseKey = BNFNamespace.CreativeResponseKey.positive

        if responseKey == BNFNamespace.CreativeResponseKey.positive.rawValue {
            responseOption = slot?.offer?.creative.responseOptionsMap?.positive
            creativeResponseKey = .positive
        }

        if responseKey == BNFNamespace.CreativeResponseKey.negative.rawValue {
            responseOption = slot?.offer?.creative.responseOptionsMap?.negative
            creativeResponseKey = .negative
        }
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return CreativeResponseViewModel(children: children,
                                         responseKey: creativeResponseKey,
                                         responseOptions: responseOption,
                                         openLinks: openLinks,
                                         layoutState: layoutState,
                                         eventService: eventService,
                                         defaultStyle: updateStyles.compactMap {$0.default},
                                         pressedStyle: updateStyles.compactMap {$0.pressed},
                                         hoveredStyle: updateStyles.compactMap {$0.hovered},
                                         disabledStyle: updateStyles.compactMap {$0.disabled})
    }

    func getCatalogStackedCollectionModel(
        model: CatalogStackedCollectionModel<LayoutSchemaModel, WhenPredicate>,
        slot: SlotOfferModel?,
        accessibilityGrouped: Bool = false
    ) throws -> CatalogStackedCollectionViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(model.styles?.elements?.own)
        switch model.template {
        case .column(let model):
            return CatalogStackedCollectionViewModel(
                children: try transformChildren(model.children, slot: slot),
                defaultStyle: updateStyles.compactMap {$0.default},
                accessibilityGrouped: accessibilityGrouped,
                layoutState: layoutState,
                template: .column
            )
        case .row(let model):
            return CatalogStackedCollectionViewModel(
                children: try transformChildren(model.children, slot: slot),
                defaultStyle: updateStyles.compactMap {$0.default},
                accessibilityGrouped: accessibilityGrouped,
                layoutState: layoutState,
                template: .row
            )
        default:
            throw RoktUXError.experienceResponseMapping
        }
    }

    func getCatalogResponseButtonModel(
        style: LayoutStyle<CatalogResponseButtonElements, ConditionalStyleTransition<CatalogResponseButtonTransitions, WhenPredicate>>?,
        children: [LayoutSchemaViewModel]?,
        slot: SlotOfferModel?
    ) throws -> CatalogResponseButtonViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(style?.elements?.own)
        return CatalogResponseButtonViewModel(
            children: children,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: updateStyles.compactMap { $0.default },
            pressedStyle: updateStyles.compactMap { $0.pressed },
            hoveredStyle: updateStyles.compactMap { $0.hovered },
            disabledStyle: updateStyles.compactMap { $0.disabled }
        )
    }

    func getProgressIndicator(
        _ progressIndicatorModel: ProgressIndicatorModel<WhenPredicate>
    ) throws -> LayoutSchemaViewModel {
        do {
            let indicatorData = try extractor.extractDataRepresentedBy(
                String.self,
                propertyChain: progressIndicatorModel.indicator,
                responseKey: nil,
                from: nil
            )

            guard case .state(let stateValue) = indicatorData,
                  DataBindingStateKeys.isValidKey(stateValue)
            else { return .empty }

            return .progressIndicator(try getProgressIndicatorUIModel(progressIndicatorModel))
        } catch {
            return .empty
        }
    }

    func getProgressIndicatorUIModel(
        _ progressIndicatorModel: ProgressIndicatorModel<WhenPredicate>
    ) throws -> ProgressIndicatorViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(progressIndicatorModel.styles?.elements?.own)
        let indicatorStyle = try StyleTransformer.updatedStyles(progressIndicatorModel.styles?.elements?.indicator)
        let seenIndicatorStyle =
        try StyleTransformer.updatedIndicatorStyles(indicatorStyle,
                                                    newStyles: progressIndicatorModel.styles?.elements?.seenIndicator)
        // active falls back to seen (which then falls back to indicator)
        let activeIndicatorStyle =
        try StyleTransformer.updatedIndicatorStyles(seenIndicatorStyle,
                                                    newStyles: progressIndicatorModel.styles?.elements?.activeIndicator)
        return ProgressIndicatorViewModel(
            indicator: progressIndicatorModel.indicator,
            defaultStyle: updateStyles.compactMap {$0.default},
            indicatorStyle: indicatorStyle.compactMap {$0.default},
            activeIndicatorStyle: activeIndicatorStyle.compactMap {$0.default},
            seenIndicatorStyle: seenIndicatorStyle.compactMap {$0.default},
            startPosition: progressIndicatorModel.startPosition,
            accessibilityHidden: progressIndicatorModel.accessibilityHidden,
            layoutState: layoutState,
            eventService: eventService
        )
    }

    func getWhenNode(children: [LayoutSchemaViewModel]?,
                     predicates: [WhenPredicate],
                     transition: WhenTransition?) -> WhenViewModel {
        return WhenViewModel(children: children,
                             predicates: predicates,
                             transition: transition,
                             slots: layoutPlugin.slots.map {$0.toSlotOfferModel()},
                             globalBreakPoints: layoutPlugin.breakpoints,
                             layoutState: layoutState)
    }

    func getToggleButton(customStateKey: String,
                         styles: LayoutStyle<ToggleButtonStateTriggerElements,
                                             ConditionalStyleTransition<ToggleButtonStateTriggerTransitions, WhenPredicate>>?,
                         children: [LayoutSchemaViewModel]?) throws -> ToggleButtonViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(styles?.elements?.own)
        return ToggleButtonViewModel(children: children,
                                     customStateKey: customStateKey,
                                     defaultStyle: updateStyles.compactMap {$0.default},
                                     pressedStyle: updateStyles.compactMap {$0.pressed},
                                     hoveredStyle: updateStyles.compactMap {$0.hovered},
                                     disabledStyle: updateStyles.compactMap {$0.disabled},
                                     layoutState: layoutState)
    }
}
