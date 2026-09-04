import Combine
import DcuiSchema
import SwiftUI
import ViewInspector
import XCTest
@testable import RoktUXHelper

@available(iOS 16.0, *)
@MainActor
final class TestBottomSheetState: XCTestCase {
    private let key = "BottomSheetExpandedState"
    private let mediumID = UISheetPresentationController.Detent.Identifier("roktMediumPercentage")

    func testOuterTogglePublishesExpansionToTheSharedSheetReader() async {
        let state = LayoutState()
        var changes: [Bool] = []
        let subscription = state.itemsPublisher
            .map { UIViewController.isBottomSheetExpanded(in: $0) }
            .removeDuplicates()
            .dropFirst()
            .sink { changes.append($0) }
        defer { subscription.cancel() }

        let button = makeButton(state: state, position: nil)
        button.model.handleToggle(position: nil)
        await waitUntil("Both sheet paths receive global expansion") { changes == [true] }
        button.model.handleToggle(position: nil)
        await waitUntil("Both sheet paths receive global collapse") { changes == [true, false] }
        XCTAssertNil(state.items[LayoutState.customStateMap])
    }

    func testGlobalExpansionOverridesLocalCollapseAndStaleRestoredGlobalCopy() {
        let state = restoredState(globalValue: 1)
        let local = LocalState([CustomStateIdentifiable(position: 0, key: key): 0,
                                CustomStateIdentifiable(position: nil, key: key): 0])
        state.items[LayoutState.customStateMap] = local.binding

        XCTAssertTrue(UIViewController.isBottomSheetExpanded(in: state.items))
        XCTAssertEqual(local.values?[CustomStateIdentifiable(position: 0, key: key)], 0)
    }

    func testOuterToggleExpandsAndCollapsesConfiguredSheet() async throws {
        let state = LayoutState()
        let button = makeButton(state: state, position: nil)
        let scene = try configureSheet(state: state, content: button.environmentObject(GlobalScreenSize()))
        defer { scene.tearDown() }

        try scene.modal.rootView.inspect().find(ViewType.HStack.self).callOnTapGesture()
        await waitForDetent(scene.sheet, expanded: true)
        XCTAssertEqual(state.globalCustomStateValue(for: key), 1)

        try scene.modal.rootView.inspect().find(ViewType.HStack.self).callOnTapGesture()
        await waitForDetent(scene.sheet, expanded: false)
        XCTAssertEqual(state.globalCustomStateValue(for: key), 0)
    }

    func testGlobalCollapseOverridesOlderOfferExpansionAndCanToggleAgain() async throws {
        let local = LocalState([CustomStateIdentifiable(position: 7, key: key): 1])
        let state = restoredState(globalValue: 0)
        state.items[LayoutState.customStateMap] = local.binding
        let scene = try configureSheet(state: state)
        defer { scene.tearDown() }
        await waitForDetent(scene.sheet, expanded: false)

        makeButton(state: state, position: nil).model.handleToggle(position: nil)
        await waitForDetent(scene.sheet, expanded: true)
        makeButton(state: state, position: nil).model.handleToggle(position: nil)
        await waitForDetent(scene.sheet, expanded: false)
        XCTAssertEqual(local.values?[CustomStateIdentifiable(position: 7, key: key)], 1)
    }

    func testRestoredGlobalExpansionAppliesWithoutAnOfferStateBinding() async throws {
        let state = restoredState(globalValue: 1)
        let scene = try configureSheet(state: state)
        defer { scene.tearDown() }
        await waitForDetent(scene.sheet, expanded: true)
        XCTAssertNil(state.items[LayoutState.customStateMap])
    }

    func testDetentChangeUpdatesAndPersistsGlobalOwnerWithoutLocalBinding() throws {
        var captured: [RoktPluginViewState] = []
        let state = restoredState(globalValue: 1, onChange: { captured.append($0) })
        let controller = UIViewController()
        controller.modalPresentationStyle = .pageSheet
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        let delegate = BottomSheetDetentSyncDelegate(layoutState: state, mediumId: mediumID)
        sheet.detents = [.custom(identifier: mediumID) { _ in 300 }, .large()]
        sheet.selectedDetentIdentifier = mediumID

        delegate.sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)
        XCTAssertEqual(state.globalCustomStateValue(for: key), 0)
        XCTAssertEqual(captured.last?.customStateMap?[CustomStateIdentifiable(position: nil, key: key)], 0)
        XCTAssertNil(state.items[LayoutState.customStateMap])

        sheet.selectedDetentIdentifier = .large
        delegate.sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)
        XCTAssertEqual(state.globalCustomStateValue(for: key), 1)
        XCTAssertEqual(captured.last?.customStateMap?[CustomStateIdentifiable(position: nil, key: key)], 1)
        let count = captured.count
        delegate.sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)
        XCTAssertEqual(captured.count, count, "An unchanged detent must not publish another saved state")
    }

    func testInitialDetentCallbackDoesNotCreateAnOfferOverride() throws {
        let state = LayoutState()
        let local = LocalState([CustomStateIdentifiable(position: 0, key: "another-state"): 1])
        state.items[LayoutState.customStateMap] = local.binding
        state.items[LayoutState.currentProgressKey] = Binding.constant(0)
        let controller = UIViewController()
        controller.modalPresentationStyle = .pageSheet
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        sheet.detents = [.custom(identifier: mediumID) { _ in 300 }]
        sheet.selectedDetentIdentifier = mediumID

        BottomSheetDetentSyncDelegate(layoutState: state, mediumId: mediumID)
            .sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)

        XCTAssertNil(state.globalCustomStateValue(for: key))
        XCTAssertNil(local.values?[CustomStateIdentifiable(position: 0, key: key)])
        XCTAssertEqual(local.values?[CustomStateIdentifiable(position: 0, key: "another-state")], 1)
    }

    func testDetentChangeKeepsExistingOfferStateLocal() throws {
        let state = LayoutState()
        let local = LocalState([CustomStateIdentifiable(position: 2, key: key): 1])
        state.items[LayoutState.customStateMap] = local.binding
        state.items[LayoutState.currentProgressKey] = Binding.constant(2)
        let controller = UIViewController()
        controller.modalPresentationStyle = .pageSheet
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        sheet.detents = [.custom(identifier: mediumID) { _ in 300 }]
        sheet.selectedDetentIdentifier = mediumID

        BottomSheetDetentSyncDelegate(layoutState: state, mediumId: mediumID)
            .sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)

        XCTAssertEqual(local.values?[CustomStateIdentifiable(position: 2, key: key)], 0)
        XCTAssertNil(state.globalCustomStateValue(for: key))
    }

    func testOfferToggleAndNavigationKeepExistingLocalBehaviour() async throws {
        let state = LayoutState()
        let schema = try JSONDecoder().decode(LayoutSchemaModel.self, from: Data(#"""
        {"type":"ToggleButtonStateTrigger","node":{"customStateKey":"BottomSheetExpandedState",
          "children":[{"type":"BasicText","node":{"value":"Toggle sheet"}}]}}
        """#.utf8))
        let slots = (0..<2).map { index in
            SlotModel(instanceGuid: "example-slot-\(index)", offer: .mock(),
                      layoutVariant: LayoutVariantModel(layoutVariantSchema: schema, moduleName: "standard-marketing"),
                      jwtToken: "")
        }
        let transformer = ProductCarouselIntegrationFixture.transformer(slots: slots, state: state)
        let layout = try transformer.transform(ProductCarouselIntegrationFixture.distributions[0],
                                               context: .outer(slots.map(\.offer)))
        guard case .oneByOne(let distribution) = layout,
              case .toggleButton(let button) = distribution.children?.first else {
            return XCTFail("Expected a toggle in the first offer")
        }
        let content = LayoutSchemaComponent(config: .init(parent: .column, position: nil), layout: layout,
                                            parentWidth: .constant(350), parentHeight: .constant(nil),
                                            styleState: .constant(.default))
            .environmentObject(GlobalScreenSize())
        let scene = try configureSheet(state: state, content: content)
        defer { scene.tearDown() }
        await waitUntil("Distribution registers its local state") { state.items[LayoutState.customStateMap] != nil }

        button.handleToggle(position: 0)
        await waitForDetent(scene.sheet, expanded: true)
        button.handleToggle(position: 0)
        await waitForDetent(scene.sheet, expanded: false)
        button.handleToggle(position: 0)
        await waitForDetent(scene.sheet, expanded: true)
        state.actionCollection[.progressControlNext](nil)
        await waitForDetent(scene.sheet, expanded: false)
        XCTAssertNil(state.globalCustomStateValue(for: key))
    }

    func testRemovingGlobalOwnerRestoresLegacyLocalReading() async throws {
        let state = restoredState(globalValue: 0)
        let local = LocalState([CustomStateIdentifiable(position: 4, key: key): 1])
        state.items[LayoutState.customStateMap] = local.binding
        let scene = try configureSheet(state: state)
        defer { scene.tearDown() }
        await waitForDetent(scene.sheet, expanded: false)

        state.resetGlobalCustomState(key: key)
        await waitForDetent(scene.sheet, expanded: true)
        XCTAssertNil(state.globalCustomStateValue(for: key))
    }

    private func restoredState(globalValue: Int, onChange: ((RoktPluginViewState) -> Void)? = nil) -> LayoutState {
        LayoutState(pluginId: "example-plugin",
                    initialPluginViewState: RoktPluginViewState(pluginId: "example-plugin", offerIndex: 0,
                                                                isPluginDismissed: false,
                                                                customStateMap: [CustomStateIdentifiable(position: nil,
                                                                                                         key: key): globalValue]),
                    onPluginViewStateChange: onChange)
    }

    private func makeButton(state: LayoutState, position: Int?) -> ToggleButtonComponent {
        let label = BasicTextViewModel(value: "Toggle sheet", defaultStyle: nil, pressedStyle: nil,
                                       hoveredStyle: nil, disabledStyle: nil, layoutState: state,
                                       diagnosticService: nil)
        let model = ToggleButtonViewModel(children: [.basicText(label)], customStateKey: key, defaultStyle: nil,
                                          pressedStyle: nil, hoveredStyle: nil, disabledStyle: nil, layoutState: state)
        return ToggleButtonComponent(config: .init(parent: .column, position: position), model: model,
                                     parentWidth: .constant(350), parentHeight: .constant(nil), parentOverride: nil)
    }

    private func configureSheet(state: LayoutState) throws -> Scene {
        try configureSheet(state: state, content: Text("Example offer"))
    }

    private func configureSheet<Content: View>(state: LayoutState, content: Content) throws -> Scene {
        let style = try JSONDecoder().decode(BottomSheetStyles.self, from: Data(#"""
        {"dimension":{"height":{"type":"percentage","value":50}}}
        """#.utf8))
        let model = BottomSheetViewModel(children: nil, allowBackdropToClose: false, defaultStyle: [style],
                                         eventService: nil, layoutState: state)
        let presenter = TestPresenter()
        presenter.present(placementType: .BottomSheet(.fixed), bottomSheetUIModel: model, layoutState: state,
                          eventService: nil, onLoad: {}, onUnLoad: {}) { _ in content }
        let modal = try XCTUnwrap(presenter.configuredController as? RoktUXSwiftUIViewController)
        let sheet = try XCTUnwrap(modal.sheetPresentationController)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = modal
        window.makeKeyAndVisible()
        modal.view.layoutIfNeeded()
        return Scene(window: window, modal: modal, sheet: sheet)
    }

    private func waitForDetent(_ sheet: UISheetPresentationController, expanded: Bool,
                               file: StaticString = #filePath, line: UInt = #line) async {
        let expected: UISheetPresentationController.Detent.Identifier = expanded ? .large : mediumID
        await waitUntil(expanded ? "Sheet expands" : "Sheet collapses", file: file, line: line) {
            sheet.selectedDetentIdentifier == expected && sheet.detents.map(\.identifier) == [expected]
        }
    }

    private func waitUntil(_ description: String, file: StaticString = #filePath, line: UInt = #line,
                           condition: @escaping () -> Bool) async {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        expectation.expectationDescription = description
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: 3)
        XCTAssertEqual(result, .completed, description, file: file, line: line)
    }

    @MainActor
    private final class LocalState {
        var values: RoktUXCustomStateMap?
        init(_ values: RoktUXCustomStateMap?) { self.values = values }
        var binding: Binding<RoktUXCustomStateMap?> {
            Binding(get: { self.values }, set: { self.values = $0 })
        }
    }

    // The package test host cannot complete UIKit modal presentations reliably. Capture the
    // controller configured by production, then mount its content using the existing test pattern.
    // These tests assert state and registered detents, not animated presentation geometry.
    private final class TestPresenter: UIViewController {
        var configuredController: UIViewController?
        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool,
                              completion: (() -> Void)? = nil) {
            configuredController = viewControllerToPresent
        }
    }

    @MainActor
    private struct Scene {
        let window: UIWindow
        let modal: RoktUXSwiftUIViewController
        let sheet: UISheetPresentationController

        func tearDown() {
            modal.detentObserverCancellable?.cancel()
            window.isHidden = true
            window.rootViewController = nil
        }
    }
}
