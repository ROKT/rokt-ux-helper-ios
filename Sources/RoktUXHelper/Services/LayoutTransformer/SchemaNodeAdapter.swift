import DcuiSchema

protocol InlineSchemaChild: Decodable {
    var commonInline: InlineChildren { get }
}

protocol InlineTextSchemaChild: InlineSchemaChild {
    var commonText: InlineBasicTextModel<WhenPredicate> { get }
}

extension InlineTextSchemaChild {
    var commonInline: InlineChildren { .basicText(commonText) }
}

extension InlineChildren: InlineSchemaChild {
    var commonInline: InlineChildren { self }
}

extension NonInteractableInlineChildren: InlineTextSchemaChild {
    var commonText: InlineBasicTextModel<WhenPredicate> {
        switch self {
        case .basicText(let model): model
        }
    }
}

extension LayoutVariantNonInteractableInlineChildren: InlineTextSchemaChild {
    var commonText: InlineBasicTextModel<WhenPredicate> {
        switch self {
        case .basicText(let model): SchemaNodeAdapter.text(model)
        }
    }
}

extension OuterLayoutNonInteractableInlineChildren: InlineTextSchemaChild {
    var commonText: InlineBasicTextModel<WhenPredicate> {
        switch self {
        case .basicText(let model): SchemaNodeAdapter.text(model)
        }
    }
}

extension LayoutVariantInlineChildren: InlineSchemaChild {
    var commonInline: InlineChildren {
        switch self {
        case .basicText(let model): .basicText(SchemaNodeAdapter.text(model))
        case .staticLink(let model): .staticLink(SchemaNodeAdapter.link(model))
        case .toggleButtonStateTrigger(let model): .toggleButtonStateTrigger(SchemaNodeAdapter.toggle(model))
        }
    }
}

extension OuterLayoutInlineChildren: InlineSchemaChild {
    var commonInline: InlineChildren {
        switch self {
        case .basicText(let model): .basicText(SchemaNodeAdapter.text(model))
        case .staticLink(let model): .staticLink(SchemaNodeAdapter.link(model))
        case .toggleButtonStateTrigger(let model): .toggleButtonStateTrigger(SchemaNodeAdapter.toggle(model))
        }
    }
}

protocol CatalogCardSchemaNode: Decodable {
    func commonLayout() throws -> LayoutSchemaModel
}

extension CatalogCarouselCollectionTemplateNode: CatalogCardSchemaNode {
    func commonLayout() throws -> LayoutSchemaModel {
        switch self {
        case .row(let model): try SchemaNodeAdapter.row(model)
        case .column(let model): try SchemaNodeAdapter.column(model)
        }
    }
}

extension CatalogCarouselCollectionTemplateNodeChildren: CatalogCardSchemaNode {
    func commonLayout() throws -> LayoutSchemaModel {
        switch self {
        case .row(let model): try SchemaNodeAdapter.row(model)
        case .column(let model): try SchemaNodeAdapter.column(model)
        case .zStack(let model): try SchemaNodeAdapter.zStack(model)
        case .staticImage(let model): try SchemaNodeAdapter.staticImage(model)
        case .dataImage(let model): try SchemaNodeAdapter.dataImage(model)
        case .basicText(let model): try SchemaNodeAdapter.basicText(model)
        case .richText(let model): try SchemaNodeAdapter.richText(model)
        case .when(let model): try SchemaNodeAdapter.when(model)
        case .staticLink(let model):
            .staticLink(StaticLinkModel(a11yLabel: model.a11yLabel, src: model.src, open: model.open,
                                        styles: try SchemaNodeAdapter.cardStyle(model.styles, blocks: model.styles?.elements?.own,
                                                                                node: "StaticLink"),
                                        children: try model.children.map { try $0.commonLayout() }))
        case .toggleButtonStateTrigger(let model):
            .toggleButtonStateTrigger(ToggleButtonStateTriggerModel(
                a11yLabel: model.a11yLabel,
                styles: try SchemaNodeAdapter.cardStyle(model.styles, blocks: model.styles?.elements?.own,
                                                        node: "ToggleButtonStateTrigger"),
                children: try model.children.map { try $0.commonLayout() }, customStateKey: model.customStateKey
            ))
        case .catalogResponseButton(let model):
            try SchemaNodeAdapter.response(model)
        case .inlineContainer(let model):
            .inlineContainer(try SchemaNodeAdapter.inlineContainer(model))
        }
    }
}

extension CatalogCarouselCollectionNonInteractableChildren: CatalogCardSchemaNode {
    func commonLayout() throws -> LayoutSchemaModel {
        switch self {
        case .row(let model): try SchemaNodeAdapter.row(model)
        case .column(let model): try SchemaNodeAdapter.column(model)
        case .zStack(let model): try SchemaNodeAdapter.zStack(model)
        case .staticImage(let model): try SchemaNodeAdapter.staticImage(model)
        case .dataImage(let model): try SchemaNodeAdapter.dataImage(model)
        case .basicText(let model): try SchemaNodeAdapter.basicText(model)
        case .richText(let model): try SchemaNodeAdapter.richText(model)
        case .when(let model): try SchemaNodeAdapter.when(model)
        case .inlineContainer(let model): .inlineContainer(try SchemaNodeAdapter.inlineContainer(model))
        }
    }
}

enum SchemaNodeAdapter {
    static func validateUnboundInlinePredicates(_ model: InlineContainerModel<InlineChildren, WhenPredicate>) throws {
        var predicates = model.styles?.conditionalTransitions?.predicates ?? []
        for child in model.children {
            switch child {
            case .basicText(let model): predicates += model.styles?.conditionalTransitions?.predicates ?? []
            case .staticLink(let model):
                predicates += model.styles?.conditionalTransitions?.predicates ?? []
                predicates += model.children.flatMap { $0.commonText.styles?.conditionalTransitions?.predicates ?? [] }
            case .toggleButtonStateTrigger(let model):
                predicates += model.styles?.conditionalTransitions?.predicates ?? []
                predicates += model.children.flatMap { $0.commonText.styles?.conditionalTransitions?.predicates ?? [] }
            }
        }
        try SchemaStyleAdapter.validateUnboundPredicates(predicates)
    }

    static func text<P: SchemaPredicateConvertible>(_ model: InlineBasicTextModel<P>) -> InlineBasicTextModel<WhenPredicate> {
        InlineBasicTextModel(styles: SchemaStyleAdapter.normalized(model.styles), value: model.value)
    }

    static func link<C: InlineTextSchemaChild, P: SchemaPredicateConvertible>(
        _ model: InlineStaticLinkModel<C, P>
    ) -> InlineStaticLinkModel<NonInteractableInlineChildren, WhenPredicate> {
        InlineStaticLinkModel(a11yLabel: model.a11yLabel, src: model.src, open: model.open,
                              styles: SchemaStyleAdapter.normalized(model.styles),
                              children: model.children.map { .basicText($0.commonText) })
    }

    static func toggle<C: InlineTextSchemaChild, P: SchemaPredicateConvertible>(
        _ model: InlineToggleButtonStateTriggerModel<C, P>
    ) -> InlineToggleButtonStateTriggerModel<NonInteractableInlineChildren, WhenPredicate> {
        InlineToggleButtonStateTriggerModel(a11yLabel: model.a11yLabel, styles: SchemaStyleAdapter.normalized(model.styles),
                                            children: model.children.map { .basicText($0.commonText) },
                                            customStateKey: model.customStateKey)
    }

    static func inlineContainer<C: InlineSchemaChild, P: SchemaPredicateConvertible>(
        _ model: InlineContainerModel<C, P>
    ) throws -> InlineContainerModel<InlineChildren, WhenPredicate> {
        _ = try SchemaStyleAdapter.inlineContainer(model.styles)
        let children = model.children.map(\.commonInline)
        for child in children {
            switch child {
            case .basicText(let text): _ = try SchemaStyleAdapter.inlineText(text.styles)
            case .staticLink(let link):
                _ = try SchemaStyleAdapter.inlineLink(link.styles)
                for text in link.children { _ = try SchemaStyleAdapter.inlineText(text.commonText.styles) }
            case .toggleButtonStateTrigger(let toggle):
                _ = try SchemaStyleAdapter.inlineToggle(toggle.styles)
                for text in toggle.children { _ = try SchemaStyleAdapter.inlineText(text.commonText.styles) }
            }
        }
        return InlineContainerModel(
            a11yLabel: model.a11yLabel,
            styles: SchemaStyleAdapter.normalized(model.styles),
            children: children
        )
    }

    static func row<C: CatalogCardSchemaNode>(_ model: RowModel<C, LayoutVariantWhenPredicate>) throws -> LayoutSchemaModel {
        try rejectNondefaultStates(model.styles?.elements?.own, node: "Row")
        return .row(RowModel(styles: try cardStyle(model.styles, blocks: model.styles?.elements?.own, node: "Row",
                                                   allowsTransition: true),
                             children: try model.children.map { try $0.commonLayout() }))
    }

    static func column<C: CatalogCardSchemaNode>(_ model: ColumnModel<C, LayoutVariantWhenPredicate>) throws
        -> LayoutSchemaModel {
        .column(ColumnModel(styles: try cardStyle(model.styles, blocks: model.styles?.elements?.own, node: "Column"),
                            children: try model.children.map { try $0.commonLayout() }))
    }

    static func zStack<C: CatalogCardSchemaNode>(_ model: ZStackModel<C, LayoutVariantWhenPredicate>) throws
        -> LayoutSchemaModel {
        .zStack(ZStackModel(styles: try cardStyle(model.styles, blocks: model.styles?.elements?.own, node: "ZStack"),
                            children: try model.children.map { try $0.commonLayout() }))
    }

    static func staticImage(_ model: StaticImageModel<LayoutVariantWhenPredicate>) throws -> LayoutSchemaModel {
        guard model.title == nil else { throw LayoutTransformerError.unsupportedFeature("catalogCard.StaticImage.title") }
        return .staticImage(StaticImageModel(
            styles: try cardStyle(model.styles, blocks: model.styles?.elements?.own, node: "StaticImage"),
            alt: model.alt, title: nil, url: model.url
        ))
    }

    static func dataImage(_ model: DataImageModel<LayoutVariantWhenPredicate>) throws -> LayoutSchemaModel {
        .dataImage(DataImageModel(styles: try cardStyle(model.styles, blocks: model.styles?.elements?.own, node: "DataImage"),
                                  imageKey: model.imageKey))
    }

    static func basicText(_ model: BasicTextModel<LayoutVariantWhenPredicate>) throws -> LayoutSchemaModel {
        .basicText(BasicTextModel(styles: try cardStyle(model.styles, blocks: model.styles?.elements?.own, node: "BasicText"),
                                  value: model.value))
    }

    static func richText(_ model: RichTextModel<LayoutVariantWhenPredicate>) throws -> LayoutSchemaModel {
        try rejectNondefaultStates(model.styles?.elements?.own, node: "RichText.own")
        try rejectNondefaultStates(model.styles?.elements?.link, node: "RichText.link")
        for block in model.styles?.elements?.link ?? [] {
            _ = try StyleTransformer.updatedStyle(block.default, newStyle: nil)
        }
        return .richText(RichTextModel(styles: try cardStyle(model.styles, blocks: model.styles?.elements?.own, node: "RichText"),
                                       openLinks: model.openLinks, value: model.value))
    }

    private static func rejectNondefaultStates<T>(_ blocks: [BasicStateStylingBlock<T>]?, node: String) throws {
        if blocks?
            .contains(where: { $0.pressed != nil || $0.hovered != nil || $0.disabled != nil || $0.focussed != nil }) == true {
            throw LayoutTransformerError.unsupportedFeature("catalogCard.\(node) nondefault state")
        }
    }

    static func when<C: CatalogCardSchemaNode>(_ model: WhenModel<C, LayoutVariantWhenPredicate>) throws -> LayoutSchemaModel {
        guard model.hide != .visually else {
            throw LayoutTransformerError.unsupportedFeature("catalogCard.When.hide.visually")
        }
        let predicates = model.predicates.map(\.commonPredicate)
        try SchemaStyleAdapter.validatePredicates(predicates)
        return .when(WhenModel(predicates: predicates, children: try model.children.map { try $0.commonLayout() },
                               transition: model.transition, hide: model.hide))
    }

    static func response(
        _ model: CatalogResponseButtonModel<CatalogCarouselCollectionNonInteractableChildren, LayoutVariantWhenPredicate>
    ) throws -> LayoutSchemaModel {
        guard model.validatorTriggerConfig == nil else {
            throw LayoutTransformerError.unsupportedFeature("catalogCard.CatalogResponseButton.validatorTriggerConfig")
        }
        return .catalogResponseButton(CatalogResponseButtonModel(
            a11yLabel: model.a11yLabel, responseKey: model.responseKey,
            styles: try cardStyle(model.styles, blocks: model.styles?.elements?.own, node: "CatalogResponseButton"),
            validatorTriggerConfig: nil, children: try model.children.map { try $0.commonLayout() }
        ))
    }

    static func cardStyle<E, S, T: SchemaRenderableStyle>(
        _ style: LayoutStyle<E, ConditionalStyleTransition<S, LayoutVariantWhenPredicate>>?,
        blocks: [BasicStateStylingBlock<T>]?, node: String, allowsTransition: Bool = false
    ) throws -> LayoutStyle<E, ConditionalStyleTransition<S, WhenPredicate>>? {
        if blocks?.contains(where: { $0.focussed != nil }) == true {
            throw LayoutTransformerError.unsupportedFeature("catalogCard.\(node).focussed style")
        }
        for block in blocks ?? [] {
            for style in [block.default, block.pressed, block.hovered, block.disabled].compactMap({ $0 }) {
                try SchemaStyleValidation.validate(style, node: "catalogCard.\(node)")
            }
        }
        if !allowsTransition { try SchemaStyleAdapter.rejectTransition(style, node: "catalogCard.\(node)") }
        if let transition = style?.conditionalTransitions {
            try SchemaStyleAdapter.validatePredicates(transition.predicates.map(\.commonPredicate))
            try SchemaStyleValidation.duration(transition.duration)
            if let row = (transition.value as? RowTransitions)?.own {
                try SchemaStyleValidation.validate(row, node: "catalogCard.Row.conditionalTransitions")
            }
        }
        return SchemaStyleAdapter.normalized(style)
    }
}
