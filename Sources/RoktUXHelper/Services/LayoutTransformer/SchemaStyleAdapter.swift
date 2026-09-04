import Foundation
import DcuiSchema

protocol SchemaPredicateConvertible: Decodable {
    var commonPredicate: WhenPredicate { get }
}

extension WhenPredicate: SchemaPredicateConvertible {
    var commonPredicate: WhenPredicate { self }
}

extension LayoutVariantWhenPredicate: SchemaPredicateConvertible {
    var commonPredicate: WhenPredicate {
        switch self {
        case .breakpoint(let value): .breakpoint(value)
        case .position(let value): .position(value)
        case .progression(let value): .progression(value)
        case .darkMode(let value): .darkMode(value)
        case .creativeCopy(let value): .creativeCopy(value)
        case .staticBoolean(let value): .staticBoolean(value)
        case .customState(let value): .customState(value)
        case .staticString(let value): .staticString(value)
        case .placeholder(let value): .placeholder(value)
        case .domainState(let value):
            .domainState(LayoutSchemaDomainStatePredicate(key: value.key.commonKey,
                                                          condition: value.condition, value: value.value))
        }
    }
}

extension OuterLayoutWhenPredicate: SchemaPredicateConvertible {
    var commonPredicate: WhenPredicate {
        switch self {
        case .breakpoint(let value): .breakpoint(value)
        case .progression(let value): .progression(value)
        case .darkMode(let value): .darkMode(value)
        case .staticBoolean(let value): .staticBoolean(value)
        case .customState(let value): .customState(value)
        case .staticString(let value): .staticString(value)
        case .placeholder(let value): .placeholder(value)
        case .domainState(let value):
            .domainState(LayoutSchemaDomainStatePredicate(key: .layoutMinimized,
                                                          condition: value.condition, value: value.value))
        }
    }
}

private extension LayoutVariantDomainStateKey {
    var commonKey: DomainStateKey {
        switch self {
        case .offerComplete: .offerComplete
        case .checkout: .checkout
        case .layoutMinimized: .layoutMinimized
        }
    }
}

/// Projects restricted wire styles into the existing style-merging pipeline without re-encoding schema models.
enum SchemaStyleAdapter {
    typealias Styles<E: Decodable, T: Decodable, P: Decodable> = LayoutStyle<E, ConditionalStyleTransition<T, P>>

    static func normalized<E, S, P: SchemaPredicateConvertible>(_ style: Styles<E, S, P>?) -> Styles<E, S, WhenPredicate>? {
        guard let style else { return nil }
        return LayoutStyle(elements: style.elements, conditionalTransitions: style.conditionalTransitions.map {
            ConditionalStyleTransition(predicates: $0.predicates.map(\.commonPredicate), duration: $0.duration, value: $0.value)
        })
    }

    static func inlineText<P: SchemaPredicateConvertible>(_ style: Styles<InlineBasicTextElements, InlineBasicTextTransitions,
                                                                          P>?) throws
                                                                          -> Styles<BasicTextElements, BasicTextTransitions,
                                                                                    WhenPredicate>? {
        try project(style, elements: { BasicTextElements(own: try $0.own.map { try states($0, transform: text) }) },
                    transition: { BasicTextTransitions(own: try $0.own.map(text)) })
    }

    static func inlineLink<P: SchemaPredicateConvertible>(_ style: Styles<InlineStaticLinkElements, InlineStaticLinkTransitions,
                                                                          P>?) throws
                                                                          -> Styles<StaticLinkElements, StaticLinkTransitions,
                                                                                    WhenPredicate>? {
        try project(style, elements: { StaticLinkElements(own: try $0.own.map { try states($0, transform: link) }) },
                    transition: { StaticLinkTransitions(own: try $0.own.map(link)) })
    }

    static func inlineToggle<P: SchemaPredicateConvertible>(_ style: Styles<InlineToggleButtonStateTriggerElements,
                                                                            InlineToggleButtonStateTriggerTransitions,
                                                                            P>?) throws
                                                                            -> Styles<ToggleButtonStateTriggerElements,
                                                                                      ToggleButtonStateTriggerTransitions,
                                                                                      WhenPredicate>? {
        try project(style,
                    elements: { ToggleButtonStateTriggerElements(own: try $0.own.map { try states($0, transform: toggle) }) },
                    transition: { ToggleButtonStateTriggerTransitions(own: try $0.own.map(toggle)) })
    }

    static func inlineContainer<P: SchemaPredicateConvertible>(_ style: Styles<InlineContainerElements,
                                                                               InlineContainerTransitions,
                                                                               P>?) throws
                                                                               -> Styles<RowElements, RowTransitions,
                                                                                         WhenPredicate>? {
        try project(style, elements: { RowElements(own: try $0.own.map { try states($0, transform: row) }) },
                    transition: { RowTransitions(own: try $0.own.map(row)) })
    }

    static func catalogCarousel<P: SchemaPredicateConvertible>(_ style: Styles<CatalogCarouselCollectionElements,
                                                                               CatalogCarouselCollectionTransitions,
                                                                               P>?) throws
                                                                               -> Styles<RowElements, RowTransitions,
                                                                                         WhenPredicate>? {
        try project(style, elements: { elements in
            RowElements(own: try elements.own.map {
                BasicStateStylingBlock(default: try row($0.default), pressed: nil, hovered: nil, focussed: nil, disabled: nil)
            })
        }, transition: { RowTransitions(own: try $0.own.map(row)) })
    }

    static func validatePredicates(_ predicates: [WhenPredicate]) throws {
        if predicates.contains(where: { if case .domainState = $0 { return true }; return false }) {
            throw LayoutTransformerError.unsupportedFeature("domainState predicate")
        }
    }

    static func validateUnboundPredicates(_ predicates: [WhenPredicate]) throws {
        for predicate in predicates {
            switch predicate {
            case .creativeCopy:
                throw LayoutTransformerError.unsupportedFeature("inline conditional creative data requires a bound offer")
            case .placeholder(let value):
                let expressions: [String]
                switch value {
                case .textValue(let value): expressions = [value.input, value.value]
                case .textLength(let value), .numeric(let value): expressions = [value.input, value.value]
                }
                if expressions.contains(where: { $0.contains("DATA.") }) {
                    throw LayoutTransformerError.unsupportedFeature("inline conditional data requires a bound offer and item")
                }
            default: break
            }
        }
    }

    static func rejectTransition<E, S, P>(_ style: LayoutStyle<E, ConditionalStyleTransition<S, P>>?, node: String) throws {
        if style?.conditionalTransitions != nil {
            throw LayoutTransformerError.unsupportedFeature("\(node).conditionalTransitions")
        }
    }

    private static func project<E, F, S, T, P: SchemaPredicateConvertible>(_ style: Styles<E, S, P>?, elements: (E) throws -> F,
                                                                           transition: (S) throws -> T) throws
                                                                           -> Styles<F, T, WhenPredicate>? {
        guard let style else { return nil }
        let conditional = try style.conditionalTransitions.map { value in
            let predicates = value.predicates.map(\.commonPredicate)
            try validatePredicates(predicates)
            try SchemaStyleValidation.duration(value.duration)
            return ConditionalStyleTransition(predicates: predicates, duration: value.duration,
                                              value: try transition(value.value))
        }
        return LayoutStyle(elements: try style.elements.map(elements), conditionalTransitions: conditional)
    }

    private static func states<T, U>(_ block: BasicStateStylingBlock<T>,
                                     transform: (T) throws -> U) throws -> BasicStateStylingBlock<U> {
        guard block.focussed == nil else { throw LayoutTransformerError.unsupportedFeature("inline.focussed style") }
        return BasicStateStylingBlock(default: try transform(block.default), pressed: try block.pressed.map(transform),
                                      hovered: try block.hovered.map(transform), focussed: nil,
                                      disabled: try block.disabled.map(transform))
    }

    private static func text(_ style: InlineBasicTextStyle) throws -> BasicTextStyle {
        try validateBackground(style.background)
        let text = style.text.map {
            TextStylingProperties(textColor: $0.textColor, fontSize: $0.fontSize, fontFamily: $0.fontFamily,
                                  fontWeight: $0.fontWeight, lineHeight: nil, horizontalTextAlign: nil,
                                  baselineTextAlign: $0.baselineTextAlign, fontStyle: $0.fontStyle,
                                  textTransform: $0.textTransform, letterSpacing: $0.letterSpacing,
                                  textDecoration: $0.textDecoration, lineLimit: nil)
        }
        let result = BasicTextStyle(dimension: nil, flexChild: nil, spacing: try spacing(style.spacing),
                                    background: style.background, text: text)
        try SchemaStyleValidation.validate(result, node: "inline.BasicText")
        return result
    }

    private static func link(_ style: InlineStaticLinkStyles) throws -> StaticLinkStyles {
        try validateBackground(style.background)
        let result = StaticLinkStyles(container: try container(style.container), background: style.background,
                                      border: style.border, dimension: nil, flexChild: nil, spacing: try spacing(style.spacing))
        try SchemaStyleValidation.validate(result, node: "inline.StaticLink")
        return result
    }

    private static func toggle(_ style: InlineToggleButtonStateTriggerStyle) throws -> ToggleButtonStateTriggerStyle {
        try validateBackground(style.background)
        let result = ToggleButtonStateTriggerStyle(container: try container(style.container), background: style.background,
                                                   border: style.border, dimension: nil, flexChild: nil,
                                                   spacing: try spacing(style.spacing))
        try SchemaStyleValidation.validate(result, node: "inline.ToggleButtonStateTrigger")
        return result
    }

    private static func row(_ style: InlineContainerStyles) throws -> RowStyle {
        if let gap = style.container?.gap, gap != 0 {
            throw LayoutTransformerError.unsupportedFeature("InlineContainer.container.gap")
        }
        if let alignment = style.container?.alignItems, alignment != .flexStart {
            throw LayoutTransformerError.unsupportedFeature("InlineContainer.container.alignItems")
        }
        let result = RowStyle(container: style.container, background: style.background, border: style.border,
                              dimension: style.dimension, flexChild: style.flexChild, spacing: style.spacing)
        try SchemaStyleValidation.validate(result, node: "InlineContainer")
        return result
    }

    private static func row(_ style: CatalogCarouselCollectionStyles) throws -> RowStyle {
        if let justification = style.container?.justifyContent, justification != .flexStart {
            throw LayoutTransformerError.unsupportedFeature("CatalogCarouselCollection.container.justifyContent")
        }
        if style.container?.alignItems == .stretch {
            throw LayoutTransformerError.unsupportedFeature("CatalogCarouselCollection.container.alignItems.stretch")
        }
        let result = RowStyle(container: style.container, background: style.background, border: style.border,
                              dimension: style.dimension, flexChild: style.flexChild, spacing: style.spacing)
        try SchemaStyleValidation.validate(result, node: "CatalogCarouselCollection")
        return result
    }

    private static func container(_ style: InlineContainerStylingProperties?) throws -> ContainerStylingProperties? {
        guard let style else { return nil }
        guard style.shadow == nil else { throw LayoutTransformerError.unsupportedFeature("inline.container.shadow") }
        guard style.blur == nil || style.blur == 0 else {
            throw LayoutTransformerError.unsupportedFeature("inline.container.blur")
        }
        return ContainerStylingProperties(justifyContent: nil, alignItems: nil, shadow: nil, overflow: nil,
                                          gap: nil, blur: nil, opacity: style.opacity)
    }

    private static func validateBackground(_ background: BackgroundStylingProperties?) throws {
        if background?.backgroundImage != nil {
            throw LayoutTransformerError.unsupportedFeature("inline.background.backgroundImage")
        }
    }

    private static func spacing(_ style: InlineSpacingStylingProperties?) throws -> SpacingStylingProperties? {
        guard let style else { return nil }
        for value in [style.padding, style.margin].compactMap({ $0 }) where !value.isEmpty {
            let numbers = value.split(whereSeparator: \.isWhitespace)
            guard (1...4).contains(numbers.count), numbers.allSatisfy({
                guard let number = Float($0) else { return false }
                return number.isFinite && number >= 0
            }) else { throw LayoutTransformerError.unsupportedFeature("inline.spacing requires nonnegative finite values") }
        }
        return SpacingStylingProperties(padding: style.padding, margin: style.margin, offset: nil)
    }
}
