import Combine
import DcuiSchema
import SwiftUI

/// Native-only children keep interactive labels text-only, before schema integration.
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
                                   border: style?.border)
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
                                   border: style?.border)
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

final class InlineContainerViewModel: ObservableObject, BaseStyleAdaptive {
    let children: [InlineContainerChild]
    let stylingProperties: [BasicStateStylingBlock<BaseStyles>]?
    let accessibilityLabel: String?
    weak var layoutState: (any LayoutStateRepresenting)?
    @LazyPublished private var width: CGFloat?
    private var subscriptions = Set<AnyCancellable>()

    init(children: [InlineContainerChild],
         stylingProperties: [BasicStateStylingBlock<BaseStyles>]? = nil,
         accessibilityLabel: String? = nil,
         layoutState: (any LayoutStateRepresenting)? = nil) {
        self.children = children
        self.stylingProperties = stylingProperties
        self.accessibilityLabel = accessibilityLabel
        self.layoutState = layoutState
        for text in children.flatMap(\.texts) {
            text.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &subscriptions)
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

    func textContent(position: Int?, colorScheme: ColorScheme,
                     contentSize: UIContentSizeCategory, layoutDirection: LayoutDirection,
                     alignment: NSTextAlignment = .natural) -> InlineTextContent {
        let builder = InlineSpanBuilder()
        var runs: [InlineTextRun] = []
        for child in children {
            let resolved = child.texts.compactMap { model -> (BasicTextViewModel, String)? in
                let pages = Int(ceil(Double(model.totalOffer)/Double(max(1, model.viewableItems.wrappedValue))))
                let value = TextComponentBNFHelper.replaceStates(model.boundValue,
                                                                 currentOffer: "\(model.currentIndex.wrappedValue + 1)",
                                                                 totalOffers: "\(pages)")
                return value.isEmpty ? nil : (model, value)
            }
            guard !resolved.isEmpty else { continue }
            let range = builder.append(style: child.spanStyle(width: width), colorScheme: colorScheme) {
                for (model, value) in resolved {
                    let style = model.currentStylingProperties
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
            let label = explicitLabel ?? resolved.map { $0.1 }.joined()
            runs.append(InlineTextRun(id: child.id, range: range, label: label, action: child.action(position: position)))
        }
        let text = builder.text
        let paragraph = NSMutableParagraphStyle()
        paragraph.baseWritingDirection = layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        text.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: text.length))
        return InlineTextContent(text: text, runs: runs, decorations: builder.decorations)
    }
}
