import XCTest
import SwiftUI
import Combine
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class CatalogProductDistributionTests: XCTestCase {
    func test_oneByOneNavigationInvalidatesOldCompletionsAndResetsPendingProgression() throws {
        try verifyNavigationLifecycle(.oneByOne)
    }

    func test_carouselNavigationInvalidatesOldCompletionsAndResetsPendingProgression() throws {
        try verifyNavigationLifecycle(.carousel)
    }

    func test_groupedNavigationInvalidatesOldCompletionsAndResetsPendingProgression() throws {
        try verifyNavigationLifecycle(.grouped)
    }

    func test_carouselAllowsResponsesFromEveryVisibleOfferWithoutAdvancingThePage() throws {
        try verifyMultipleVisibleOffers(.carousel)
    }

    func test_groupedAllowsResponsesFromEveryVisibleOfferWithoutAdvancingTheGroup() throws {
        try verifyMultipleVisibleOffers(.grouped)
    }

    private func verifyNavigationLifecycle(_ distribution: Distribution) throws {
        let scene = try makeScene(distribution, visibleCount: 1)
        defer { scene.tearDown() }
        let response = try responseModel(in: scene, offerIndex: 0)
        response.handleResponse()
        XCTAssertEqual(scene.delegate.closures.count, 1)

        waitForVisible([1], in: scene.state) { scene.state.actionCollection[.progressControlNext](nil) }
        waitForVisible([0], in: scene.state) { scene.state.actionCollection[.progressControlPrevious](nil) }
        let staleCompletion = try XCTUnwrap(scene.delegate.closures[safe: 0])
        assertRemainsVisible([0], in: scene.state, perform: staleCompletion)

        response.handleResponse()
        XCTAssertEqual(scene.delegate.closures.count, 2)
        let firstCompletion = try XCTUnwrap(scene.delegate.closures[safe: 1])
        waitForVisible([1], in: scene.state, perform: firstCompletion)
        waitForVisible([0], in: scene.state) { scene.state.actionCollection[.progressControlPrevious](nil) }
        response.handleResponse()
        XCTAssertEqual(scene.delegate.closures.count, 3)
        let repeatedCompletion = try XCTUnwrap(scene.delegate.closures[safe: 2])
        waitForVisible([1], in: scene.state, perform: repeatedCompletion)
        XCTAssertFalse(scene.delegate.roktEvents.contains(.CartItemInstantPurchase))
        XCTAssertFalse(scene.delegate.roktEvents.contains(.CartItemForwardPayment))
    }

    private func verifyMultipleVisibleOffers(_ distribution: Distribution) throws {
        let scene = try makeScene(distribution, visibleCount: 2)
        defer { scene.tearDown() }
        let secondOffer = try responseModel(in: scene, offerIndex: 1)
        secondOffer.handleResponse()
        XCTAssertEqual(scene.delegate.closures.count, 1)
        let secondCompletion = try XCTUnwrap(scene.delegate.closures[safe: 0])
        assertRemainsVisible([0, 1], in: scene.state, perform: secondCompletion)

        waitForVisible([2, 3], in: scene.state) { scene.state.actionCollection[.progressControlNext](nil) }
        let fourthOffer = try responseModel(in: scene, offerIndex: 3)
        fourthOffer.handleResponse()
        XCTAssertEqual(scene.delegate.closures.count, 2)
        let fourthCompletion = try XCTUnwrap(scene.delegate.closures[safe: 1])
        assertRemainsVisible([2, 3], in: scene.state, perform: fourthCompletion)

        secondOffer.handleResponse()
        XCTAssertEqual(scene.delegate.closures.count, 2, "An offer outside the visible group cannot respond")
        XCTAssertFalse(scene.delegate.roktEvents.contains(.PlacementClosed))
    }

    private func responseModel(in scene: Scene, offerIndex: Int) throws -> CatalogProductResponseViewModel {
        let context = try XCTUnwrap(CatalogItemContext(slots: scene.slots, offerIndex: offerIndex, itemIndex: 1))
        return CatalogProductResponseViewModel(context: context, eventService: scene.service, layoutState: scene.state)
    }

    private func makeScene(_ distribution: Distribution, visibleCount: UInt8) throws -> Scene {
        let productSlot = try CatalogProductFixture.slots()[1]
        let slots = (0..<4).map { index in
            SlotModel(instanceGuid: "example-slot-\(index)", offer: productSlot.offer,
                      layoutVariant: productSlot.layoutVariant, jwtToken: productSlot.jwtToken)
        }
        let state = LayoutState()
        state.items[LayoutState.layoutSettingsKey] = LayoutSettings(closeOnComplete: false)
        let delegate = CatalogProductURLDelegate()
        let service = get_mock_event_processor(uxEventDelegate: delegate)
        let children = slots.indices.map { index in
            LayoutSchemaViewModel.basicText(BasicTextViewModel(value: "Example offer \(index)", defaultStyle: nil,
                                                               pressedStyle: nil, hoveredStyle: nil, disabledStyle: nil,
                                                               layoutState: state, diagnosticService: nil))
        }
        let layout = distribution.layout(children: children, slots: slots, visibleCount: visibleCount,
                                         state: state, service: service)
        let screen = GlobalScreenSize()
        screen.width = 300
        screen.height = 800
        let mounted = expectation(description: "Distribution mounted and actions registered")
        let root = LayoutSchemaComponent(config: ComponentConfig(parent: .column, position: nil), layout: layout,
                                         parentWidth: .constant(300), parentHeight: .constant(nil),
                                         styleState: .constant(.default))
            .frame(width: 300, height: 500, alignment: .topLeading)
            .environmentObject(screen)
            .onAppear { DispatchQueue.main.async { mounted.fulfill() } }
        let host = UIHostingController(rootView: AnyView(root))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 800))
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        wait(for: [mounted], timeout: 3)
        waitForVisible(Array(0..<Int(visibleCount)), in: state) { screen.width = 301 }
        return Scene(slots: slots, state: state, service: service, delegate: delegate, window: window)
    }

    private func waitForVisible(_ indexes: [Int], in state: LayoutState, perform action: () -> Void) {
        let published = expectation(description: "Distribution publishes visible offers \(indexes)")
        let subscription = state.itemsPublisher
            .compactMap { $0[LayoutState.visibleOfferIndexesKey] as? [Int] }
            .filter { $0 == indexes }.first().sink { _ in published.fulfill() }
        action()
        wait(for: [published], timeout: 3)
        subscription.cancel()
        XCTAssertEqual(state.items[LayoutState.visibleOfferIndexesKey] as? [Int], indexes)
    }

    private func assertRemainsVisible(_ indexes: [Int], in state: LayoutState, perform action: () -> Void) {
        let changed = expectation(description: "The visible offers must not change")
        changed.isInverted = true
        let subscription = state.itemsPublisher
            .compactMap { $0[LayoutState.visibleOfferIndexesKey] as? [Int] }
            .filter { $0 != indexes }.sink { _ in changed.fulfill() }
        action()
        wait(for: [changed], timeout: 0.1)
        subscription.cancel()
        XCTAssertEqual(state.items[LayoutState.visibleOfferIndexesKey] as? [Int], indexes)
    }

    @MainActor
    private struct Scene {
        let slots: [SlotModel]
        let state: LayoutState
        let service: EventService
        let delegate: CatalogProductURLDelegate
        let window: UIWindow

        func tearDown() {
            window.isHidden = true
            window.rootViewController = nil
            state.actionCollection.reset()
        }
    }

    @MainActor
    private enum Distribution {
        case oneByOne, carousel, grouped

        func layout(children: [LayoutSchemaViewModel], slots: [SlotModel], visibleCount: UInt8,
                    state: LayoutState, service: EventService) -> LayoutSchemaViewModel {
            switch self {
            case .oneByOne:
                return .oneByOne(OneByOneViewModel(children: children, defaultStyle: nil, transition: nil,
                                                   eventService: service, slots: slots, layoutState: state))
            case .carousel:
                return .carousel(CarouselViewModel(children: children, defaultStyle: nil, viewableItems: [visibleCount],
                                                   peekThroughSize: [.fixed(0)], eventService: service, slots: slots,
                                                   layoutState: state))
            case .grouped:
                return .groupDistribution(GroupedDistributionViewModel(children: children, defaultStyle: nil,
                                                                       viewableItems: [visibleCount],
                                                                       transition: .fadeInOut(.init(duration: 0)),
                                                                       eventService: service, slots: slots, layoutState: state))
            }
        }
    }
}
