import XCTest
import SwiftUI
import ViewInspector
import SnapshotTesting
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

    // MARK: - Snapshots

    // Visual companion to the drag-end geometry tests above: the same two degenerate schemas
    // that used to crash the drag gesture now render a floored, very narrow page instead of
    // trapping. Each test stacks that degenerate carousel under a normal, healthy one at the same
    // 320pt container width, so the comparison itself shows why: `getPeekThrough`'s clamp applies
    // to both sides of the page at once (`pageWidth = width - peekThrough * 2`), so a peek-through
    // this large doesn't just shrink the "peek" -- it consumes the main offer too, leaving only
    // the floored sliver this PR's fix keeps from reaching zero.

    func testSnapshot_fiftyPercentPeekThroughWithNoGap() throws {
        let view = try makeComparisonSnapshotView(degeneratePeekThroughSize: [.percentage(50)],
                                                  degenerateLabel: "This schema: 50% peek-through, no gap")
        assertCarouselSnapshot(view)
    }

    func testSnapshot_fixedPeekThroughEqualToHalfTheWidth() throws {
        let view = try makeComparisonSnapshotView(
            degeneratePeekThroughSize: [.fixed(160)],
            degenerateLabel: "This schema: fixed 160pt peek-through (half the 320pt container)"
        )
        assertCarouselSnapshot(view)
    }

    private func makeComparisonSnapshotView(degeneratePeekThroughSize: [PeekThroughSize],
                                            degenerateLabel: String) throws -> some View {
        // 250pt comfortably fills most of the 256pt offer width a 10% peek-through computes at
        // this container width, leaving the next (teal) offer peeking in at the trailing edge --
        // what an ordinary, non-degenerate carousel looks like.
        let normal = try makeCarouselView(peekThroughSize: [.percentage(10)], childWidth: 250)
        // 2pt matches the floored offer width both degenerate schemas compute at this container
        // width (`getPeekThrough` clamps to width/2 - 1 = 159, so `getOfferWidth` floors to 2).
        let degenerate = try makeCarouselView(peekThroughSize: degeneratePeekThroughSize, childWidth: 2)

        return VStack(alignment: .leading, spacing: 6) {
            Text("Normal: 10% peek-through").font(.caption2)
            normal
            Text(degenerateLabel).font(.caption2)
            degenerate
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }

    private func makeCarouselView(peekThroughSize: [PeekThroughSize], childWidth: CGFloat) throws -> some View {
        let layoutState = LayoutState()
        let colors = ["#D7263D", "#1B998B", "#2E86AB"]
        // A fixed size no larger than this configuration's own offer width keeps each child's
        // background within its own HStack slot: `CarouselDistributionComponent`'s per-child
        // `.frame(width: offerWidth)` isn't individually clipped, so anything larger -- a
        // percentage width, say, which resolves against the carousel's full container rather than
        // its page slot -- paints over its neighbours instead of being cropped to its own slot.
        let children: [LayoutSchemaViewModel] = try (0..<3).map { index in
            let style = try JSONDecoder().decode(BasicTextStyle.self, from: Data("""
            {"dimension":{"width":{"type":"fixed","value":\(childWidth)},"height":{"type":"fixed","value":40}},
             "background":{"backgroundColor":{"light":"\(colors[index])"}}}
            """.utf8))
            let text = BasicTextViewModel(value: " ", defaultStyle: [style], pressedStyle: nil,
                                          hoveredStyle: nil, disabledStyle: nil, layoutState: layoutState,
                                          diagnosticService: nil)
            return .basicText(text)
        }
        let model = CarouselViewModel(children: children, defaultStyle: nil, viewableItems: [1],
                                      peekThroughSize: peekThroughSize, eventService: nil, slots: [],
                                      layoutState: layoutState)
        let screen = GlobalScreenSize()
        screen.width = 320
        screen.height = 100
        return CarouselDistributionComponent(config: .init(parent: .column, position: 1), model: model,
                                             parentWidth: .constant(320), parentHeight: .constant(nil),
                                             styleState: .constant(.default), parentOverride: nil)
            .frame(width: 320, alignment: .topLeading)
            .environmentObject(screen)
            .environment(\.colorScheme, .light)
    }

    private func assertCarouselSnapshot(_ view: some View, file: StaticString = #filePath,
                                        testName: String = #function, line: UInt = #line) {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 340, height: 200))
        window.rootViewController = host
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        host.view.layoutIfNeeded()
        // The carousel's height comes from a child's async `readSize` callback (a second
        // SwiftUI layout pass), which isn't observable from outside without reaching into
        // private state, so this settles on a short fixed delay rather than a polled condition.
        let settled = expectation(description: "carousel layout settles")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settled.fulfill() }
        wait(for: [settled], timeout: 1)
        host.view.layoutIfNeeded()
        assertSnapshot(of: host, as: .image(on: snapshotDevice, precision: snapshotPrecision,
                                            perceptualPrecision: snapshotPerceptualPrecision),
                       file: file, testName: testName, line: line)
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
