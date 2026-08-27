import Combine
import DcuiSchema
import SwiftUI

/// Native children keep interactive labels text-only throughout text layout.
enum InlineContainerChild {
    case text(BasicTextViewModel)
    case link(StaticLinkViewModel, label: [BasicTextViewModel], accessibilityLabel: String? = nil,
              styles: [BasicStateStylingBlock<InlineSpanStyle>]? = nil)
    case toggle(ToggleButtonViewModel, label: [BasicTextViewModel], accessibilityLabel: String? = nil,
                styles: [BasicStateStylingBlock<InlineSpanStyle>]? = nil)

    var texts: [BasicTextViewModel] {
        switch self {
        case .text(let model): return [model]
        case .link(_, let label, _, _), .toggle(_, let label, _, _): return label
        }
    }

    var id: UUID {
        switch self {
        case .text(let model): return model.id
        case .link(let model, _, _, _): return model.id
        case .toggle(let model, _, _, _): return model.id
        }
    }

    var accessibilityLabel: String? {
        switch self {
        case .text: return nil
        case .link(_, _, let label, _), .toggle(_, _, let label, _): return label
        }
    }

    func spanStyle(width: CGFloat?) -> InlineSpanStyle {
        let state = texts.first?.styleState ?? .default
        switch self {
        case .text:
            return InlineSpanStyle()
        case .link(let model, _, _, let styles):
            if let styles {
                let index = model.layoutState?.getGlobalBreakpointIndex(width) ?? 0
                return Self.select(styles, at: index, state: state) ?? InlineSpanStyle()
            }
            let index = model.updateBreakpointIndex(for: width)
            let style = Self.select(model, at: index, state: state)
            return InlineSpanStyle(spacing: style?.spacing, backgroundColor: style?.background?.backgroundColor,
                                   border: style?.border, opacity: style?.container?.opacity)
        case .toggle(let model, _, _, let styles):
            if let styles {
                let index = model.layoutState?.getGlobalBreakpointIndex(width) ?? 0
                return Self.select(styles, at: index, state: state) ?? InlineSpanStyle()
            }
            let index = model.updateBreakpointIndex(for: width)
            let values: [ToggleButtonStateTriggerStyle]?
            switch state {
            case .pressed: values = model.pressedStyle ?? model.defaultStyle
            case .hovered: values = model.hoveredStyle ?? model.defaultStyle
            case .disabled: values = model.disabledStyle ?? model.defaultStyle
            default: values = model.defaultStyle
            }
            let style = values?[safe: index]
            return InlineSpanStyle(spacing: style?.spacing, backgroundColor: style?.background?.backgroundColor,
                                   border: style?.border, opacity: style?.container?.opacity)
        }
    }

    private static func select(_ styles: [BasicStateStylingBlock<InlineSpanStyle>], at index: Int,
                               state: StyleState) -> InlineSpanStyle? {
        guard let block = styles[safe: min(index, max(0, styles.count - 1))] else { return nil }
        switch state {
        case .pressed: return block.pressed ?? block.default
        case .hovered: return block.hovered ?? block.default
        case .disabled: return block.disabled ?? block.default
        default: return block.default
        }
    }

    private static func select(_ model: StaticLinkViewModel, at index: Int, state: StyleState) -> StaticLinkStyles? {
        switch state {
        case .pressed: return (model.pressedStyle ?? model.defaultStyle)?[safe: index]
        case .hovered: return (model.hoveredStyle ?? model.defaultStyle)?[safe: index]
        case .disabled: return (model.disabledStyle ?? model.defaultStyle)?[safe: index]
        default: return model.defaultStyle?[safe: index]
        }
    }

    func action(position: Int?) -> InlineTextAction? {
        switch self {
        case .text: return nil
        case .link(let model, _, _, _):
            return InlineTextAction(traits: .link, activate: model.handleLink)
        case .toggle(let model, _, _, _):
            return InlineTextAction(traits: .button, activate: { model.handleToggle(position: position) })
        }
    }
}

final class InlineContainerViewModel: ObservableObject, BaseStyleAdaptive, Identifiable, Hashable {
    let id = UUID()
    let children: [InlineContainerChild]
    let stylingProperties: [BasicStateStylingBlock<BaseStyles>]?
    let accessibilityLabel: String?
    let conditionalStyle: ConditionalStyleBinding?
    let childConditionalStyles: [UUID: ConditionalStyleBinding]
    weak var layoutState: (any LayoutStateRepresenting)?
    @LazyPublished private var width: CGFloat?
    private var subscriptions = Set<AnyCancellable>()

    init(children: [InlineContainerChild],
         stylingProperties: [BasicStateStylingBlock<BaseStyles>]? = nil,
         accessibilityLabel: String? = nil,
         layoutState: (any LayoutStateRepresenting)? = nil,
         conditionalStyle: ConditionalStyleBinding? = nil,
         childConditionalStyles: [UUID: ConditionalStyleBinding] = [:]) {
        self.children = children
        self.stylingProperties = stylingProperties
        self.accessibilityLabel = accessibilityLabel
        self.layoutState = layoutState
        self.conditionalStyle = conditionalStyle
        self.childConditionalStyles = childConditionalStyles
        for text in children.flatMap(\.texts) {
            text.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &subscriptions)
        }
        for conditional in Array(childConditionalStyles.values) + [conditionalStyle].compactMap({ $0 }) {
            conditional.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        }
    }

    func updateTextStyles(width: CGFloat?, state: StyleState = .default) {
        self.width = width
        for text in children.flatMap(\.texts) {
            let index = text.layoutState?.getGlobalBreakpointIndex(width) ?? 0
            text.breakpointIndex = max(0, min(index, (text.defaultStyle?.count ?? 1) - 1))
            text.styleState = state
            text.validateFont(textStyle: text.currentStylingProperties?.text)
        }
    }

    func setStyleState(_ state: StyleState, childID: UUID) {
        children.first(where: { $0.id == childID })?.texts.forEach { $0.styleState = state }
    }

    func style(state: StyleState, position: Int?, width: CGFloat?, colorScheme: ColorScheme) -> BaseStyles? {
        let block = stylingProperties?[safe: updateBreakpointIndex(for: width)]
        let selected: BaseStyles?
        let childStates = children.flatMap(\.texts).map(\.styleState)
        let activeState = state == .default
            ? (childStates.contains(.pressed) ? .pressed : childStates.contains(.hovered) ? .hovered : .default) : state
        switch activeState {
        case .pressed: selected = block?.pressed ?? block?.default
        case .hovered: selected = block?.hovered ?? block?.default
        case .disabled: selected = block?.disabled ?? block?.default
        default: selected = block?.default
        }
        return conditionalStyle?.resolve(selected, position: position, width: width ?? 0, colorScheme: colorScheme) ?? selected
    }

    func textContent(position: Int?, colorScheme: ColorScheme,
                     contentSize: UIContentSizeCategory, layoutDirection: LayoutDirection,
                     alignment: NSTextAlignment = .natural) -> InlineTextContent {
        let builder = InlineSpanBuilder()
        var runs: [InlineTextRun] = []
        for child in children {
            let resolved = child.texts.compactMap { model -> (value: String, style: BasicTextStyle?)? in
                let style = textStyle(model, position: position, colorScheme: colorScheme)
                let pages = Int(ceil(Double(model.totalOffer)/Double(max(1, model.viewableItems.wrappedValue))))
                let expanded = TextComponentBNFHelper.replaceStates(model.inlineResolvedValue,
                                                                    currentOffer: "\(model.currentIndex.wrappedValue + 1)",
                                                                    totalOffers: "\(pages)")
                let value = BasicTextViewModel.transform(expanded, using: style?.text?.textTransform)
                return value.isEmpty ? nil : (value, style)
            }
            guard !resolved.isEmpty else { continue }
            let range = builder.append(style: spanStyle(child, position: position, colorScheme: colorScheme),
                                       colorScheme: colorScheme) {
                for (value, style) in resolved {
                    _ = builder.append(style: InlineSpanStyle(spacing: style?.spacing,
                                                              backgroundColor: style?.background?.backgroundColor),
                                       colorScheme: colorScheme) {
                        builder.text.append(InlineTextAttributes.make(value, style: style,
                                                                      colorScheme: colorScheme, contentSize: contentSize))
                    }
                }
            }
            let explicitLabel = child.accessibilityLabel
                .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
            let label = explicitLabel ?? resolved.map(\.value).joined()
            runs.append(InlineTextRun(id: child.id, range: range, label: label, action: child.action(position: position)))
        }
        let text = builder.text
        let paragraph = NSMutableParagraphStyle()
        paragraph.baseWritingDirection = layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        text.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: text.length))
        let conditions = childConditionalStyles.sorted { $0.key.uuidString < $1.key.uuidString }.map(\.value)
        return InlineTextContent(text: text, runs: runs, decorations: builder.decorations,
                                 transitionStates: conditions.map {
                                      $0.applies(position: position, width: width ?? 0, colorScheme: colorScheme)
                                  }, transitionDuration: conditions.map { $0.animation.duration }.max() ?? 0)
    }

    private func textStyle(_ model: BasicTextViewModel, position: Int?, colorScheme: ColorScheme) -> BasicTextStyle? {
        let style = model.currentStylingProperties
        guard let conditional = childConditionalStyles[model.id] else { return style }
        let base = BaseStyles(background: style?.background, dimension: style?.dimension,
                              flexChild: style?.flexChild, spacing: style?.spacing, text: style?.text)
        guard let merged = conditional.resolve(base, position: position, width: width ?? 0, colorScheme: colorScheme)
            else { return style }
        return BasicTextStyle(dimension: merged.dimension, flexChild: merged.flexChild, spacing: merged.spacing,
                              background: merged.background, text: merged.text)
    }

    private func spanStyle(_ child: InlineContainerChild, position: Int?, colorScheme: ColorScheme) -> InlineSpanStyle {
        let style = child.spanStyle(width: width)
        if case .text = child { return style }
        guard let conditional = childConditionalStyles[child.id],
              conditional.applies(position: position, width: width ?? 0, colorScheme: colorScheme) else { return style }
        let diff = conditional.animation.style
        return InlineSpanStyle(spacing: StyleTransformer.updatedSpacing(style.spacing, newStyle: diff.spacing),
                               backgroundColor: try? StyleTransformer.updatedColor(style.backgroundColor,
                                                                                   newStyle: diff.background?.backgroundColor),
                               border: try? StyleTransformer.updatedBorder(style.border, newStyle: diff.border),
                               opacity: diff.container?.opacity ?? style.opacity)
    }
}
