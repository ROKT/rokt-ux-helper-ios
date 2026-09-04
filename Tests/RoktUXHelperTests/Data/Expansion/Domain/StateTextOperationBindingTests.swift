import SwiftUI
import XCTest
@testable import RoktUXHelper

final class StateTextOperationBindingTests: XCTestCase {
    func test_creativeStateBindingsPreserveOperationsUntilTextRendering() {
        let offer = OfferModel(campaignId: nil,
                               creative: CreativeModel(referralCreativeId: "creative", instanceGuid: "instance",
                                                       copy: ["copy": "fallback"], images: nil, links: nil,
                                                       responseOptionsMap: nil, jwtToken: ""),
                               catalogItems: nil, catalogItemGroup: nil, transactionData: nil)
        assertRenderedStateBindings(namespace: "DATA.creativeCopy", fallbackKey: "copy") {
            CreativeMapper().map(consumer: $0, context: .generic(offer))
        }
    }

    func test_catalogStateBindingsPreserveOperationsUntilTextRendering() {
        let item = CatalogItem.mock(catalogItemId: "fallback", images: nil)
        assertRenderedStateBindings(namespace: "DATA.catalogItem", fallbackKey: "catalogItemId") {
            CatalogMapper().map(consumer: $0, context: item)
        }
    }

    private func assertRenderedStateBindings(namespace: String, fallbackKey: String,
                                             map: (LayoutSchemaViewModel) -> Void,
                                             file: StaticString = #filePath, line: UInt = #line) {
        let fallback = "\(namespace).\(fallbackKey)"
        let cases = [
            ("STATE.TotalOffers:sliceText[Chars,1]|\(fallback)", "4"),
            ("STATE.TotalOffers|\(fallback)", "45"),
            ("STATE.IndicatorPosition:sliceText[Chars,1]|\(fallback)", "2"),
            ("STATE.IndicatorPosition|\(fallback)", "23"),
            ("STATE.Unknown|\(fallback)", "fallback"),
            ("STATE.Unknown|\(namespace).missing|literal", "literal")
        ]
        for (chain, expected) in cases {
            let state = LayoutState()
            state.items[LayoutState.totalItemsKey] = 45
            state.items[LayoutState.currentProgressKey] = Binding.constant(22)
            state.items[LayoutState.viewableItemsKey] = Binding.constant(1)
            let template = "Before %^\(chain)^% after"
            let basic = BasicTextViewModel(value: template, defaultStyle: nil, pressedStyle: nil,
                                           hoveredStyle: nil, disabledStyle: nil, layoutState: state, diagnosticService: nil)
            let rich = RichTextViewModel(value: template, defaultStyle: nil, openLinks: nil,
                                         layoutState: state, eventService: nil)
            map(.basicText(basic))
            map(.richText(rich))

            if !chain.hasPrefix("STATE.Unknown") {
                XCTAssertEqual(basic.boundValue, template, "STATE text stays deferred after mapping", file: file, line: line)
                XCTAssertEqual(rich.boundValue, template, "STATE text stays deferred after mapping", file: file, line: line)
            }
            let component = BasicTextComponent(config: .init(parent: .column, position: 0), model: basic,
                                               parentWidth: .constant(300), parentHeight: .constant(nil),
                                               styleState: .constant(.default), parentOverride: nil,
                                               expandsToContainerOnSelfAlign: false)
            XCTAssertEqual(component.stateReplacedValue, "Before \(expected) after", chain, file: file, line: line)
            XCTAssertEqual(rich.stateReplacedText, "Before \(expected) after", chain, file: file, line: line)
            XCTAssertEqual(rich.stateReplacedAttributedString.string, "Before \(expected) after", chain, file: file, line: line)
        }
    }
}
