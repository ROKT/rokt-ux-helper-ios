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
struct LayoutTransformer<
    CreativeSyntaxMapper: SyntaxMapping,
    AddToCartMapper: SyntaxMapping,
    Extractor: DataExtracting
>
where CreativeSyntaxMapper.Context == CreativeContext, AddToCartMapper.Context == CatalogItem {

    enum Context {
        case outer([OfferModel?])
        case inner(Inner)

        enum Inner {
            case positive(OfferModel)
            case negative(OfferModel)
            case generic(OfferModel?)
            case addToCart(CatalogItem)
        }
    }

    let layoutPlugin: LayoutPlugin
    let layoutState: LayoutState
    let eventService: EventDiagnosticServicing?
    let creativeMapper: CreativeSyntaxMapper
    let addToCartMapper: AddToCartMapper
    let extractor: Extractor

    init(
        layoutPlugin: LayoutPlugin,
        creativeMapper: CreativeSyntaxMapper = CreativeMapper(),
        addToCartMapper: AddToCartMapper = CatalogMapper(),
        extractor: Extractor = CreativeDataExtractor(),
        layoutState: LayoutState = LayoutState(),
        eventService: EventDiagnosticServicing? = nil
    ) {
        self.layoutPlugin = layoutPlugin
        self.creativeMapper = creativeMapper
        self.addToCartMapper = addToCartMapper
        self.extractor = extractor
        self.layoutState = layoutState
        self.eventService = eventService
    }

    func transform() throws -> LayoutSchemaViewModel? {
        guard let layout = layoutPlugin.layout else { return nil}

        let transformedUIModels = try transform(
            layout,
            context: .outer(layoutPlugin.slots.map(\.offer))
        )

        AttributedStringTransformer.convertRichTextHTMLIfExists(uiModel: transformedUIModels, config: layoutState.config)

        return transformedUIModels
    }

    func transform<T: Codable>(_ layout: T, context: Context) throws -> LayoutSchemaViewModel {
        if let layout = layout as? LayoutSchemaModel {
            return try transform(layout, context: context)
        } else if let layout = layout as? AccessibilityGroupedLayoutChildren {
            return try transform(layout, context: context)
        } else {
            return .empty
        }
    }

    func transform(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        switch layout {
        case .row(let rowModel):
                .row(
                    try getRow(
                        rowModel.styles,
                        children: transformChildren(rowModel.children, context: context)
                    )
                )
        case .column(let columnModel):
                .column(
                    try getColumn(
                        columnModel.styles,
                        children: transformChildren(columnModel.children, context: context)
                    )
                )
        case .zStack(let zStackModel):
                .zStack(
                    try getZStack(
                        zStackModel.styles,
                        children: transformChildren(zStackModel.children, context: context)
                    )
                )
        case .basicText(let basicTextModel):
                .basicText(try getBasicText(basicTextModel, context: context))
        case .staticImage(let imageModel):
                .staticImage(try getStaticImage(imageModel))
        case .richText(let richTextModel):
                .richText(try getRichText(richTextModel, context: context))
        case .dataImage(let imageModel):
            try transformWithFallback {
                .dataImage(try getDataImage(imageModel, context: context))
            }
        case .progressIndicator(let progressIndicatorModel):
                .progressIndicator(try getProgressIndicatorUIModel(progressIndicatorModel, context: context))
        case .creativeResponse(let model):
            try getCreativeResponse(
                model: model,
                context: context
            )
        case .oneByOneDistribution(let oneByOneModel):
                .oneByOne(try getOneByOne(oneByOneModel: oneByOneModel, context: context))
        case .overlay(let overlayModel):
                .overlay(
                    try getOverlay(
                        overlayModel.styles,
                        allowBackdropToClose: overlayModel.allowBackdropToClose,
                        children: transformChildren(overlayModel.children, context: context)
                    )
                )
        case .bottomSheet(let bottomSheetModel):
                .bottomSheet(
                    try getBottomSheet(
                        bottomSheetModel.styles,
                        allowBackdropToClose: bottomSheetModel.allowBackdropToClose,
                        children: transformChildren(bottomSheetModel.children, context: context)
                    )
                )
        case .when(let whenModel):
                .when(
                    getWhenNode(
                        children: try transformChildren(whenModel.children, context: context),
                        predicates: whenModel.predicates,
                        transition: whenModel.transition
                    )
                )
        case .staticLink(let staticLinkModel):
                .staticLink(
                    try getStaticLink(
                        src: staticLinkModel.src,
                        open: staticLinkModel.open,
                        styles: staticLinkModel.styles,
                        children: transformChildren(staticLinkModel.children, context: context)
                    )
                )
        case .closeButton(let closeButtonModel):
                .closeButton(
                    try getCloseButton(
                        styles: closeButtonModel.styles,
                        children: transformChildren(closeButtonModel.children, context: context)
                    )
                )
        case .carouselDistribution(let carouselModel):
                .carousel(try getCarousel(carouselModel: carouselModel, context: context))
        case .groupedDistribution(let groupedModel):
                .groupDistribution(try getGroupedDistribution(groupedModel: groupedModel, context: context))
        case .progressControl(let progressControlModel):
                .progressControl(
                    try getProgressControl(
                        styles: progressControlModel.styles,
                        direction: progressControlModel.direction,
                        children: transformChildren(progressControlModel.children,
                                                    context: context)
                    )
                )
        case .accessibilityGrouped(let accessibilityGroupedModel):
            try getAccessibilityGrouped(
                child: accessibilityGroupedModel.child,
                context: context
            )
        case .scrollableColumn(let columnModel):
                .scrollableColumn(
                    try getScrollableColumn(
                        columnModel.styles,
                        children:
                            transformChildren(columnModel.children, context: context)
                    )
                )
        case .scrollableRow(let rowModel):
                .scrollableRow(
                    try getScrollableRow(
                        rowModel.styles,
                        children: transformChildren(rowModel.children, context: context)
                    )
                )
        case .toggleButtonStateTrigger(let buttonModel):
                .toggleButton(
                    try getToggleButton(
                        customStateKey: buttonModel.customStateKey,
                        styles: buttonModel.styles,
                        children: transformChildren(buttonModel.children,
                                                    context: context)
                    )
                )
        case .dataImageCarousel(let dataImageCarouselModel):
            try transformWithFallback {
                .dataImageCarousel(try getDataImageCarousel(dataImageCarouselModel, context: context))
            }
        case .catalogStackedCollection(let model):
                .catalogStackedCollection(
                    try getCatalogStackedCollectionModel(
                        model: model,
                        context: context
                    )
                )
        case .catalogDevicePayButton(let model):
                .catalogDevicePayButton(
                    try getCatalogDevicePayButtonModel(
                        style: model.styles,
                        children: transformChildren(model.children, context: context),
                        provider: model.provider,
                        context: context
                    )
                )
        case .catalogCombinedCollection(let model):
                .catalogCombinedCollection(
                    try getCatalogCombinedCollectionModel(
                        model: model,
                        context: context
                    )
                )
        case .catalogResponseButton(let model):
                .catalogResponseButton(
                    try getCatalogResponseButtonModel(
                        style: model.styles,
                        children: transformChildren(model.children, context: context),
                        context: context
                    )
                )
        case .catalogDropdown(let model):
                .catalogDropdown(
                    try getCatalogDropdownModel(
                        model: model,
                        context: context
                    )
                )
        }
    }

    func transform(
        _ layout: AccessibilityGroupedLayoutChildren,
        context: Context
    ) throws -> LayoutSchemaViewModel {
        switch layout {
        case .row(let rowModel):
                .row(try getRow(rowModel.styles, children: transformChildren(rowModel.children, context: context)))
        case .column(let columnModel):
            .column(
                try getColumn(
                    columnModel.styles,
                    children: transformChildren(columnModel.children, context: context)
                )
            )
        case .zStack(let zStackModel):
            .zStack(
                try getZStack(
                    zStackModel.styles,
                    children: transformChildren(zStackModel.children, context: context)
                )
            )
        }
    }

    func transformChildren<T: Codable>(_ layouts: [T]?, context: Context) throws -> [LayoutSchemaViewModel]? {
        try layouts?.map {
            try transform($0, context: context)
        }
    }

    // attach inner layout into outer layout and transform to UI Model
    func getOneByOne(oneByOneModel: OneByOneDistributionModel<WhenPredicate>, context: Context) throws -> OneByOneViewModel {
        let children: [LayoutSchemaViewModel] = try layoutPlugin.slots.compactMap {
            guard let innerLayout = $0.layoutVariant?.layoutVariantSchema else { return nil }
            return try transform(innerLayout, context: .inner(.generic($0.offer)))
        }
        let updateStyles = try StyleTransformer.updatedStyles(oneByOneModel.styles?.elements?.own)
        return OneByOneViewModel(children: children,
                                 defaultStyle: updateStyles.compactMap {$0.default},
                                 transition: oneByOneModel.transition,
                                 eventService: eventService,
                                 slots: layoutPlugin.slots,
                                 layoutState: layoutState)
    }

    func getCarousel(carouselModel: CarouselDistributionModel<WhenPredicate>, context: Context) throws -> CarouselViewModel {
        let children: [LayoutSchemaViewModel] = try layoutPlugin.slots.compactMap {
            guard let innerLayout = $0.layoutVariant?.layoutVariantSchema else { return nil }
            return try transform(innerLayout, context: .inner(.generic($0.offer)))
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
        groupedModel: GroupedDistributionModel<WhenPredicate>,
        context: Context
    ) throws -> GroupedDistributionViewModel {
        let children: [LayoutSchemaViewModel] = try layoutPlugin.slots.compactMap {
            guard let innerLayout = $0.layoutVariant?.layoutVariantSchema else { return nil }
            return try transform(innerLayout, context: .inner(.generic($0.offer)))
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
        let updatedStyles = try StyleTransformer.updatedStyles(imageModel.styles?.elements?.own, transform: BaseStyles.init)
        return StaticImageViewModel(url: imageModel.url,
                                    alt: imageModel.alt,
                                    stylingProperties: updatedStyles,
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
        var creativeImage: CreativeImage?
        switch context {
        case .inner(.generic(.some(let offer))),
                .inner(.negative(let offer)),
                .inner(.positive(let offer)):
            creativeImage = findImage(for: imageModel.imageKey, in: offer.creative.images)
        case let .inner(.addToCart(catalogItem)):
            creativeImage = findImage(for: imageModel.imageKey, in: catalogItem.images)
        default:
            throw LayoutTransformerError.missingData
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
        let vm = BasicTextViewModel(value: basicTextModel.value,
                                    defaultStyle: updateStyles.compactMap {$0.default},
                                    pressedStyle: updateStyles.compactMap {$0.pressed},
                                    hoveredStyle: updateStyles.compactMap {$0.hovered},
                                    disabledStyle: updateStyles.compactMap {$0.disabled},
                                    layoutState: layoutState,
                                    diagnosticService: eventService)
        if case .inner = context, let bnfContext = context.mapToCreativeContext {
            creativeMapper.map(consumer: .basicText(vm), context: bnfContext)
        } else if case let .inner(.addToCart(catalogItem)) = context {
            addToCartMapper.map(consumer: .basicText(vm), context: catalogItem)
        }
        return vm
    }

    func getRichText(_ richTextModel: RichTextModel<WhenPredicate>, context: Context) throws -> RichTextViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(richTextModel.styles?.elements?.own)
        let updateLinkStyles = try StyleTransformer.updatedStyles(richTextModel.styles?.elements?.link)
        let vm = RichTextViewModel(value: richTextModel.value,
                                   defaultStyle: updateStyles.compactMap {$0.default},
                                   linkStyle: updateLinkStyles.compactMap {$0.default},
                                   openLinks: richTextModel.openLinks,
                                   layoutState: layoutState,
                                   eventService: eventService)

        if case .inner = context, let bnfContext = context.mapToCreativeContext {
            creativeMapper.map(consumer: .richText(vm), context: bnfContext)
        } else if case let .inner(.addToCart(catalogItem)) = context {
            addToCartMapper.map(consumer: .richText(vm), context: catalogItem)
        }
        return vm
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
        let updatedStyles = try StyleTransformer.updatedStyles(styles?.elements?.own, transform: BaseStyles.init)

        return RowViewModel(
            children: children,
            stylingProperties: updatedStyles,
            animatableStyle: AnimationStyle(
                transition: styles?.conditionalTransitions,
                transform: { $0.own.map(BaseStyles.init) }
            ),
            accessibilityGrouped: accessibilityGrouped,
            layoutState: layoutState,
            predicates: styles?.conditionalTransitions?.predicates,
            globalBreakPoints: layoutPlugin.breakpoints,
            offers: layoutPlugin.slots.map(\.offer)
        )
    }

    func getScrollableRow(_ styles: LayoutStyle<ScrollableRowElements,
                                                ConditionalStyleTransition<ScrollableRowTransitions, WhenPredicate>>?,
                          children: [LayoutSchemaViewModel]?,
                          accessibilityGrouped: Bool = false) throws -> RowViewModel {
        let updatedStyles = try StyleTransformer.updatedStyles(styles?.elements?.own, transform: BaseStyles.init)

        return RowViewModel(
            children: children,
            stylingProperties: updatedStyles,
            animatableStyle: AnimationStyle(
                transition: styles?.conditionalTransitions,
                transform: { $0.own.map(BaseStyles.init) }
            ),
            accessibilityGrouped: accessibilityGrouped,
            layoutState: layoutState,
            predicates: styles?.conditionalTransitions?.predicates,
            globalBreakPoints: layoutPlugin.breakpoints,
            offers: layoutPlugin.slots.map(\.offer)
        )
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
                                 context: Context) throws -> LayoutSchemaViewModel {
        switch child {
        case .column(let columnModel):
            return .column(try getColumn(columnModel.styles,
                                         children: transformChildren(columnModel.children, context: context),
                                         accessibilityGrouped: true))
        case .row(let rowModel):
            return .row(try getRow(rowModel.styles,
                                   children: transformChildren(rowModel.children, context: context),
                                   accessibilityGrouped: true))
        case .zStack(let zStackModel):
            return .zStack(try getZStack(zStackModel.styles,
                                         children: transformChildren(zStackModel.children, context: context),
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

    func getCreativeResponse(model: CreativeResponseModel<LayoutSchemaModel, WhenPredicate>,
                             context: Context) throws -> LayoutSchemaViewModel {
        guard case let .inner(.generic(offer)) = context, let offer else {
            throw LayoutTransformerError.InvalidMapping()
        }
        var updatedContext: Context
        if model.responseKey == BNFNamespace.CreativeResponseKey.positive.rawValue,
           offer.creative.responseOptionsMap?.positive != nil {
            updatedContext = .inner(.positive(offer))
        } else if model.responseKey == BNFNamespace.CreativeResponseKey.negative.rawValue,
                  offer.creative.responseOptionsMap?.negative != nil {
            updatedContext = .inner(.negative(offer))
        } else {
            return .empty
        }
        let children = try transformChildren(model.children, context: updatedContext)
        return .creativeResponse(try getCreativeResponseUIModel(responseKey: model.responseKey,
                                                                openLinks: model.openLinks,
                                                                styles: model.styles,
                                                                children: children,
                                                                offer: offer))
    }

    func getCreativeResponseUIModel(
        responseKey: String,
        openLinks: LinkOpenTarget?,
        styles: LayoutStyle<CreativeResponseElements,
                            ConditionalStyleTransition<CreativeResponseTransitions, WhenPredicate>>?,
        children: [LayoutSchemaViewModel]?,
        offer: OfferModel
    ) throws -> CreativeResponseViewModel {
        var responseOption: RoktUXResponseOption?
        var creativeResponseKey = BNFNamespace.CreativeResponseKey.positive

        if responseKey == BNFNamespace.CreativeResponseKey.positive.rawValue {
            responseOption = offer.creative.responseOptionsMap?.positive
            creativeResponseKey = .positive
        }

        if responseKey == BNFNamespace.CreativeResponseKey.negative.rawValue {
            responseOption = offer.creative.responseOptionsMap?.negative
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
        context: Context,
        accessibilityGrouped: Bool = false
    ) throws -> CatalogStackedCollectionViewModel {
        guard case let .inner(.generic(.some(offer))) = context else {
            throw LayoutTransformerError.InvalidMapping()
        }

        let updateStyles = try StyleTransformer.updatedStyles(model.styles?.elements?.own)
        let children: [LayoutSchemaViewModel]? = try offer.catalogItems?.map { catalogItem in
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
            }
        }
        return CatalogStackedCollectionViewModel(
            children: children,
            defaultStyle: updateStyles.compactMap {$0.default},
            layoutState: layoutState
        )
    }

    func getCatalogCombinedCollectionModel(
        model: CatalogCombinedCollectionModel<CatalogCombinedCollectionLayoutSchemaTemplateNode, WhenPredicate>,
        context: Context,
        accessibilityGrouped: Bool = false
    ) throws -> CatalogCombinedCollectionViewModel {
        guard case let .inner(.generic(.some(offer))) = context else {
            throw LayoutTransformerError.InvalidMapping()
        }

        // Set the first catalog item as active
        if let firstCatalogItem = offer.catalogItems?.first {
            layoutState.items[LayoutState.activeCatalogItemKey] = firstCatalogItem
        }

        // Store the full offer for dropdown access
        layoutState.items[LayoutState.fullOfferKey] = offer

        let updateStyles = try StyleTransformer.updatedStyles(model.styles?.elements?.own)

        let childBuilder: (CatalogItem) -> [LayoutSchemaViewModel]? = { catalogItem in
            do {
                switch model.template {
                case .column(let templateModel):
                    let transformedChildren = try self.transformChildren(
                        templateModel.children,
                        context: .inner(.addToCart(catalogItem))
                    )

                    return [
                        .column(
                            try self.getColumn(
                                templateModel.styles,
                                children: transformedChildren
                            )
                        )
                    ]
                case .row(let templateModel):
                    let transformedChildren = try self.transformChildren(
                        templateModel.children,
                        context: .inner(.addToCart(catalogItem))
                    )

                    return [
                        .row(
                            try self.getRow(
                                templateModel.styles,
                                children: transformedChildren
                            )
                        )
                    ]
                }
            } catch {
                return nil
            }
        }

        let initialChildren = offer.catalogItems?.first.flatMap(childBuilder) ?? []

        return CatalogCombinedCollectionViewModel(
            children: initialChildren,
            defaultStyle: updateStyles.compactMap { $0.default },
            layoutState: layoutState,
            childBuilder: childBuilder
        )
    }

    func getCatalogResponseButtonModel(
        style: LayoutStyle<
            CatalogResponseButtonElements,
            ConditionalStyleTransition<CatalogResponseButtonTransitions, WhenPredicate>
        >?,
        children: [LayoutSchemaViewModel]?,
        context: Context
    ) throws -> CatalogResponseButtonViewModel {
        guard case let .inner(.addToCart(catalogItem)) = context else {
            throw LayoutTransformerError.InvalidMapping()
        }

        let updateStyles = try StyleTransformer.updatedStyles(style?.elements?.own)
        return CatalogResponseButtonViewModel(
            catalogItem: catalogItem,
            children: children,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: updateStyles.compactMap { $0.default },
            pressedStyle: updateStyles.compactMap { $0.pressed },
            hoveredStyle: updateStyles.compactMap { $0.hovered },
            disabledStyle: updateStyles.compactMap { $0.disabled }
        )
    }

     func getCatalogDevicePayButtonModel(
         style: LayoutStyle<
             CatalogDevicePayButtonElements,
             ConditionalStyleTransition<CatalogDevicePayButtonTransitions, WhenPredicate>
         >?,
         children: [LayoutSchemaViewModel]?,
         provider: PaymentProvider,
         context: Context
     ) throws -> CatalogDevicePayButtonViewModel {
        guard case let .inner(.addToCart(catalogItem)) = context else {
            throw LayoutTransformerError.InvalidMapping()
        }
        let updateStyles = try StyleTransformer.updatedStyles(style?.elements?.own)
        return CatalogDevicePayButtonViewModel(
            catalogItem: catalogItem,
            children: children,
            provider: provider,
            layoutState: layoutState,
            eventService: eventService,
            defaultStyle: updateStyles.compactMap {$0.default},
            pressedStyle: updateStyles.compactMap {$0.pressed},
            hoveredStyle: updateStyles.compactMap {$0.hovered},
            disabledStyle: updateStyles.compactMap {$0.disabled}
        )
    }

    func getCatalogDropdownModel(
        model: CatalogDropdownModel<LayoutSchemaModel, WhenPredicate>,
        context: Context
    ) throws -> CatalogDropdownViewModel {
        guard case .inner(.addToCart) = context else {
            throw LayoutTransformerError.InvalidMapping()
        }

        // Get the full offer from layoutState to access all catalog items
        guard let fullOffer = layoutState.items[LayoutState.fullOfferKey] as? OfferModel else {
            throw LayoutTransformerError.InvalidMapping()
        }

        let closedTemplate = try transform(model.closedTemplate, context: context)
        let closedDefaultTemplate = try transform(model.closedDefaultTemplate, context: context)
        let requiredSelectionErrorTemplate = try transform(model.requiredSelectionErrorTemplate, context: context)

        // Create openDropdownChildren array - one template per catalog item from the full offer
        let openDropdownChildren: [LayoutSchemaViewModel] = try fullOffer.catalogItems?.map { catalogItemFromOffer in
            try transform(model.openTemplate, context: .inner(.addToCart(catalogItemFromOffer)))
        } ?? []
        let updateStyles = try StyleTransformer.updatedStyles(model.styles?.elements?.own)
        let dropdownListItemStyles = try StyleTransformer.updatedStyles(model.styles?.elements?.dropDownListItem)
        let dropdownSelectedItemStyles = try StyleTransformer.updatedStyles(model.styles?.elements?.dropDownSelectedItem)
        let dropdownListContainerStyles = try StyleTransformer.updatedStyles(model.styles?.elements?.dropDownListContainer)
        return CatalogDropdownViewModel(layoutState: layoutState,
                                        defaultStyle: updateStyles.compactMap {$0.default},
                                        pressedStyle: updateStyles.compactMap {$0.pressed},
                                        hoveredStyle: updateStyles.compactMap {$0.hovered},
                                        disabledStyle: updateStyles.compactMap {$0.disabled},
                                        dropDownListItemDefaultStyle: dropdownListItemStyles.compactMap { $0.default },
                                        dropDownListItemPressedStyle: dropdownListItemStyles.compactMap { $0.pressed },
                                        dropDownListItemHoveredStyle: dropdownListItemStyles.compactMap { $0.hovered },
                                        dropDownListItemDisabledStyle: dropdownListItemStyles.compactMap { $0.disabled },
                                        dropDownSelectedItemDefaultStyle: dropdownSelectedItemStyles.compactMap { $0.default },
                                        dropDownSelectedItemPressedStyle: dropdownSelectedItemStyles.compactMap { $0.pressed },
                                        dropDownSelectedItemHoveredStyle: dropdownSelectedItemStyles.compactMap { $0.hovered },
                                        dropDownSelectedItemDisabledStyle: dropdownSelectedItemStyles.compactMap { $0.disabled },
                                        dropDownListContainerDefaultStyle: dropdownListContainerStyles.compactMap { $0.default },
                                        dropDownListContainerPressedStyle: dropdownListContainerStyles.compactMap { $0.pressed },
                                        dropDownListContainerHoveredStyle: dropdownListContainerStyles.compactMap { $0.hovered },
                                        dropDownListContainerDisabledStyle: dropdownListContainerStyles
                                        .compactMap { $0.disabled },
                                        a11yLabel: model.a11yLabel,
                                        openDropdownChildren: openDropdownChildren,
                                        closedTemplate: closedTemplate,
                                        closedDefaultTemplate: closedDefaultTemplate,
                                        requiredSelectionErrorTemplate: requiredSelectionErrorTemplate,
                                        eventService: eventService)
    }

    func getProgressIndicatorUIModel(
        _ progressIndicatorModel: ProgressIndicatorModel<WhenPredicate>,
        context: Context
    ) throws -> ProgressIndicatorViewModel {
        let updateStyles = try StyleTransformer.updatedStyles(progressIndicatorModel.styles?.elements?.own)
        let indicatorStyle = try StyleTransformer.updatedStyles(progressIndicatorModel.styles?.elements?.indicator)
        let seenIndicatorStyle = try StyleTransformer.updatedIndicatorStyles(
            indicatorStyle,
            newStyles: progressIndicatorModel.styles?.elements?.seenIndicator
        )
        // active falls back to seen (which then falls back to indicator)
        let activeIndicatorStyle = try StyleTransformer.updatedIndicatorStyles(
            seenIndicatorStyle,
            newStyles: progressIndicatorModel.styles?.elements?.activeIndicator
        )
        let vm = ProgressIndicatorViewModel(
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
        if let bnfContext = context.mapToCreativeContext {
            creativeMapper.map(consumer: .progressIndicator(vm), context: bnfContext)
        } else if case let .inner(.addToCart(catalogItem)) = context {
            addToCartMapper.map(consumer: .progressIndicator(vm), context: catalogItem)
        }
        return vm
    }

    func getWhenNode(children: [LayoutSchemaViewModel]?,
                     predicates: [WhenPredicate],
                     transition: WhenTransition?) -> WhenViewModel {
        return WhenViewModel(children: children,
                             predicates: predicates,
                             transition: transition,
                             offers: layoutPlugin.slots.map(\.offer),
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

    func getDataImageCarousel(_ dataImageCarouselModel: DataImageCarouselModel<WhenPredicate>,
                              context: Context) throws -> DataImageCarouselViewModel {
        var carouselImages: [CreativeImage]?
        switch context {
        case .inner(.generic(let offer?)),
                .inner(.negative(let offer)),
                .inner(.positive(let offer)):
            let imageKeys = dataImageCarouselModel.imageKey.split(separator: "|").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            carouselImages = offer.creative.images?.filter { image in
                imageKeys.contains { key in
                    image.key.contains(key)
                }
            }
            .sorted(by: { $0.key < $1.key })
            .compactMap { $0.value }
        default:
            throw LayoutTransformerError.InvalidMapping()
        }
        guard let carouselImages else { throw LayoutTransformerError.missingData }

        let ownStyle = try StyleTransformer.updatedStyles(dataImageCarouselModel.styles?.elements?.own)
        let indicatorStyle = try StyleTransformer.updatedStyles(dataImageCarouselModel.styles?.elements?.indicator)
        let seenIndicatorStyle = try StyleTransformer.updatedIndicatorStyles(
            indicatorStyle,
            newStyles: dataImageCarouselModel.styles?.elements?.seenIndicator
        )
        // active falls back to seen (which then falls back to indicator)
        let activeIndicatorStyle = try StyleTransformer.updatedIndicatorStyles(
            seenIndicatorStyle,
            newStyles: dataImageCarouselModel.styles?.elements?.activeIndicator
        )
        let indicatorContainerStyle = try StyleTransformer
            .updatedStyles(dataImageCarouselModel.styles?.elements?.progressIndicatorContainer)
        return DataImageCarouselViewModel(key: dataImageCarouselModel.imageKey,
                                          images: carouselImages,
                                          duration: dataImageCarouselModel.duration,
                                          ownStyle: ownStyle,
                                          indicatorStyle: indicatorStyle,
                                          seenIndicatorStyle: seenIndicatorStyle,
                                          activeIndicatorStyle: activeIndicatorStyle,
                                          indicatorContainer: indicatorContainerStyle,
                                          layoutState: layoutState)
    }

    private func transformWithFallback(_ transform: () throws -> LayoutSchemaViewModel) throws -> LayoutSchemaViewModel {
        do {
           return try transform()
        } catch LayoutTransformerError.missingData {
            return .empty
        } catch {
            throw error
        }
    }

    private func findImage(for key: String, in images: [String: CreativeImage]?) -> CreativeImage? {
        let imageKeys = key.split(separator: "|").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        for imageKey in imageKeys {
            if let image = images?[imageKey] {
                return image
            }
        }
        return nil
    }
}

@available(iOS 15, *)
private extension LayoutTransformer.Context {
    var mapToCreativeContext: CreativeContext? {
        switch self {
        case .outer:
                .outer
        case .inner(let inner):
            switch inner {
            case .positive(let offerModel):
                    .positiveResponse(offerModel)
            case .negative(let offerModel):
                    .negativeResponse(offerModel)
            case .generic(let offerModel):
                    .generic(offerModel)
            case .addToCart:
                nil
            }
        }
    }
}
