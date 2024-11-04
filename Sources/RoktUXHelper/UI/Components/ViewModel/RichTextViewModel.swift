//
//  RichTextUIModel.swift
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

@available(iOS 15, *)
class RichTextViewModel: Hashable, Identifiable, ObservableObject, ScreenSizeAdaptive {
    // `value` is used by our BNF transformer to update `dataBinding`
    private(set) var value: String?
    private(set) var dataBinding: DataBinding = .value("")
    // this closure performs the STATE-based data expansion (eg. progress indicator component owning a rich text child)
    private var stateDataExpansionClosure: ((String?) -> String?)?
    private let eventService: EventDiagnosticServicing?

    let id: UUID = UUID()
    let defaultStyle: [RichTextStyle]?
    let linkStyle: [InLineTextStyle]?
    let openLinks: LinkOpenTarget?
    let layoutState: any LayoutStateRepresenting

    // extracted data from `dataBinding` that's published externally
    @Published var boundValue = ""
    @Published var breakpointIndex = 0
    @Published var breakpointLinkIndex = 0
    @Published var attributedString = NSAttributedString("")

    var imageLoader: ImageLoader? {
        layoutState.imageLoader
    }

    lazy var currentIndex: Binding<Int> = layoutState.items[LayoutState.currentProgressKey] as? Binding<Int> ?? .constant(0)
    lazy var totalOffer: Int = layoutState.items[LayoutState.totalItemsKey] as? Int ?? 1
    lazy var viewableItems: Binding<Int> = layoutState.items[LayoutState.viewableItemsKey] as? Binding<Int> ?? .constant(1)

    var totalPages: Int {
        return Int(ceil(Double(totalOffer)/Double(viewableItems.wrappedValue)))
    }

    var stateReplacedAttributedString: NSAttributedString {
        let text = attributedString.description.isEmpty ? NSAttributedString(string: boundValue) : attributedString

        let replacedText = TextComponentBNFHelper.replaceStates(text,
                                                                currentOffer: "\(currentIndex.wrappedValue + 1)",
                                                                totalOffers: "\(totalPages)")
        return replacedText
    }

    var stateReplacedText: String {
        TextComponentBNFHelper.replaceStates(boundValue,
                                             currentOffer: "\(currentIndex.wrappedValue + 1)",
                                             totalOffers: "\(totalPages)")
    }

    init(
        value: String?,
        defaultStyle: [RichTextStyle]?,
        linkStyle: [InLineTextStyle]? = nil,
        openLinks: LinkOpenTarget?,
        stateDataExpansionClosure: ((String?) -> String?)? = nil,
        layoutState: any LayoutStateRepresenting,
        eventService: EventDiagnosticServicing?
    ) {
        self.value = value
        self.boundValue = value ?? ""

        self.defaultStyle = defaultStyle
        self.linkStyle = linkStyle
        self.openLinks = openLinks
        self.stateDataExpansionClosure = stateDataExpansionClosure
        self.layoutState = layoutState
        self.eventService = eventService
        updateBoundValueWithStyling()
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

    // only runs if the DataBinding is STATE. this is where we do a STATE operation (eg. adding + 1)
    private func processStateValue(_ value: String?, isStateIndicatorPosition: Bool) {
        guard isStateIndicatorPosition,
              let stateDataExpansionClosure,
              let expandedValue = stateDataExpansionClosure(value)
        else { return }

        boundValue = expandedValue
    }

    func updateBoundValueWithStyling() {
        guard defaultStyle?.count ?? -1 > breakpointIndex,
              let transform = defaultStyle?[breakpointIndex].text?.textTransform else { return }

        switch transform {
        case .uppercase:
            boundValue = boundValue.uppercased()
        case .lowercase:
            boundValue = boundValue.lowercased()
        case .capitalize:
            boundValue = boundValue.capitalized
        default:
            break
        }
    }

    func transformValueToAttributedString(_ colorMode: RoktUXConfig.ColorMode?, colorScheme: ColorScheme?) {
        let customColorScheme: ColorScheme = colorScheme ?? UITraitCollection.getConfigColorSchema(colorMode: colorMode)
        transformValueToAttributedString(customColorScheme)
    }

    func transformValueToAttributedString(_ colorScheme: ColorScheme) {
        let valueToTransform = boundValue

        guard defaultStyle?.count ?? -1 > breakpointIndex,
              let breakpointDefaultStyle = defaultStyle?[breakpointIndex]
        else { return }

        let shouldSelectLink = linkStyle != nil && linkStyle?.count ?? -1 > breakpointLinkIndex
        let breakpointLinkStyle = shouldSelectLink ? linkStyle?[breakpointLinkIndex] : nil

        guard let htmlTransformedValue = try? valueToTransform.htmlToAttributedString(
            textColorHex: breakpointDefaultStyle.text?.textColor?.getAdaptiveColor(colorScheme),
            uiFont: breakpointDefaultStyle.text?.styledUIFont,
            linkStyles: breakpointLinkStyle?.text,
            colorScheme: colorScheme
        ) else {
            attributedString = NSAttributedString(string: valueToTransform)
            return
        }

        attributedString = htmlTransformedValue
    }

    func updateAttributedString(_ colorScheme: ColorScheme) {
        transformValueToAttributedString(colorScheme)
    }

    func validateFont(textStyle: TextStylingProperties?) {
        if let fontFamily = textStyle?.fontFamily,
            UIFont(name: fontFamily,
                   size: CGFloat(textStyle?.fontSize ?? 17)) == nil {
            eventService?.sendFontDiagnostics(fontFamily)
        }
    }

    func handleURL(_ url: URL) -> OpenURLAction.Result {
        eventService?.openURL(url: url, type: .init(openLinks), completionHandler: {})
        return .handled
    }

    func updateBreakpointLinkIndex(for newSize: CGFloat?) -> Int {
        let linkIndex = min(layoutState.getGlobalBreakpointIndex(newSize),
                            (linkStyle?.count ?? 1) - 1)
        return linkIndex >= 0 ? linkIndex : 0
    }

    func onAppear(textStyle: RichTextStyle?) {
        if attributedString.description.isEmpty && stateReplacedAttributedString.description.isEmpty {
            eventService?.sendDiagnostics(
                message: kViewErrorCode,
                callStack: kInvalidHTMLFormatError + stateReplacedAttributedString.description
            )
        }
        validateFont(textStyle: textStyle?.text)
    }
}
