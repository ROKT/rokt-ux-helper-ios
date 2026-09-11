import Foundation
import DcuiSchema

@available(iOS 15, *)
extension LayoutTransformer {
    func validateNonInteractiveChildren(_ children: [LayoutSchemaModel]) throws {
        try withSchemaValidation {
            try SchemaInteractionValidation.validate(children,
                                                     slotSchemas: layoutPlugin.slots
                                                     .compactMap { $0.layoutVariant?.layoutVariantSchema })
        }
    }

    func transformNonInteractiveChildren(_ children: [LayoutSchemaModel], context: Context) throws -> [LayoutSchemaViewModel]? {
        try validateNonInteractiveChildren(children)
        return try transformChildren(children, context: context)
    }

    func resolveAccessibilityLabel(_ value: String?, context: Context) throws -> String? {
        guard let value else { return nil }
        let model = try getBasicText(BasicTextModel(styles: nil, value: value), context: context)
        let label = model.inlineResolvedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? nil : label
    }

    func withSchemaValidation<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch let LayoutTransformerError.unsupportedFeature(feature) {
            eventService?.sendDiagnostics(message: "Unsupported layout feature", callStack: feature)
            throw LayoutTransformerError.unsupportedFeature(feature)
        }
    }

    func getInlineContainer<C: InlineSchemaChild, P: SchemaPredicateConvertible>(
        _ schema: InlineContainerModel<C, P>, context: Context
    ) throws -> InlineContainerViewModel {
        let schema = try SchemaNodeAdapter.inlineContainer(schema)
        if case .inner(.addToCart) = context { try SchemaNodeAdapter.validateUnboundInlinePredicates(schema) }
        let styles = try SchemaStyleAdapter.inlineContainer(schema.styles)
        var conditions: [UUID: ConditionalStyleBinding] = [:]

        func makeText(_ schema: InlineBasicTextModel<WhenPredicate>) throws -> BasicTextViewModel {
            let styles = try SchemaStyleAdapter.inlineText(schema.styles)
            let model = try getBasicText(BasicTextModel(styles: styles, value: schema.value), context: context)
            conditions[model.id] = makeConditionalStyle(styles?.conditionalTransitions, context: context) {
                $0.own.map(BaseStyles.init)
            }
            return model
        }

        let children = try schema.children.map { child -> InlineContainerChild in
            switch child {
            case .basicText(let text): return .text(try makeText(text))
            case .staticLink(let link):
                let styles = try SchemaStyleAdapter.inlineLink(link.styles)
                let label = try resolveAccessibilityLabel(link.a11yLabel, context: context)
                let model = try getStaticLink(src: link.src, open: link.open, styles: styles, children: nil,
                                              accessibilityLabel: label)
                conditions[model.id] = makeConditionalStyle(styles?.conditionalTransitions, context: context) {
                    $0.own.map(BaseStyles.init)
                }
                return .link(model, label: try link.children.map { try makeText($0.commonText) },
                             accessibilityLabel: label)
            case .toggleButtonStateTrigger(let toggle):
                let styles = try SchemaStyleAdapter.inlineToggle(toggle.styles)
                let label = try resolveAccessibilityLabel(toggle.a11yLabel, context: context)
                let model = try getToggleButton(customStateKey: toggle.customStateKey, styles: styles, children: nil,
                                                accessibilityLabel: label)
                conditions[model.id] = makeConditionalStyle(styles?.conditionalTransitions, context: context) {
                    $0.own.map(BaseStyles.init)
                }
                return .toggle(model, label: try toggle.children.map { try makeText($0.commonText) },
                               accessibilityLabel: label)
            }
        }
        return InlineContainerViewModel(
            children: children,
            stylingProperties: try StyleTransformer.updatedStyles(styles?.elements?.own, transform: BaseStyles.init),
            accessibilityLabel: try resolveAccessibilityLabel(schema.a11yLabel, context: context), layoutState: layoutState,
            conditionalStyle: makeConditionalStyle(styles?.conditionalTransitions, context: context) {
            $0.own.map(BaseStyles.init) },
            childConditionalStyles: conditions
        )
    }

    func getCatalogCarousel<P: SchemaPredicateConvertible>(
        _ schema: CatalogCarouselCollectionModel<CatalogCarouselCollectionTemplateNode, P>, context: Context
    ) throws -> CatalogCarouselCollectionViewModel {
        guard case .inner(.generic(_, let index)) = context, let index,
              layoutPlugin.slots.indices.contains(index) else {
            throw LayoutTransformerError.unsupportedFeature("CatalogCarouselCollection requires an offer slot")
        }
        guard layoutPlugin.slots.allSatisfy({ $0.layoutVariant?.layoutVariantSchema != nil }) else {
            throw LayoutTransformerError.unsupportedFeature("CatalogCarouselCollection requires a layout variant for every slot")
        }
        let styles = try SchemaStyleAdapter.catalogCarousel(schema.styles)
        let mergedStyles = try StyleTransformer.updatedStyles(styles?.elements?.own, transform: BaseStyles.init)
        // Validate the template before expanding items, including branches that are currently hidden.
        let template = try schema.template.commonLayout()
        return try CatalogCarouselCollectionViewModel(
            slots: layoutPlugin.slots, offerIndex: index, viewableItems: schema.viewableItems,
            peekThroughSize: schema.peekThroughSize.map {
                switch $0 {
                case .fixed(let value): .fixed(value)
                case .percentage(let value): .percentage(value)
                }
            }, defaultStyle: mergedStyles.map(\.default), layoutState: layoutState,
            callbacks: .init(eventService: eventService),
            conditionalStyle: makeConditionalStyle(styles?.conditionalTransitions, context: context) {
            $0.own.map(BaseStyles.init) }
        ) { card in
            try transform(template, context: .inner(.catalogItem(card)))
        }
    }

    private func makeConditionalStyle<S>(
        _ transition: ConditionalStyleTransition<S, WhenPredicate>?, context: Context, transform: (S) -> BaseStyles?
    ) -> ConditionalStyleBinding? {
        guard let transition, let animation = AnimationStyle(transition: transition, transform: transform) else { return nil }
        return ConditionalStyleBinding(
            condition: getWhenNode(children: nil, predicates: transition.predicates, transition: nil,
                                   catalogItemContext: context.catalogItemContext, predicateOfferIndex: context.offerIndex),
            animation: animation
        )
    }
}
