//
//  BasicTextUIModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import Combine
import DcuiSchema

protocol DataBindingImplementable {
    associatedtype T: Hashable
    var dataBinding: DataBinding<T> { get }
    func updateDataBinding(dataBinding: DataBinding<T>)
}

@available(iOS 15, *)
class BasicTextViewModel: Hashable, Identifiable, ObservableObject, DataBindingImplementable {
    private var bag = Set<AnyCancellable>()

    let id: UUID = UUID()

    // `value` is used by our BNF transformer to update `dataBinding`
    private(set) var value: String?
    private(set) var dataBinding: DataBinding<String> = .value("")

    // extracted data from `dataBinding` that's published externally
    @Published var boundValue = ""

    @Published var styleState = StyleState.default
    @Published var breakpointIndex = 0
    var currentStylingProperties: BasicTextStyle? {
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

    // this closure performs the STATE-based data expansion (eg. progress indicator component owning a rich text child)
    private var stateDataExpansionClosure: ((String?) -> String?)?
    private let diagnosticService: DiagnosticServicing?

    var imageLoader: ImageLoader? {
        layoutState?.imageLoader
    }

    var currentIndex: Binding<Int> {
        layoutState?.items[LayoutState.currentProgressKey] as? Binding<Int> ?? .constant(0)
    }

    var totalOffer: Int {
        layoutState?.items[LayoutState.totalItemsKey] as? Int ?? 1
    }

    var viewableItems: Binding<Int> {
        layoutState?.items[LayoutState.viewableItemsKey] as? Binding<Int> ?? .constant(1)
    }

    init(
        value: String?,
        defaultStyle: [BasicTextStyle]?,
        pressedStyle: [BasicTextStyle]?,
        hoveredStyle: [BasicTextStyle]?,
        disabledStyle: [BasicTextStyle]?,
        stateDataExpansionClosure: ((String?) -> String?)? = nil,
        layoutState: (any LayoutStateRepresenting)?,
        diagnosticService: DiagnosticServicing?
    ) {
        self.value = value

        self.boundValue = value ?? ""

        self.defaultStyle = defaultStyle
        self.pressedStyle = pressedStyle
        self.hoveredStyle = hoveredStyle
        self.disabledStyle = disabledStyle

        self.stateDataExpansionClosure = stateDataExpansionClosure
        self.layoutState = layoutState
        self.diagnosticService = diagnosticService
        performStyleStateBinding()
    }

    func updateDataBinding(dataBinding: DataBinding<String>) {
        self.dataBinding = dataBinding
        runDataExpansion()
    }

    private func runDataExpansion() {
        switch dataBinding {
        case .value(let data):
            boundValue = data
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

    // update the text to display if State changes
    private func performStyleStateBinding() {
        $styleState.sink { [weak self] _ in
            self?.updateBoundValueWithStyling()
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

    private func updateBoundValueWithStyling() {
        guard let transform = currentStylingProperties?.text?.textTransform else { return }

        switch transform {
        case .uppercase:
            boundValue = boundValue.uppercased()
        case .lowercase:
            boundValue = boundValue.lowercased()
        case .capitalize:
            boundValue = boundValue.capitalized
        default: break
        }
    }

    func validateFont(textStyle: TextStylingProperties?) {
        if let fontFamily = textStyle?.fontFamily,
            UIFont(name: fontFamily,
                   size: CGFloat(textStyle?.fontSize ?? 17)) == nil {
            diagnosticService?.sendFontDiagnostics(fontFamily)
        }
    }
}
