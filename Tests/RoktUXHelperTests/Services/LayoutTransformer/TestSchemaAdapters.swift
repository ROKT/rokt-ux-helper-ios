import DcuiSchema
import XCTest
@testable import RoktUXHelper

final class TestSchemaAdapters: XCTestCase {
    func testUnboundInlineConditionsRejectDataOnEitherSideButAllowLocalState() throws {
        let conditions: [[String: Any]] = [
            ["type": "CreativeCopy", "predicate": ["condition": "exists", "value": "title"]],
            ["type": "Placeholder", "predicate": ["type": "TextValue", "content": [
                "condition": "is", "input": "%^DATA.catalogItem.title^%", "value": "Example"
            ]]],
            ["type": "Placeholder", "predicate": ["type": "TextValue", "content": [
                "condition": "is", "input": "Example", "value": "%^DATA.creativeCopy.title^%"
            ]]]
        ]
        for condition in conditions {
            let predicate = try decode(WhenPredicate.self, condition)
            XCTAssertThrowsError(try SchemaStyleAdapter.validateUnboundPredicates([predicate]))
        }
        XCTAssertNoThrow(try SchemaStyleAdapter.validateUnboundPredicates([
            decode(WhenPredicate.self, customState()), decode(WhenPredicate.self, hiddenPredicate())
        ]))
    }
    func testInteractiveAncestorValidationFindsHiddenAndUnexpandedNewActions() throws {
        let inline: [String: Any] = ["type": "InlineContainer", "node": ["children": [
            ["type": "ToggleButtonStateTrigger", "node": ["customStateKey": "details", "children": [text()]]]
        ]]]
        let column: [String: Any] = ["type": "Column", "node": ["children": [inline]]]
        let wrapped: [[String: Any]] = [
            column,
            ["type": "When", "node": ["predicates": [hiddenPredicate()], "children": [column]]],
            ["type": "CatalogStackedCollection", "node": ["template": column]],
            ["type": "CatalogCombinedCollection", "node": ["template": column]]
        ]
        for object in wrapped {
            let schema = try decode(LayoutSchemaModel.self, object)
            XCTAssertThrowsError(try SchemaInteractionValidation.validate([schema]))
        }
        XCTAssertThrowsError(try decode(LayoutSchemaModel.self, ["type": "AccessibilityGrouped", "node": ["child": column]]))
        let distribution = LayoutSchemaModel.oneByOneDistribution(.init(styles: nil, transition: .fadeInOut(.init(duration: 0))))
        let schema = try decode(LayoutSchemaModel.self, inline)
        XCTAssertThrowsError(try SchemaInteractionValidation.validate([distribution], slotSchemas: [schema, distribution]))
        XCTAssertNoThrow(try SchemaInteractionValidation.validate([distribution], slotSchemas: [distribution]))
        let textOnly = try decode(LayoutSchemaModel.self, ["type": "InlineContainer", "node": ["children": [text()]]])
        XCTAssertNoThrow(try SchemaInteractionValidation.validate([textOnly]))
    }

    func testRichTextStatesAreRejectedInNewCardContexts() throws {
        let schema = try decode(CatalogCarouselCollectionTemplateNodeChildren.self, [
            "type": "RichText", "node": ["value": "Example", "styles": ["elements": ["own": [],
                                                                                     "link": [
                                                                                         ["default": ["text": [:]], "pressed": [
                                                                                             "text": ["fontSize": 20]
                                                                                         ]]
                                                                                     ]]]]
        ])
        XCTAssertThrowsError(try schema.commonLayout())
    }
    func testNewContainerContextsRejectUnusedLayoutProperties() throws {
        for value: [String: Any] in [
            ["container": ["gap": 4]], ["container": ["alignItems": "stretch"]],
            ["flexChild": ["order": 2]],
            ["container": ["shadow": ["spreadRadius": 2, "color": ["light": "#000000"]]]]
        ] {
            let schema = try decode(InlineContainerModel<InlineChildren, WhenPredicate>.self,
                                    ["children": [text()], "styles": styles(value)])
            XCTAssertThrowsError(try SchemaStyleAdapter.inlineContainer(schema.styles))
        }
        for container in [["justifyContent": "center"], ["alignItems": "stretch"]] {
            let schema = try decode(CatalogCarouselCollectionModel<CatalogCarouselCollectionTemplateNode, WhenPredicate>.self, [
                "viewableItems": [1], "peekThroughSize": [], "styles": styles(["container": container]),
                "template": ["type": "Column", "node": ["children": []]]
            ])
            XCTAssertThrowsError(try SchemaStyleAdapter.catalogCarousel(schema.styles))
        }
    }

    func testInvalidConditionalColorAndDurationAreRejectedBeforePredicateEvaluation() throws {
        for transition: [String: Any] in [
            ["duration": -1, "value": ["own": [:]]],
            ["duration": 10, "value": ["own": ["text": ["textColor": ["light": "invalid"]]]]]
        ] {
            var value = transition
            value["predicates"] = [hiddenPredicate()]
            let schema = try decode(InlineBasicTextModel<WhenPredicate>.self,
                                    ["value": "Example", "styles": ["conditionalTransitions": value]])
            XCTAssertThrowsError(try SchemaStyleAdapter.inlineText(schema.styles))
        }
    }

    func testFunctionalWhenHidingUsesExistingRemovalButVisualHidingIsRejected() throws {
        for hide in ["functionally", "visually"] {
            let schema = try decode(CatalogCarouselCollectionTemplateNodeChildren.self,
                                    ["type": "When", "node": ["hide": hide, "predicates": [hiddenPredicate()], "children": []]])
            if hide == "functionally" { XCTAssertNoThrow(try schema.commonLayout()) }
            else { XCTAssertThrowsError(try schema.commonLayout()) }
        }
    }
    func testInlineTextPreservesRestrictedTypographyAndSpacing() throws {
        let schema = try decode(InlineBasicTextModel<WhenPredicate>.self, [
            "value": "Example", "styles": styles([
                "spacing": ["padding": "2 3", "margin": "4"], "background": ["backgroundColor": ["light": "#ffffff"]],
                "text": ["fontSize": 18, "fontWeight": "700", "fontFamily": "System", "fontStyle": "italic",
                         "textColor": ["light": "#123456", "dark": "#abcdef"], "baselineTextAlign": "super",
                         "textTransform": "uppercase", "letterSpacing": 2, "textDecoration": "underline"]
            ])
        ])
        let projected = try XCTUnwrap(SchemaStyleAdapter.inlineText(schema.styles)?.elements?.own.first?.default)
        XCTAssertEqual(projected.spacing?.padding, "2 3")
        XCTAssertEqual(projected.spacing?.margin, "4")
        XCTAssertNil(projected.spacing?.offset)
        XCTAssertEqual(projected.background?.backgroundColor?.light, "#ffffff")
        XCTAssertEqual(projected.text?.fontSize, 18)
        XCTAssertEqual(projected.text?.fontFamily, "System")
        XCTAssertEqual(projected.text?.textColor?.dark, "#abcdef")
        XCTAssertEqual(projected.text?.textTransform, .uppercase)
        XCTAssertEqual(projected.text?.baselineTextAlign, .super)
        XCTAssertEqual(projected.text?.letterSpacing, 2)
        XCTAssertNil(projected.text?.lineHeight)
        XCTAssertNil(projected.text?.lineLimit)
        XCTAssertNil(projected.dimension)
    }

    func testResponsiveContainerOpacityAndActionStatesUseExistingMerging() throws {
        let schema = try decode(InlineStaticLinkModel<NonInteractableInlineChildren, WhenPredicate>.self, [
            "src": "https://example.com", "open": "externally", "children": [text()], "styles": ["elements": ["own": [
                ["default": ["container": ["opacity": 0.5], "spacing": ["padding": "4"],
                             "background": ["backgroundColor": ["light": "#ffffff"]]],
                 "pressed": ["container": ["opacity": 0.25]]],
                ["default": ["spacing": ["margin": "6"]]]
            ]]]
        ])
        let mapped = try SchemaStyleAdapter.inlineLink(schema.styles)
        let merged = try StyleTransformer.updatedStyles(mapped?.elements?.own)
        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged[1].default.container?.opacity, 0.5)
        XCTAssertEqual(merged[1].pressed?.container?.opacity, 0.25)
        XCTAssertEqual(merged[1].pressed?.spacing?.padding, "4")
        XCTAssertEqual(merged[1].pressed?.spacing?.margin, "6")
        XCTAssertEqual(merged[1].pressed?.background?.backgroundColor?.light, "#ffffff")
    }

    func testConditionalProjectionPreservesDurationPredicatesAndOpacity() throws {
        let schema = try decode(InlineContainerModel<InlineChildren, WhenPredicate>.self, [
            "children": [text()], "styles": ["conditionalTransitions": [
                "predicates": [customState()], "duration": 250, "value": ["own": ["container": ["opacity": 0.4]]]
            ]]
        ])
        let mapped = try XCTUnwrap(SchemaStyleAdapter.inlineContainer(schema.styles)?.conditionalTransitions)
        XCTAssertEqual(mapped.duration, 250)
        XCTAssertEqual(mapped.value.own?.container?.opacity, 0.4)
        guard case .customState(let predicate) = mapped.predicates.first else { return XCTFail("Expected custom state") }
        XCTAssertEqual(predicate.key, "details")
        XCTAssertEqual(predicate.value, 1)
    }

    func testEveryInlineChildFamilyProjectsWithoutDroppingLabelsOrActions() throws {
        let object: [String: Any] = ["a11yLabel": "Description", "children": [
            text(), ["type": "StaticLink", "node": ["src": "https://example.com", "open": "externally",
                                                    "a11yLabel": "Open destination", "children": [text()]]],
            ["type": "ToggleButtonStateTrigger", "node": ["customStateKey": "details", "a11yLabel": "Change details",
                                                          "children": [text()]]]
        ]]
        let common = try decode(InlineContainerModel<InlineChildren, WhenPredicate>.self, object)
        let variant = try decode(InlineContainerModel<LayoutVariantInlineChildren, LayoutVariantWhenPredicate>.self, object)
        let outer = try decode(InlineContainerModel<OuterLayoutInlineChildren, OuterLayoutWhenPredicate>.self, object)
        for model in [try SchemaNodeAdapter.inlineContainer(common), try SchemaNodeAdapter.inlineContainer(variant),
                      try SchemaNodeAdapter.inlineContainer(outer)] {
            XCTAssertEqual(model.children.count, 3)
            XCTAssertEqual(model.a11yLabel, "Description")
            guard case .staticLink(let link) = model.children[1],
                  case .toggleButtonStateTrigger(let toggle) = model.children[2] else { return XCTFail("Expected actions") }
            XCTAssertEqual(link.a11yLabel, "Open destination")
            XCTAssertEqual(toggle.a11yLabel, "Change details")
            XCTAssertEqual(toggle.customStateKey, "details")
        }
        let textOnly: [String: Any] = ["children": [text()]]
        let noninteractive = try decode(InlineContainerModel<LayoutVariantNonInteractableInlineChildren,
                                                             LayoutVariantWhenPredicate>.self, textOnly)
        XCTAssertEqual(try SchemaNodeAdapter.inlineContainer(noninteractive).children.count, 1)
    }

    func testUnsupportedRangeEffectsAreRejectedInEveryStateAndConditionalValue() throws {
        let effects: [[String: Any]] = [
            ["background": ["backgroundImage": ["url": ["light": "https://example.com/image.png"]]]],
            ["container": ["blur": 2]], ["container": ["shadow": ["color": ["light": "#000000"]]]],
            ["spacing": ["margin": "-2"]]
        ]
        for effect in effects {
            for state in ["default", "pressed", "hovered", "disabled"] {
                var block: [String: Any] = ["default": [:]]
                block[state] = effect
                let schema = try decode(InlineStaticLinkModel<NonInteractableInlineChildren, WhenPredicate>.self, [
                    "src": "https://example.com", "open": "externally", "children": [text()],
                    "styles": ["elements": ["own": [block]]]
                ])
                XCTAssertThrowsError(try SchemaStyleAdapter.inlineLink(schema.styles))
            }
            let schema = try decode(InlineStaticLinkModel<NonInteractableInlineChildren, WhenPredicate>.self, [
                "src": "https://example.com", "open": "externally", "children": [text()],
                "styles": ["conditionalTransitions": ["predicates": [hiddenPredicate()], "duration": 10,
                                                      "value": ["own": effect]]]
            ])
            XCTAssertThrowsError(try SchemaStyleAdapter.inlineLink(schema.styles))
        }
    }

    func testFocusedStyleIsExplicitlyRejected() throws {
        let schema = try decode(InlineBasicTextModel<WhenPredicate>.self, [
            "value": "Example", "styles": ["elements": ["own": [["default": [:], "focussed": ["text": ["fontSize": 20]]]]]]
        ])
        XCTAssertThrowsError(try SchemaStyleAdapter.inlineText(schema.styles))
    }

    func testHiddenCatalogBranchesStillValidateInlineEffects() throws {
        let schema = try decode(CatalogCarouselCollectionTemplateNode.self, ["type": "Column", "node": ["children": [
            ["type": "When", "node": ["predicates": [hiddenPredicate()], "children": [
                ["type": "InlineContainer", "node": ["children": [
                    ["type": "BasicText", "node": ["value": "Hidden", "styles": styles([
                        "background": ["backgroundImage": ["url": ["light": "https://example.com/image.png"]]]
                    ])]]
                ]]]
            ]]]
        ]]])
        XCTAssertThrowsError(try schema.commonLayout())
    }

    func testCatalogTemplateAndNoninteractiveChildrenDispatchEveryCase() throws {
        let leaves: [[String: Any]] = [
            text(), ["type": "RichText", "node": ["value": "<p>Example</p>"]],
            ["type": "StaticImage", "node": ["url": ["light": "https://example.com/image.png"]]],
            ["type": "DataImage", "node": ["imageKey": "product"]],
            ["type": "When", "node": ["predicates": [hiddenPredicate()], "children": [text()]]],
            ["type": "InlineContainer", "node": ["children": [text()]]]
        ]
        let containers = ["Row", "Column", "ZStack"].map { ["type": $0, "node": ["children": leaves]] as [String: Any] }
        for object in leaves + containers {
            XCTAssertNoThrow(try decode(CatalogCarouselCollectionTemplateNodeChildren.self, object).commonLayout())
            XCTAssertNoThrow(try decode(CatalogCarouselCollectionNonInteractableChildren.self, object).commonLayout())
        }
        for type in ["StaticLink", "ToggleButtonStateTrigger", "CatalogResponseButton"] {
            var node: [String: Any] = ["children": containers, "a11yLabel": "Example action"]
            if type == "StaticLink" { node["src"] = "https://example.com"; node["open"] = "externally" }
            if type == "ToggleButtonStateTrigger" { node["customStateKey"] = "details" }
            let object: [String: Any] = ["type": type, "node": node]
            XCTAssertNoThrow(try decode(CatalogCarouselCollectionTemplateNodeChildren.self, object).commonLayout())
            XCTAssertThrowsError(try decode(CatalogCarouselCollectionNonInteractableChildren.self, object))
        }
        for type in ["Row", "Column"] {
            XCTAssertNoThrow(try decode(CatalogCarouselCollectionTemplateNode.self,
                                        ["type": type, "node": ["children": containers]]).commonLayout())
        }
    }

    func testUnsupportedCardTransitionsFailInsteadOfDisappearing() throws {
        let schema = try decode(CatalogCarouselCollectionTemplateNode.self, ["type": "Column", "node": [
            "children": [], "styles": ["conditionalTransitions": ["predicates": [hiddenPredicate()],
                                                                  "duration": 20,
                                                                  "value": ["own": ["spacing": ["padding": "2"]]]]]
        ]])
        XCTAssertThrowsError(try schema.commonLayout())
    }

    func testVariantDomainPredicateKeepsItsKeyBeforeExplicitValidation() throws {
        let predicate = try decode(LayoutVariantWhenPredicate.self, ["type": "DomainState", "predicate": [
            "key": "offerComplete", "condition": "is", "value": 1
        ]])
        guard case .domainState(let value) = predicate.commonPredicate else { return XCTFail("Expected domain state") }
        XCTAssertEqual(value.key, .offerComplete)
        XCTAssertEqual(value.value, 1)
        XCTAssertThrowsError(try SchemaStyleAdapter.validatePredicates([predicate.commonPredicate]))
    }

    private func decode<T: Decodable>(_ type: T.Type, _ object: [String: Any]) throws -> T {
        try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: object))
    }

    private func styles(_ value: [String: Any]) -> [String: Any] {
        ["elements": ["own": [["default": value]]]]
    }

    private func text() -> [String: Any] { ["type": "BasicText", "node": ["value": "Example"]] }
    private func customState() -> [String: Any] {
        ["type": "CustomState", "predicate": ["key": "details", "condition": "is", "value": 1]]
    }

    private func hiddenPredicate() -> [String: Any] {
        ["type": "StaticBoolean", "predicate": ["condition": "is-true", "value": false]]
    }
}
