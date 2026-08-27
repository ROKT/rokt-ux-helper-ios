import Combine
import DcuiSchema
import SwiftUI
import XCTest
@testable import RoktUXHelper

@MainActor
final class TestProductCarouselIntegration: XCTestCase {
    func testExampleDecodesWithBothCommonAndRestrictedVariantTypes() throws {
        let data = try ProductCarouselIntegrationFixture.data()
        XCTAssertNoThrow(try JSONDecoder().decode(LayoutSchemaModel.self, from: data))
        XCTAssertNoThrow(try JSONDecoder().decode(LayoutVariantSchemaModel.self, from: data))
    }

    func testCopyBoundaryUsesCharacterCountAndExplicitOfferContext() throws {
        for count in [77, 78, 79] {
            let copy = String(repeating: "👩🏽‍🚀", count: count)
            let slots = try ProductCarouselIntegrationFixture.slots(copies: ["Other offer", copy])
            let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
            let layout = try transformer.transform(try ProductCarouselIntegrationFixture.layout(),
                                                   context: .inner(.generic(slots[1].offer, offerIndex: 1)))
            guard case .column(let column) = layout,
                  case .when(let short) = column.children?[0],
                  case .when(let collapsed) = column.children?[1],
                  case .when(let expanded) = column.children?[2],
                  case .inlineContainer(let inline) = collapsed.children?.first else {
                return XCTFail("Expected description branches")
            }
            let state = get_mock_uistate(currentProgress: 0, totalOffers: 2, position: 1)
            XCTAssertEqual(short.shouldApply(state), count < 78)
            XCTAssertEqual(collapsed.shouldApply(state), count >= 78)
            XCTAssertFalse(expanded.shouldApply(state))
            XCTAssertEqual(inline.children[0].texts[0].boundValue, String(copy.prefix(78)) + "... ")
            let active = get_mock_uistate(currentProgress: 0, totalOffers: 2, position: 1,
                                          customStateMap: [CustomStateIdentifiable(position: 1, key: "detailsExpanded"): 1])
            XCTAssertFalse(collapsed.shouldApply(active))
            XCTAssertEqual(expanded.shouldApply(active), count >= 78)
        }
    }

    func testCardsKeepTheirOriginalOfferIndexWithDuplicateCreativeIDs() throws {
        let slots = try ProductCarouselIntegrationFixture.slots(copies: ["First", "Second", "Third", "Fourth"])
        let events = SchemaIntegrationEventService()
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots, events: events)
        let carousel = try ProductCarouselIntegrationFixture.carousel(transformer: transformer, slots: slots, index: 3)
        XCTAssertEqual(carousel.cards.map(\.context.offerIndex), [3, 3])
        XCTAssertEqual(carousel.cards.map(\.context.itemIndex), [0, 1])
        XCTAssertTrue(carousel.cards.allSatisfy { $0.context.offer.creative.copy["creative.copy"] == "Fourth" })
        let labels = try carousel.cards.map { card -> String? in
            guard case .column(let column) = card.layout,
                  case .catalogResponseButton(let button) = column.children?[3] else {
                throw LayoutTransformerError.InvalidMapping()
            }
            return button.accessibilityLabel
        }
        XCTAssertEqual(labels, ["Example product A", "Example product B"])
        carousel.mounted()
        carousel.mounted()
        XCTAssertEqual(events.catalogImpressions.map(\.offerIndex), [3, 3])
        XCTAssertEqual(events.catalogImpressions.map(\.itemIndex), [0, 1])
        let geometry = carousel.geometry(viewportWidth: 300, breakpointIndex: 0)
        carousel.beginInteraction(offset: 0, geometry: geometry)
        carousel.scrolled(offset: geometry.offset(for: 1), geometry: geometry)
        XCTAssertEqual(events.catalogScrolls.map { $0.0.itemIndex }, [1])
    }

    func testCatalogCardStateCountsStayConsistentWhenOuterDistributionShowsMultipleOffers() throws {
        let slots = try ProductCarouselIntegrationFixture.slots(copies: ["One", "Two", "Three", "Four"])
        let state = LayoutState()
        state.items[LayoutState.currentProgressKey] = Binding.constant(1)
        state.items[LayoutState.viewableItemsKey] = Binding.constant(2)
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots, state: state)
        let card = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 3, itemIndex: 1))
        let value = "%^STATE.IndicatorPosition^% of %^STATE.TotalOffers^%"
        let basic = try transformer.getBasicText(BasicTextModel(styles: nil, value: value), context: .inner(.catalogItem(card)))
        let rich = try transformer.getRichText(RichTextModel(styles: nil, openLinks: nil, value: value),
                                               context: .inner(.catalogItem(card)))
        let inline = InlineContainerViewModel(children: [.text(basic)], layoutState: state)
        for _ in 0..<2 {
            let component = BasicTextComponent(config: .init(parent: .column, position: 3), model: basic,
                                               parentWidth: .constant(300), parentHeight: .constant(nil),
                                               styleState: .constant(.default), parentOverride: nil,
                                               expandsToContainerOnSelfAlign: false)
            XCTAssertEqual(component.stateReplacedValue, "4 of 4")
            XCTAssertEqual(rich.stateReplacedText, "4 of 4")
            XCTAssertEqual(ProductCarouselIntegrationFixture.content(inline, position: 3).text.string, "4 of 4")
            XCTAssertEqual(PlaceholderPredicateResolver().resolveString(placeholder: "%^STATE.TotalOffers^%",
                                                                        context: .init(catalogItemContext: card)), "4")
            state.publishStateChange()
        }
    }

    func testCatalogResponseUsesItsBoundCardWithoutPurchaseOrDuplicateEvents() throws {
        let slots = try ProductCarouselIntegrationFixture.slots(copies: ["Offer"])
        let events = SchemaIntegrationEventService()
        let state = LayoutState()
        state.items[LayoutState.visibleOfferIndexesKey] = [0]
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots, state: state, events: events)
        let carousel = try ProductCarouselIntegrationFixture.carousel(transformer: transformer, slots: slots, index: 0)
        guard case .column(let column) = carousel.cards[1].layout,
              case .catalogResponseButton(let button) = column.children?[3] else { return XCTFail("Expected product action") }
        button.cartItemInstantPurchase(position: 99)
        XCTAssertEqual(events.productResponses.count, 1)
        XCTAssertEqual(events.productResponses.first?.context.offerIndex, 0)
        XCTAssertEqual(events.productResponses.first?.context.itemIndex, 1)
        XCTAssertEqual(events.productResponses.first?.option.responseJWTToken, "example-response-token-b")
        XCTAssertTrue(events.openURLCalled)
        XCTAssertFalse(events.cartItemInstantPurchaseCalled)
        XCTAssertFalse(events.cartItemForwardPaymentCalled)
    }

    func testCardSelectorsAndImagesReadEachBoundItem() throws {
        let slots = try ProductCarouselIntegrationFixture.slots(copies: ["Offer"])
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
        let carousel = try ProductCarouselIntegrationFixture.carousel(transformer: transformer, slots: slots, index: 0)
        for (index, card) in carousel.cards.enumerated() {
            guard case .column(let column) = card.layout,
                  case .dataImage(let image) = column.children?[0],
                  case .when(let title) = column.children?[1],
                  case .when(let price) = column.children?[2],
                  case .basicText(let text) = title.children?.first else { return XCTFail("Expected bound product content") }
            XCTAssertEqual(image.image?.light, index == 0 ? "https://example.com/a.png" : "https://example.com/b.png")
            XCTAssertEqual(text.boundValue, index == 0 ? "Example product A" : "Example product B")
            XCTAssertEqual(title.shouldApply(get_mock_uistate(position: 0)), index == 0)
            XCTAssertEqual(price.shouldApply(get_mock_uistate(position: 0)), index == 0)
        }
    }

    func testTextOnlyInlineWithinCreativeResponseKeepsItsOfferForConditionalPredicates() throws {
        let positive = RoktUXResponseOption(id: "example-positive", action: .url, instanceGuid: "example-positive",
                                            signalType: .signalResponse, shortLabel: "Yes", longLabel: nil,
                                            shortSuccessLabel: nil, isPositive: true, url: "https://example.com",
                                            responseJWTToken: "example-positive-token")
        let negative = RoktUXResponseOption(id: "example-negative", action: .captureOnly, instanceGuid: "example-negative",
                                            signalType: .signalResponse, shortLabel: "No", longLabel: nil,
                                            shortSuccessLabel: nil, isPositive: false, url: nil,
                                            responseJWTToken: "example-negative-token")
        let offer = OfferModel.mock(copy: ["title": "Product offer"],
                                    responseOptionList: .init(positive: positive, negative: negative))
        let slots = [SlotModel(instanceGuid: nil, offer: .mock(copy: ["title": "Other offer"]), layoutVariant: nil, jwtToken: ""),
                     SlotModel(instanceGuid: nil, offer: offer, layoutVariant: nil, jwtToken: "")]
        let inline = try JSONDecoder().decode(LayoutSchemaModel.self, from: Data(#"""
        {"type":"InlineContainer","node":{"children":[{"type":"BasicText","node":{"value":"Label"}}],
          "styles":{"conditionalTransitions":{"duration":0,"value":{"own":{"container":{"opacity":0.5}}},
            "predicates":[{"type":"Placeholder","predicate":{"type":"TextValue","content":{
              "condition":"is","input":"%^DATA.creativeCopy.title^%","value":"Product offer"}}}]}}}}
        """#.utf8))
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
        for key in ["positive", "negative"] {
            let schema = LayoutSchemaModel.creativeResponse(CreativeResponseModel(responseKey: key, styles: nil,
                                                                                  openLinks: nil, children: [inline]))
            let layout = try transformer.transform(schema, context: .inner(.generic(offer, offerIndex: 1)))
            guard case .creativeResponse(let response) = layout,
                  case .inlineContainer(let model) = response.children?.first else { return XCTFail("Expected text-only inline") }
            XCTAssertEqual(model.conditionalStyle?.condition.predicateOfferIndex, 1)
            XCTAssertEqual(model.conditionalStyle?.applies(position: 1, width: 200, colorScheme: .light), true)
        }
    }

    func testMissingLabelCopyFallsBackToChildrenInsteadOfAnEmptyOrRawLabel() throws {
        let slots = try ProductCarouselIntegrationFixture.slots(copies: ["Offer"])
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
        let context = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 0, itemIndex: 1))
        let button = try transformer.getCatalogResponseButtonModel(style: nil, children: nil,
                                                                   context: .inner(.catalogItem(context)),
                                                                   accessibilityLabel: "%^DATA.catalogItem.copy.missing|^%")
        XCTAssertNil(button.accessibilityLabel)
        XCTAssertEqual(try transformer.resolveAccessibilityLabel("%^DATA.catalogItem.copy.provider.productName|^%",
                                                                 context: .inner(.catalogItem(context))), "Example product B")
    }

    func testUnboundCollectionRejectsInlineDataConditionsWithADiagnostic() throws {
        let item = try XCTUnwrap(CatalogProductFixture.slots()[1].offer?.catalogItems?.first)
        let schema = try JSONDecoder().decode(LayoutSchemaModel.self, from: Data(#"""
        {"type":"InlineContainer","node":{"children":[{"type":"BasicText","node":{"value":"Label",
          "styles":{"conditionalTransitions":{"duration":0,"value":{"own":{"text":{"fontSize":20}}},
            "predicates":[{"type":"Placeholder","predicate":{"type":"TextValue","content":{
              "condition":"is","input":"%^DATA.catalogItem.title^%","value":"Example"}}}]}}}}]}}
        """#.utf8))
        let events = SchemaIntegrationEventService()
        events.useDiagnosticEvents = true
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: [], events: events)
        XCTAssertThrowsError(try transformer.transform(schema, context: .inner(.addToCart(item))))
        XCTAssertEqual(events.diagnostics.count, 1)
        XCTAssertTrue(events.diagnostics[0].contains("bound offer and item"))
    }

    func testCatalogDistributionsRejectMissingFirstMiddleAndLastLayoutVariants() throws {
        for distribution in ProductCarouselIntegrationFixture.distributions {
            for missingIndex in 0..<3 {
                var slots = try ProductCarouselIntegrationFixture.slots(copies: ["First", "Middle", "Last"])
                let slot = slots[missingIndex]
                slots[missingIndex] = SlotModel(instanceGuid: slot.instanceGuid, offer: slot.offer,
                                                layoutVariant: nil, jwtToken: slot.jwtToken)
                let events = SchemaIntegrationEventService()
                events.useDiagnosticEvents = true
                let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots, events: events)
                XCTAssertThrowsError(try transformer.transform(distribution, context: .outer(slots.map(\.offer))))
                XCTAssertEqual(events.diagnostics.count, 1)
                XCTAssertTrue(events.diagnostics[0].contains("every slot"))
                XCTAssertTrue(events.productResponses.isEmpty)
                XCTAssertTrue(events.catalogImpressions.isEmpty)
                XCTAssertFalse(events.transformerSuccessEventsCalled)
            }
        }
    }

    func testEmptyAndValidDistributionsKeepExistingShapeAndOrder() throws {
        for distribution in ProductCarouselIntegrationFixture.distributions {
            let empty = ProductCarouselIntegrationFixture.transformer(slots: [])
            XCTAssertNoThrow(try empty.transform(distribution, context: .outer([])))
            let slots = try ProductCarouselIntegrationFixture.slots(copies: ["First", "Second"])
            let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
            let layout = try transformer.transform(distribution, context: .outer(slots.map(\.offer)))
            let children: [LayoutSchemaViewModel]?
            switch layout {
            case .oneByOne(let model): children = model.children
            case .carousel(let model): children = model.children
            case .groupDistribution(let model): children = model.children
            default: return XCTFail("Expected distribution")
            }
            XCTAssertEqual(children?.count, 2)
            for (index, child) in (children ?? []).enumerated() {
                guard case .column(let column) = child,
                      case .catalogCarouselCollection(let carousel) = column.children?[3] else {
                    return XCTFail("Expected catalog cards")
                }
                XCTAssertTrue(carousel.cards.allSatisfy { $0.context.offerIndex == index })
            }
        }
    }

    func testCatalogWithoutAnOfferContextIsRejected() throws {
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: [])
        XCTAssertThrowsError(try transformer.transform(try ProductCarouselIntegrationFixture.catalogSchema(),
                                                       context: .outer([])))
    }
    func testExistingActionsRejectNewNestedActionsBeforeResponseFallback() throws {
        let inline: [String: Any] = ["type": "InlineContainer", "node": ["children": [
            ["type": "ToggleButtonStateTrigger", "node": ["customStateKey": "details", "children": []]]
        ]]]
        let hidden: [String: Any] = ["type": "When", "node": [
            "predicates": [["type": "StaticBoolean", "predicate": ["condition": "is-true", "value": false]]],
            "children": [["type": "Column", "node": ["children": [inline]]]]
        ]]
        for type in ["StaticLink", "ToggleButtonStateTrigger", "CreativeResponse", "CatalogResponseButton",
                     "CloseButton", "ProgressControl", "CatalogDevicePayButton"] {
            let node: [String: Any] = ["children": [hidden], "src": "https://example.com", "open": "externally",
                                       "customStateKey": "parent", "responseKey": "positive", "direction": "Forward",
                                       "provider": "ApplePay"]
            let schema = try JSONDecoder().decode(LayoutSchemaModel.self,
                                                  from: JSONSerialization.data(withJSONObject: ["type": type, "node": node]))
            let events = SchemaIntegrationEventService()
            events.useDiagnosticEvents = true
            let transformer = ProductCarouselIntegrationFixture.transformer(slots: [], events: events)
            XCTAssertThrowsError(try transformer.transform(schema, context: .inner(.generic(nil)))) { error in
                guard case LayoutTransformerError.unsupportedFeature = error else {
                    return XCTFail("Nested action should fail before any missing-response fallback")
                }
            }
            XCTAssertEqual(events.diagnostics.count, 1)
        }
    }

    func testOuterActionCannotHideNewActionsBehindADistribution() throws {
        let slots = try ProductCarouselIntegrationFixture.slots(copies: ["Offer"])
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
        for distribution in ProductCarouselIntegrationFixture.distributions {
            let wrapper = LayoutSchemaModel.staticLink(StaticLinkModel(a11yLabel: nil, src: "https://example.com",
                                                                       open: .externally, styles: nil, children: [distribution]))
            XCTAssertThrowsError(try transformer.transform(wrapper, context: .outer(slots.map(\.offer))))
        }
    }

    func testMissingVariantsRemainAllowedForLegacyNoncatalogDistributions() throws {
        let schema = LayoutSchemaModel.basicText(BasicTextModel(styles: nil, value: "Example"))
        let slots = [SlotModel(instanceGuid: nil, offer: nil, layoutVariant: nil, jwtToken: ""),
                     SlotModel(instanceGuid: nil, offer: nil,
                               layoutVariant: LayoutVariantModel(layoutVariantSchema: schema, moduleName: "standard-marketing"),
                               jwtToken: "")]
        for distribution in ProductCarouselIntegrationFixture.distributions {
            let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots)
            XCTAssertNoThrow(try transformer.transform(distribution, context: .outer(slots.map(\.offer))))
        }
    }

    func testLegacyActionsKeepGapAndRowStateStylesOutsideCatalogCards() throws {
        let item = try XCTUnwrap(CatalogProductFixture.slots()[1].offer?.catalogItems?.first)
        let events = SchemaIntegrationEventService()
        events.useDiagnosticEvents = true
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: [], events: events)
        let row: [String: Any] = ["type": "Row", "node": ["children": [], "styles": ["elements": ["own": [[
            "default": ["container": ["gap": 2]], "pressed": ["container": ["gap": 3]],
            "hovered": ["container": ["gap": 4]], "disabled": ["container": ["gap": 5]],
            "focussed": ["container": ["gap": 6]]
        ]]]]]]
        for type in ["StaticLink", "ToggleButtonStateTrigger", "CatalogResponseButton"] {
            var node: [String: Any] = ["children": [row], "styles": ["elements": ["own": [[
                "default": ["container": ["gap": 4]]
            ]]]]]
            if type == "StaticLink" { node["src"] = "https://example.com"; node["open"] = "externally" }
            if type == "ToggleButtonStateTrigger" { node["customStateKey"] = "details" }
            let schema = try JSONDecoder().decode(LayoutSchemaModel.self,
                                                  from: JSONSerialization.data(withJSONObject: ["type": type, "node": node]))
            let layout = try transformer.transform(schema, context: .inner(.addToCart(item)))
            let children: [LayoutSchemaViewModel]?
            switch layout {
            case .staticLink(let model):
                XCTAssertEqual(model.defaultStyle?.first?.container?.gap, 4)
                children = model.children
            case .toggleButton(let model):
                XCTAssertEqual(model.defaultStyle?.first?.container?.gap, 4)
                children = model.children
            case .catalogResponseButton(let model):
                XCTAssertEqual(model.defaultStyle?.first?.container?.gap, 4)
                children = model.children
            default: return XCTFail("Expected existing action")
            }
            guard case .row(let model) = children?.first else { return XCTFail("Expected existing row") }
            let styles = try XCTUnwrap(model.stylingProperties?.first)
            XCTAssertEqual(styles.default.container?.gap, 2)
            XCTAssertEqual(styles.pressed?.container?.gap, 3)
            XCTAssertEqual(styles.hovered?.container?.gap, 4)
            XCTAssertEqual(styles.disabled?.container?.gap, 5)
            XCTAssertEqual(styles.focussed?.container?.gap, 6)
        }
        XCTAssertTrue(events.diagnostics.isEmpty)
    }
}

enum ProductCarouselIntegrationFixture {
    typealias Transformer = LayoutTransformer<
        CreativeMapper<CreativeDataExtractor<PlaceholderValidator<DataSanitiser>>>,
        CatalogMapper<CatalogDataExtractor<PlaceholderValidator<DataSanitiser>>>,
        TransactionDataMapper<TransactionDataExtractor<PlaceholderValidator<DataSanitiser>>>,
        CreativeDataExtractor<PlaceholderValidator<DataSanitiser>>
    >

    static func data() throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "product_carousel_layout", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    static func layout() throws -> LayoutSchemaModel { try JSONDecoder().decode(LayoutSchemaModel.self, from: data()) }

    static func catalogSchema() throws -> LayoutSchemaModel {
        guard case .column(let column) = try layout() else { throw LayoutTransformerError.InvalidMapping() }
        return column.children[3]
    }

    static func slots(copies: [String]) throws -> [SlotModel] {
        let items = try XCTUnwrap(CatalogProductFixture.slots()[1].offer?.catalogItems)
        let schema = try layout()
        return copies.enumerated().map { index, copy in
            SlotModel(instanceGuid: "example-slot-\(index)",
                      offer: .mock(referralCreativeId: "duplicate-creative", copy: ["creative.copy": copy], catalogItems: items),
                      layoutVariant: LayoutVariantModel(layoutVariantSchema: schema, moduleName: "standard-marketing"),
                      jwtToken: "example-slot-token-\(index)")
        }
    }

    static func transformer(slots: [SlotModel], state: LayoutState = LayoutState(),
                            events: EventDiagnosticServicing? = nil) -> Transformer {
        LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots), layoutState: state, eventService: events)
    }

    static func carousel(transformer: Transformer, slots: [SlotModel],
                         index: Int) throws -> CatalogCarouselCollectionViewModel {
        let model = try transformer.transform(catalogSchema(), context: .inner(.generic(slots[index].offer, offerIndex: index)))
        guard case .catalogCarouselCollection(let carousel) = model else { throw LayoutTransformerError.InvalidMapping() }
        return carousel
    }

    static var distributions: [LayoutSchemaModel] {
        [.oneByOneDistribution(OneByOneDistributionModel(styles: nil, transition: .fadeInOut(.init(duration: 0)))),
         .carouselDistribution(CarouselDistributionModel(viewableItems: [1], peekThroughSize: [.fixed(0)], styles: nil)),
         .groupedDistribution(GroupedDistributionModel(viewableItems: [1], transition: .fadeInOut(.init(duration: 0)),
                                                       styles: nil))]
    }

    static func content(_ model: InlineContainerViewModel, position: Int? = nil) -> InlineTextContent {
        model.textContent(position: position, colorScheme: .light, contentSize: .large, layoutDirection: .leftToRight)
    }
}

final class SchemaIntegrationEventService: MockEventService {
    var interactionCount = 0
    var diagnostics: [String] = []

    override func sendUserInteraction(action: UserInteraction, context: UserInteractionContext) {
        interactionCount += 1
        super.sendUserInteraction(action: action, context: context)
    }

    override func sendEvent(_ eventType: RoktUXEventType, parentGuid: String, extraMetadata: [RoktEventNameValue],
                            eventData: [String: String], objectData: [String: String]?, jwtToken: String) {
        if eventType == .SignalSdkDiagnostic { diagnostics.append(eventData[kErrorStackTrace] ?? "") }
    }
}
