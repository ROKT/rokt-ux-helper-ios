import XCTest
import SwiftUI
import ViewInspector
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestCatalogResponseButtonComponent: XCTestCase {

    @MainActor
    func test_productResponseWithoutStylesRendersItsChildWithoutExpandingHeight() throws {
        let slots = try CatalogProductFixture.slots()
        let context = try XCTUnwrap(CatalogItemContext(slots: slots, offerIndex: 1, itemIndex: 0))
        for styles in ["null", #"{"elements":{"own":[]}}"#] {
            let schema = try JSONDecoder().decode(LayoutSchemaModel.self, from: Data("""
            {"type":"CatalogResponseButton","node":{"styles":\(styles),"children":[
              {"type":"BasicText","node":{"value":"View product"}}
            ]}}
            """.utf8))
            let state = LayoutState()
            let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots, state: state)
            let layout = try transformer.transform(schema, context: .inner(.catalogItem(context)))
            guard case .catalogResponseButton(let model) = layout else {
                return XCTFail("Expected a catalog response button")
            }
            XCTAssertEqual(model.defaultStyle?.count, 0)
            let screen = GlobalScreenSize()
            screen.width = 240
            let component = CatalogResponseButtonComponent(config: .init(parent: .column, position: 1), model: model,
                                                           parentWidth: .constant(240), parentHeight: .constant(nil),
                                                           parentOverride: nil).environmentObject(screen)
            let child = try component.inspect().find(BasicTextComponent.self).actualView()
            XCTAssertEqual(child.model.boundValue, "View product")
            XCTAssertFalse(child.expandsToContainerOnSelfAlign)
        }
    }

    func test_creative_response() throws {

        let view = try TestPlaceHolder
            .make(layoutMaker: LayoutSchemaViewModel.makeCatalogResponseButton(layoutState:eventService:))

        let catalogResponseButton = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogResponseButtonComponent.self)
            .actualView()
            .inspect()
            .find(ViewType.HStack.self)
        
        // test custom modifier class
        let paddingModifier = try catalogResponseButton.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 5, right: 5, bottom: 5, left: 5))  
        let marginModifier = try catalogResponseButton.modifier(MarginModifier.self)
        XCTAssertEqual(
            try marginModifier.actualView().getMargin(),
            FrameAlignmentProperty(top: 24, right: 0, bottom: 24, left: 0)
        )
        
        // test the effect of custom modifier
        let padding = try catalogResponseButton.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 29.0, leading: 5.0, bottom: 29.0, trailing: 5.0))
    }

    func test_send_ux_event() throws {
        var closeEventCalled = false
        var signalCartItemInitiatedCalled = false
        let eventDelegate = MockUXHelper()
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeEventCalled = true
                } else if event.eventType == .SignalCartItemInstantPurchaseInitiated {
                    signalCartItemInitiatedCalled = true
                }
            },
            eventDelegate: eventDelegate,
            layoutMaker: LayoutSchemaViewModel.makeCatalogResponseButton(layoutState:eventService:)
        )

        let catalogResponseButton = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CatalogResponseButtonComponent.self)
            .actualView()

        let sut = catalogResponseButton.model
        sut.cartItemInstantPurchase(position: nil)

        XCTAssertTrue(eventDelegate.roktEvents.contains(.CartItemInstantPurchase))
        XCTAssertTrue(eventDelegate.roktEvents.contains(.PlacementClosed))
        XCTAssertTrue(signalCartItemInitiatedCalled)
        XCTAssertTrue(closeEventCalled)
        XCTAssertNotNil(sut.layoutState)
    }
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {
    static func makeCatalogResponseButton(
        layoutState: LayoutState,
        eventService: EventService
    ) throws -> Self {
        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(),
            layoutState: layoutState,
            eventService: eventService
        )
        let catalogResponseButton = ModelTestData.CatalogResponseButtonData.catalogResponseButton()
        
        guard let catalogItem = ModelTestData.CatalogPageModelData.withBNF().layoutPlugins?.first?.slots.first?.offer?
            .catalogItems?.first else {
            XCTFail("Couldn't get catalog item")
            throw LayoutTransformerError.InvalidMapping()
        }
        return LayoutSchemaViewModel.catalogResponseButton(
            try transformer.getCatalogResponseButtonModel(
                style: catalogResponseButton.styles,
                children: transformer.transformChildren(catalogResponseButton.children, context: .inner(.addToCart(catalogItem))),
                context: .inner(.addToCart(catalogItem))
            )
        )
    }
}
