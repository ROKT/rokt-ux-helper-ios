import SwiftUI
import Combine
import DcuiSchema

protocol DataBindingImplementable {
    associatedtype T: Hashable
    var dataBinding: DataBinding<T> { get }
    func updateDataBinding(dataBinding: DataBinding<T>)
}

class BasicTextViewModel: Hashable, Identifiable, ObservableObject, DataBindingImplementable {
    private var bag = Set<AnyCancellable>()

    let id: UUID = UUID()

    // `value` is used by our BNF transformer to update `dataBinding`
    private(set) var value: String?
    let catalogItemContext: CatalogItemContext?
    private(set) var dataBinding: DataBinding<String> = .value("")

    // Post-mapper text retained as the template for reactive catalog-runtime resolution. Mappers
    // resolve their own namespaces and write the partially-resolved text here; on every
    // `LayoutState.itemsPublisher` emission we re-resolve `%^DATA.catalogRuntime.<key>^%`
    // against the latest catalog-runtime dictionary so live values from the host SDK appear
    // without re-running the layout transformer.
    private var postMapperTemplate: String?

    // extracted data from `dataBinding` that's published externally
    @LazyPublished var boundValue = ""
    // `boundValue` before the style's text transform. Each style change transforms this,
    // so it never re-transforms the previous style's output.
    private var untransformedValue: String

    @LazyPublished var styleState = StyleState.default
    @LazyPublished var breakpointIndex = 0
    var currentStylingProperties: BasicTextStyle? {
        stylingProperties(for: styleState)
    }

    private func stylingProperties(for styleState: StyleState) -> BasicTextStyle? {
        switch styleState {
        case .hovered:
            return hoveredStyle?.count ?? -1 > breakpointIndex ? hoveredStyle?[breakpointIndex] : nil
        case .pressed:
            return pressedStyle?.count ?? -1 > breakpointIndex ? pressedStyle?[breakpointIndex] : nil
        case .disabled:
            return disabledStyle?.count ?? -1 > breakpointIndex ? disabledStyle?[breakpointIndex] : nil
        default:
            return defaultStyle?.count ?? -1 > breakpointIndex ? defaultStyle?[breakpointIndex] : nil
        }
    }

    let defaultStyle: [BasicTextStyle]?
    let pressedStyle: [BasicTextStyle]?
    let hoveredStyle: [BasicTextStyle]?
    let disabledStyle: [BasicTextStyle]?
    weak var layoutState: (any LayoutStateRepresenting)?
    weak var diagnosticService: DiagnosticServicing?
    // this closure performs the STATE-based data expansion (eg. progress indicator component owning a rich text child)
    private var stateDataExpansionClosure: ((String?) -> String?)?
    private var cancellable: AnyCancellable?

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    var currentIndex: Binding<Int> = .constant(0)
    var viewableItems: Binding<Int> = .constant(1)

    var totalOffer: Int {
        catalogItemContext?.offers.count ?? layoutState?.items[LayoutState.totalItemsKey] as? Int ?? 1
    }

    init(
        value: String?,
        defaultStyle: [BasicTextStyle]?,
        pressedStyle: [BasicTextStyle]?,
        hoveredStyle: [BasicTextStyle]?,
        disabledStyle: [BasicTextStyle]?,
        stateDataExpansionClosure: ((String?) -> String?)? = nil,
        layoutState: (any LayoutStateRepresenting)?,
        diagnosticService: DiagnosticServicing?,
        catalogItemContext: CatalogItemContext? = nil
    ) {
        self.value = value
        self.catalogItemContext = catalogItemContext

        self.boundValue = value ?? ""
        self.untransformedValue = value ?? ""

        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle

        self.stateDataExpansionClosure = stateDataExpansionClosure
        self.layoutState = layoutState
        self.diagnosticService = diagnosticService
        self.viewableItems = catalogItemContext == nil
            ? layoutState?.items[LayoutState.viewableItemsKey] as? Binding<Int> ?? .constant(1) : .constant(1)
        self.currentIndex = catalogItemContext.map { Binding<Int>.constant($0.offerIndex) }
            ?? layoutState?.items[LayoutState.currentProgressKey] as? Binding<Int> ?? .constant(0)
        performStyleStateBinding()

        cancellable = layoutState?.itemsPublisher.sink { [weak self] newValue in
            guard let self else { return }
            self.viewableItems = self.catalogItemContext == nil
                ? newValue[LayoutState.viewableItemsKey] as? Binding<Int> ?? .constant(1) : .constant(1)
            self.currentIndex = self.catalogItemContext.map { Binding<Int>.constant($0.offerIndex) }
                ?? newValue[LayoutState.currentProgressKey] as? Binding<Int> ?? .constant(0)
            // Re-resolve `%^DATA.catalogRuntime.<key>^%` against the latest catalog-runtime dict so the
            // confirmation screen picks up subtotal/tax/shipping/total values pushed at runtime.
            self.reapplyCatalogRuntimeResolution()
        }
    }

    deinit {
        cancellable?.cancel()
        bag.removeAll()
    }

    func updateDataBinding(dataBinding: DataBinding<String>) {
        self.dataBinding = dataBinding
        if case .value(let v) = dataBinding {
            self.postMapperTemplate = v
        }
        runDataExpansion()
    }

    /// Template text for chained mappers: the post-previous-mapper output if any mapper has
    /// already written to `dataBinding`, otherwise the raw template. Distinguishes "no prior
    /// mapping" (postMapperTemplate == nil) from "prior mapping resolved to empty"
    /// (postMapperTemplate == ""), so an empty mapper output is preserved instead of
    /// reintroducing the raw placeholders for a later finalize pass to zero the line.
    var currentTemplateText: String {
        postMapperTemplate ?? value ?? ""
    }

    var inlineResolvedValue: String {
        if case .value = dataBinding { return applyCatalogRuntimeResolution(to: currentTemplateText) }
        return boundValue
    }

    private func runDataExpansion() {
        switch dataBinding {
        case .value(let data):
            boundValue = applyCatalogRuntimeResolution(to: data)
        case .state(let data):
            var isStateIndicatorPosition = false

            // if the input is `%^STATE.IndicatorPosition^%`, associated value `data` = `IndicatorPosition`
            if DataBindingStateKeys.isValidKey(data) {
                isStateIndicatorPosition = true
            }

            // if the input is `%^STATE.IndicatorPosition^%`, becomes `IndicatorPosition`
            // if the input is `Hello`, becomes `Hello`
            boundValue = data

            // perform data expansion on initialiser argument `value` if the DataBinding is STATE
            processStateValue(value, isStateIndicatorPosition: isStateIndicatorPosition)
        }

        updateBoundValueWithStyling()
    }

    private func reapplyCatalogRuntimeResolution() {
        guard let template = postMapperTemplate else { return }
        boundValue = applyCatalogRuntimeResolution(to: template)
        updateBoundValueWithStyling()
    }

    private func applyCatalogRuntimeResolution(to text: String) -> String {
        CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: layoutState?.items[LayoutState.catalogRuntimeDataKey] as? [String: String]
        )
    }

    /// Called by the layout transformer after every mapper has had its turn. Substitutes
    /// `|` defaults for any placeholder no mapper claimed, and zeroes the line if a
    /// mandatory placeholder is still unresolved. Deferred namespaces (`DATA.catalogRuntime`,
    /// `STATE.*`) are left intact.
    func finalizePlaceholders() {
        guard let template = postMapperTemplate else { return }
        guard let validated = OrphanedPlaceholderResolver.resolve(text: template) else {
            postMapperTemplate = ""
            boundValue = ""
            updateBoundValueWithStyling()
            return
        }
        postMapperTemplate = validated
        boundValue = applyCatalogRuntimeResolution(to: validated)
        updateBoundValueWithStyling()
    }

    // update the text to display if State changes
    private func performStyleStateBinding() {
        // The publisher emits before `styleState` changes, so use the emitted state.
        $styleState.sink { [weak self] styleState in
            self?.applyTextTransform(for: styleState)
        }
        .store(in: &bag)
    }

    // only runs if the DataBinding is STATE. this is where we do a STATE operation (eg. adding + 1)
    func processStateValue(_ value: String?, isStateIndicatorPosition: Bool) {
        guard isStateIndicatorPosition,
              let stateDataExpansionClosure,
              let expandedValue = stateDataExpansionClosure(value)
        else { return }

        boundValue = expandedValue
    }

    /// Call after writing new, untransformed text to `boundValue`.
    private func updateBoundValueWithStyling() {
        untransformedValue = boundValue
        applyTextTransform(for: styleState)
    }

    private func applyTextTransform(for styleState: StyleState) {
        boundValue = Self.transform(
            untransformedValue,
            using: stylingProperties(for: styleState)?.text?.textTransform
        )
    }

    static func transform(_ value: String, using transform: TextTransform?) -> String {
        switch transform {
        case .uppercase:
            return value.uppercased()
        case .lowercase:
            return value.lowercased()
        case .capitalize:
            var inWord = false
            return capitalize(value, inWord: &inWord)
        default: return value
        }
    }

    /// Transforms one piece of a longer text. `inWord` says whether the text before
    /// `value` ended inside a word and is advanced past `value`, so a word split
    /// across pieces is capitalized once.
    static func transform(_ value: String, using transform: TextTransform?, inWord: inout Bool) -> String {
        if transform == .capitalize {
            return capitalize(value, inWord: &inWord)
        }
        inWord = value.reduce(inWord) { continuesWord($1, inWord: $0) }
        return Self.transform(value, using: transform)
    }

    /// Matches CSS: capitalizes the first letter of each word and keeps the rest.
    private static func capitalize(_ value: String, inWord: inout Bool) -> String {
        var result = ""
        for character in value {
            if !inWord, character.isLetter {
                result += String(character).capitalized
            } else {
                result.append(character)
            }
            inWord = continuesWord(character, inWord: inWord)
        }
        return result
    }

    /// CSS word rule: letters, digits and "_" join a word, and an apostrophe joins one
    /// only mid-word. Anything else, including other punctuation, ends the word.
    private static func continuesWord(_ character: Character, inWord: Bool) -> Bool {
        character.isLetter || character.isNumber || character == "_"
            || (inWord && (character == "'" || character == "\u{2019}"))
    }

    func validateFont(textStyle: TextStylingProperties?) {
        if let fontFamily = textStyle?.fontFamily,
            UIFont(name: fontFamily,
                   size: CGFloat(textStyle?.fontSize ?? 17)) == nil {
            diagnosticService?.sendFontDiagnostics(fontFamily)
        }
    }
}
