import XCTest
import SwiftUI
import ViewInspector
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15.0, *)
final class TestCarouselDistributionComponent: XCTestCase {

    // MARK: - peekThroughSize

    // An empty `peekThroughSize` array previously floored `peekThroughBreakpointIndex` to 0 and
    // indexed it directly in `getPeekThrough`, trapping on first render inside the GeometryReader.
    func test_getPeekThrough_withEmptyPeekThroughSize_returnsZero() {
        let component = makeCarouselDistributionComponent(peekThroughSize: [])

        XCTAssertEqual(component.getPeekThrough(320), 0)
    }

    func test_getPeekThrough_withNonEmptyPeekThroughSize_resolvesTheBreakpointValue() {
        let component = makeCarouselDistributionComponent(peekThroughSize: [.fixed(16)])

        XCTAssertEqual(component.getPeekThrough(320), 16)
    }

    private func makeCarouselDistributionComponent(
        peekThroughSize: [PeekThroughSize],
        viewableItems: Int = 1,
        gap: Int = 0
    ) -> CarouselDistributionComponent {
        let defaultStyle: [CarouselDistributionStyles]? = gap == 0 ? nil : [
            CarouselDistributionStyles(
                container: ContainerStylingProperties(
                    justifyContent: nil,
                    alignItems: nil,
                    shadow: nil,
                    overflow: nil,
                    gap: Float(gap),
                    blur: nil,
                    opacity: nil
                ),
                background: nil,
                border: nil,
                dimension: nil,
                flexChild: nil,
                spacing: nil
            )
        ]

        let model = CarouselViewModel(
            children: [],
            defaultStyle: defaultStyle,
            viewableItems: [UInt8(viewableItems)],
            peekThroughSize: peekThroughSize,
            eventService: nil,
            slots: [],
            layoutState: LayoutState()
        )
        model.viewableItems = viewableItems

        return CarouselDistributionComponent(
            config: .init(parent: .column, position: 1),
            model: model,
            parentWidth: .constant(320),
            parentHeight: .constant(nil),
            styleState: .constant(.default),
            parentOverride: nil
        )
    }

    // MARK: - drag-end geometry

    // A 50%-of-container peek-through with no gap, or a fixed peek-through equal to half the
    // container width, previously drove pageWidth (and from it, offerWidth) to exactly zero,
    // which the drag gesture's -translation.width/offerWidth then divided by: a purely
    // horizontal drag gave ±infinity, a purely vertical one (0/0) gave NaN, and converting
    // either to Int trapped. offerWidth is now floored above zero regardless.

    func test_getOfferWidth_withFiftyPercentPeekThroughAndNoGap_staysPositiveAndFinite() {
        let component = makeCarouselDistributionComponent(peekThroughSize: [.percentage(50)])
        let width: CGFloat = 320

        let peekThrough = component.getPeekThrough(width)
        let pageWidth = component.getPageWidth(width: width, peekThrough: peekThrough)
        let offerWidth = component.getOfferWidth(pageWidth: pageWidth, totalOffers: 3)

        XCTAssertTrue(offerWidth.isFinite)
        XCTAssertGreaterThan(offerWidth, 0)

        // The exact formula used by the drag gesture's onEnded handler.
        XCTAssertTrue((-CGFloat(0)/offerWidth).isFinite, "a purely vertical drag must not divide by zero")
        XCTAssertTrue((-width/offerWidth).isFinite, "a purely horizontal drag must not divide by zero")
    }

    func test_getOfferWidth_withFixedPeekThroughEqualToHalfTheWidth_staysPositiveAndFinite() {
        let component = makeCarouselDistributionComponent(peekThroughSize: [.fixed(160)])
        let width: CGFloat = 320

        let peekThrough = component.getPeekThrough(width)
        let pageWidth = component.getPageWidth(width: width, peekThrough: peekThrough)
        let offerWidth = component.getOfferWidth(pageWidth: pageWidth, totalOffers: 3)

        XCTAssertTrue(offerWidth.isFinite)
        XCTAssertGreaterThan(offerWidth, 0)

        XCTAssertTrue((-CGFloat(0)/offerWidth).isFinite, "a purely vertical drag must not divide by zero")
        XCTAssertTrue((-width/offerWidth).isFinite, "a purely horizontal drag must not divide by zero")
    }

    // MARK: - page stride

    // A review finding on the offerWidth floor above: flooring only offerWidth left pageWidth
    // (the page-to-page drag/paging stride) narrower than what multiple gapped, floored-width
    // offers actually render at, so dragging would land on the wrong card instead of crashing.
    // getPageStride reconstructs the stride from the floored offerWidth so paging matches what's
    // rendered.
    func test_getPageStride_whenOfferWidthIsFloored_matchesTheRenderedWidth() {
        let component = makeCarouselDistributionComponent(
            peekThroughSize: [.percentage(50)],
            viewableItems: 2,
            gap: 12
        )
        let width: CGFloat = 320

        let peekThrough = component.getPeekThrough(width)
        let pageWidth = component.getPageWidth(width: width, peekThrough: peekThrough)
        let offerWidth = component.getOfferWidth(pageWidth: pageWidth, totalOffers: 3)
        let pageStride = component.getPageStride(pageWidth: pageWidth, offerWidth: offerWidth, totalOffers: 3)

        XCTAssertEqual(pageWidth, 2)
        XCTAssertEqual(offerWidth, 1)
        // Two floored-width offers plus the gap between and around them (2 * (1 + 12) = 26) —
        // what the inner HStack(spacing: gap) actually lays out for two items, not pageWidth's 2.
        XCTAssertEqual(pageStride, 26)
    }

    func test_getPageStride_whenOfferWidthIsNotFloored_staysEqualToPageWidth() {
        let component = makeCarouselDistributionComponent(
            peekThroughSize: [.fixed(16)],
            viewableItems: 2,
            gap: 4
        )
        let width: CGFloat = 320

        let peekThrough = component.getPeekThrough(width)
        let pageWidth = component.getPageWidth(width: width, peekThrough: peekThrough)
        let offerWidth = component.getOfferWidth(pageWidth: pageWidth, totalOffers: 3)
        let pageStride = component.getPageStride(pageWidth: pageWidth, offerWidth: offerWidth, totalOffers: 3)

        XCTAssertEqual(pageStride, pageWidth, accuracy: 0.001)
    }

    func test_carousel() throws {
        var closeActionCalled = false
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeCarousel(layoutState:eventService:)
        )

        let carouselComponent = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CarouselDistributionComponent.self)
            .actualView()

        let geometryReader = try carouselComponent.inspect().geometryReader()

        // test custom modifier class
        let paddingModifier = try geometryReader.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 3, right: 4, bottom: 5, left: 6))

        // test the effect of custom modifier
        let padding = try geometryReader.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 3.0, leading: 6.0, bottom: 5.0, trailing: 4.0))

        // Test accessibility label on the carousel item (LayoutSchemaComponent)
        let carouselItem = try geometryReader.find(LayoutSchemaComponent.self)
        XCTAssertEqual(try carouselItem.accessibilityLabel().string(), "Page 1 of 1")

        carouselComponent.model.goToNextOffer(nil)
        XCTAssertTrue(closeActionCalled)
    }

    func test_goToNextOffer_with_closeOnComplete_false() throws {
        var closeActionCalled = false
        let closeOnCompleteSettings = LayoutSettings(closeOnComplete: false, bottomSheetPresentation: nil)
        let view = try TestPlaceHolder.make(
            layoutSettings: closeOnCompleteSettings,
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeCarousel(layoutState:eventService:)
        )

        let carouselComponent = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(CarouselDistributionComponent.self)
            .actualView()

        carouselComponent.model.goToNextOffer(nil)
        XCTAssertFalse(closeActionCalled)
    }
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {

    static func makeCarousel(
        layoutState: LayoutState,
        eventService: EventService
    ) throws -> Self {
        let slots = ModelTestData.PageModelData.withBNF().layoutPlugins?.first?.slots
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots!),
                                            layoutState: layoutState,
                                            eventService: eventService)
        let model = ModelTestData.CarouselData.carousel()
        return LayoutSchemaViewModel.carousel(try transformer.getCarousel(carouselModel: model!, context: .outer([])))
    }
}
