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
struct LayoutTransformer {

    let layoutPlugin: LayoutPlugin
    let layoutState: LayoutState
    let eventService: EventDiagnosticServicing?

    init(
        layoutPlugin: LayoutPlugin,
        layoutState: LayoutState = LayoutState(),
        eventService: EventDiagnosticServicing? = nil
    ) {
        self.layoutPlugin = layoutPlugin
        self.layoutState = layoutState
        self.eventService = eventService
    }

    func transform() throws -> LayoutSchemaViewModel? {
        guard let layout = layoutPlugin.layout else { return nil}

        let transformedUIModels = try transform(
            layout,
            context: .outer(layoutPlugin.slots.compactMap(\.offer))
        )

        AttributedStringTransformer.convertRichTextHTMLIfExists(uiModel: transformedUIModels, config: layoutState.config)

        return transformedUIModels
    }

    // TODO: will have to fix accessibilityGroupedLayoutChildren

    enum Context {
        case outer([OfferModel])
        case inner(Inner)

        enum Inner {
            case marketing(Marketing)
            case addToCart(CatalogItem)

            enum Marketing {
                case positive(OfferModel)
                case negative(OfferModel)
                case generic(OfferModel?)

                var offer: OfferModel? {
                    switch self {
                    case .positive(let offerModel),
                            .negative(let offerModel):
                        offerModel
                    case .generic(let offerModel):
                        offerModel
                    }
                }
            }
        }
    }

    // transform inner
    func transform(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        switch layout {
        case .row(let rowModel):
            return .row(
                try getRow(
                    rowModel.styles,
                    children: transformChildren(rowModel.children, context: context)
                )
            )
        case .column(let columnModel):
            return .column(
                try getColumn(
                    columnModel.styles,
                    children: transformChildren(columnModel.children, context: context)
                )
            )
        case .zStack(let zStackModel):
            return .zStack(
                try getZStack(
                    zStackModel.styles,
                    children: transformChildren(zStackModel.children, context: context)
                )
            )
        case .basicText(let basicTextModel):
            let vm: LayoutSchemaViewModel = .basicText(try getBasicText(basicTextModel, context: context))
            map(viewModel: vm, context: context)
            return vm
        case .staticImage(let imageModel):
            return .staticImage(try getStaticImage(imageModel))
        case .richText(let richTextModel):
            let vm: LayoutSchemaViewModel = .richText(try getRichText(richTextModel, context: context))
            map(viewModel: vm, context: context)
            return vm
        case .dataImage(let imageModel):
            return .dataImage(try getDataImage(imageModel, context: context))
        case .progressIndicator(let progressIndicatorModel):
            let vm: LayoutSchemaViewModel = .progressIndicator(try getProgressIndicatorUIModel(progressIndicatorModel))
            map(viewModel: vm, context: context)
            return vm
        case .creativeResponse(let model):
            return try getCreativeResponse(
                model: model,
                context: context
            )
        case .oneByOneDistribution(let oneByOneModel):
            return .oneByOne(try getOneByOne(oneByOneModel: oneByOneModel))
        case .overlay(let overlayModel):
            return .overlay(
                try getOverlay(
                    overlayModel.styles,
                    allowBackdropToClose: overlayModel.allowBackdropToClose,
                    children: transformChildren(overlayModel.children, context: context)
                )
            )
        case .bottomSheet(let bottomSheetModel):
            return .bottomSheet(
                try getBottomSheet(
                    bottomSheetModel.styles,
                    allowBackdropToClose: bottomSheetModel.allowBackdropToClose,
                    children: transformChildren(bottomSheetModel.children, context: context)
                )
            )
        case .when(let whenModel):
            return .when(
                getWhenNode(
                    children: try transformChildren(whenModel.children, context: context),
                    predicates: whenModel.predicates,
                    transition: whenModel.transition
                )
            )
        case .staticLink(let staticLinkModel):
            return .staticLink(
                try getStaticLink(
                    src: staticLinkModel.src,
                    open: staticLinkModel.open,
                    styles: staticLinkModel.styles,
                    children: transformChildren(staticLinkModel.children, context: context)
                )
            )
        case .closeButton(let closeButtonModel):
            return .closeButton(
                try getCloseButton(
                    styles: closeButtonModel.styles,
                    children: transformChildren(closeButtonModel.children, context: context)
                )
            )
        case .carouselDistribution(let carouselModel):
            return .carousel(try getCarousel(carouselModel: carouselModel))
        case .groupedDistribution(let groupedModel):
            return .groupDistribution(try getGroupedDistribution(groupedModel: groupedModel))
        case .progressControl(let progressControlModel):
            return .progressControl(
                try getProgressControl(
                    styles: progressControlModel.styles,
                    direction: progressControlModel.direction,
                    children: transformChildren(progressControlModel.children, context: context)
                )
            )
        case .scrollableColumn(let columnModel):
            return .scrollableColumn(
                try getScrollableColumn(
                    columnModel.styles,
                    children:
                        transformChildren(columnModel.children, context: context)
                )
            )
        case .scrollableRow(let rowModel):
            return .scrollableRow(
                try getScrollableRow(
                    rowModel.styles,
                    children: transformChildren(rowModel.children, context: context)
                )
            )
        case .toggleButtonStateTrigger(let buttonModel):
            return .toggleButton(
                try getToggleButton(
                    customStateKey: buttonModel.customStateKey,
                    styles: buttonModel.styles,
                    children: transformChildren(buttonModel.children, context: context)
                )
            )
        case .catalogStackedCollection(let model):
            return .catalogStackedCollection(
                try getCatalogStackedCollectionModel(
                    model: model,
                    context: context
                )
            )
        case .catalogResponseButton(let model):
            return .catalogResponseButton(
                try getCatalogResponseButtonModel(
                    style: model.styles,
                    children: transformChildren(model.children, context: context)
                )
            )
        case .accessibilityGrouped(let accessibilityGroupedModel):
            throw LayoutTransformerError.UnsupportedNode
        }
    }

    func transformChildren(_ layouts: [LayoutSchemaModel], context: Context) throws -> [LayoutSchemaViewModel]? {
        try layouts.map {
            try transform($0, context: context)
        }
    }

    // attach inner layout into outer layout and transform to UI Model
    func getOneByOne(oneByOneModel: OneByOneDistributionModel<WhenPredicate>) throws -> OneByOneViewModel {
        var children: [LayoutSchemaViewModel] = []

        try layoutPlugin.slots.forEach { slot in
            if let innerLayout = slot.layoutVariant?.layoutVariantSchema {
                children.append(
                    try transform(
                        innerLayout,
                        context: .inner(.marketing(.generic(slot.offer)))
                    )
                )
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
                children.append(try transform(innerLayout, context: .inner(.marketing(.generic(slot.offer)))))
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
                children.append(try transform(innerLayout, context: .inner(.marketing(.generic(slot.offer)))))
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

    func getDataImage(_ imageModel: DataImageModel<WhenPredicate>, context: Context) throws -> DataImageViewModel {
        guard case let .inner(offer) = context else {
            throw LayoutTransformerError.InvalidNode
        }
        var creativeImage: CreativeImage? = nil
        if case let .inner(.marketing(container)) = context {
            creativeImage = container.offer?.creative.images?[imageModel.imageKey]
        } else if case let .inner(.addToCart(model)) = context {
            creativeImage = model.images?[imageModel.imageKey]
        }
        let updateStyles = try StyleTransformer.updatedStyles(imageModel.styles?.elements?.own)
        return DataImageViewModel(image: creativeImage,
                                  defaultStyle: updateStyles.compactMap {$0.default},
                                  pressedStyle: updateStyles.compactMap {$0.pressed},
                                  hoveredStyle: updateStyles.compactMap {$0.hovered},
                                  disabledStyle: updateStyles.compactMap {$0.disabled},
                                  layoutState: layoutState)
    }

    func getBasicText(_ basicTextModel: BasicTextModel<WhenPredicate>, context: Context) throws -> BasicTextViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(basicTextModel.styles?.elements?.own)
        return BasicTextViewModel(value: basicTextModel.value,
                                  defaultStyle: updateStyles.compactMap {$0.default},
                                  pressedStyle: updateStyles.compactMap {$0.pressed},
                                  hoveredStyle: updateStyles.compactMap {$0.hovered},
                                  disabledStyle: updateStyles.compactMap {$0.disabled},
                                  layoutState: layoutState,
                                  diagnosticService: eventService)
    }

    func getRichText(_ richTextModel: RichTextModel<WhenPredicate>, context: Context) throws -> RichTextViewModel {
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

    func getCreativeResponse(model: CreativeResponseModel<LayoutSchemaModel, WhenPredicate>,
                             context: Context) throws -> LayoutSchemaViewModel {
        guard case let .inner(.marketing(.generic(offer))) = context, let offer else {
            throw LayoutTransformerError.InvalidNode
        }
        let responseKey = model.responseKey
        guard let responseOptionsMap = offer.creative.responseOptionsMap,
              (responseKey == BNFNamespace.CreativeResponseKey.positive.rawValue
               && responseOptionsMap.positive != nil)
                ||
                (responseKey == BNFNamespace.CreativeResponseKey.negative.rawValue
                 && responseOptionsMap.negative != nil)
        else {
            return .empty
        }

        let updatedContext: Context
        if responseKey == BNFNamespace.CreativeResponseKey.positive.rawValue {
            updatedContext = .inner(.marketing(.positive(offer)))
        } else {
            updatedContext = .inner(.marketing(.negative(offer)))
        }

        let children = try transformChildren(model.children, context: updatedContext)

        return .creativeResponse(try getCreativeResponseUIModel(responseKey: responseKey,
                                                                openLinks: model.openLinks,
                                                                styles: model.styles,
                                                                children: children,
                                                                offer: offer))
    }

    func getCreativeResponseUIModel(responseKey: String,
                                    openLinks: LinkOpenTarget?,
                                    styles: LayoutStyle<CreativeResponseElements,
                                                        ConditionalStyleTransition<CreativeResponseTransitions, WhenPredicate>>?,
                                    children: [LayoutSchemaViewModel]?,
                                    offer: OfferModel?) throws -> CreativeResponseViewModel {
        var responseOption: ResponseOption?
        var creativeResponseKey = BNFNamespace.CreativeResponseKey.positive

        if responseKey == BNFNamespace.CreativeResponseKey.positive.rawValue {
            responseOption = offer?.creative.responseOptionsMap?.positive
            creativeResponseKey = .positive
        }

        if responseKey == BNFNamespace.CreativeResponseKey.negative.rawValue {
            responseOption = offer?.creative.responseOptionsMap?.negative
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

    private func getCatalogStackedCollectionModel(
        model: CatalogStackedCollectionModel<CatalogStackedCollectionLayoutSchemaTemplateNode, WhenPredicate>,
        context: Context
    ) throws -> CatalogStackedCollectionViewModel {
        guard case let .inner(.marketing(marketing)) = context, let offer = marketing.offer else {
            throw LayoutTransformerError.InvalidNode
        }

        let updateStyles = try StyleTransformer.updatedStyles(model.styles?.elements?.own)
        var children: [LayoutSchemaViewModel]? = try offer.catalogItems?.map { catalogItem in
            switch model.template {
            case .column(let model):
                return .column(
                    try getColumn(
                        model.styles,
                        children: transformChildren(
                            model.children,
                            context: .inner(.addToCart(catalogItem))
                        )
                    )
                )
            case .row(let model):
                return .row(
                    try getRow(
                        model.styles,
                        children: transformChildren(
                            model.children,
                            context: .inner(.addToCart(catalogItem))
                        )
                    )
                )
            default:
                throw RoktUXError.experienceResponseMapping
            }
        }
        return CatalogStackedCollectionViewModel(
            children: children,
            defaultStyle: updateStyles.compactMap {$0.default},
            layoutState: layoutState
        )
    }

    private func getCatalogResponseButtonModel(
        style: LayoutStyle<CatalogResponseButtonElements, ConditionalStyleTransition<CatalogResponseButtonTransitions, WhenPredicate>>?,
        children: [LayoutSchemaViewModel]?
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
            let indicatorData = try BNFCreativeDataExtractor().extractDataRepresentedBy(
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

    private func map(viewModel: LayoutSchemaViewModel, context: Context) {
        switch context {
        case .outer(let array):
            return
        case .inner(let inner):
            switch inner {
            case .addToCart(let item):
                BNFCatalogNodeMapper().map(consumer: viewModel, context: item)
            case .marketing(let marketing):
                switch marketing {
                case .positive(let offer):
                    BNFCreativeNodeMapper().map(consumer: viewModel, context: .positiveResponse(offer))
                case .negative(let offer):
                    BNFCreativeNodeMapper().map(consumer: viewModel, context: .negativeResponse(offer))
                case .generic(.some(let offer)):
                    BNFCreativeNodeMapper().map(consumer: viewModel, context: .marketing(offer))
                case .generic(.none):
                    break
                }
            }
        }
    }
}
