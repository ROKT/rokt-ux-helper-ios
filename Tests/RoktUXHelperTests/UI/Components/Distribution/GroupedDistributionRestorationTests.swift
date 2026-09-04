import XCTest
import SwiftUI
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class GroupedDistributionRestorationTests: XCTestCase {
    func test_defaultIndexRendersFirstOffer() throws {
        let scene = try makeScene(initialOfferIndex: nil)
        defer { scene.tearDown() }

        try assertScene(scene, currentGroup: 0, visibleIndexes: [0], viewableItems: 1)
    }

    func test_restoredLastValidIndexRendersThatOffer() throws {
        let scene = try makeScene(initialOfferIndex: 2)
        defer { scene.tearDown() }

        try assertScene(scene, currentGroup: 2, visibleIndexes: [2], viewableItems: 1)
    }

    func test_negativeRestoredIndexesRenderFirstOffer() throws {
        for index in [-1, Int.min] {
            let scene = try makeScene(initialOfferIndex: index)
            defer { scene.tearDown() }

            try assertScene(scene, currentGroup: 0, visibleIndexes: [0], viewableItems: 1)
        }
    }

    func test_staleRestoredIndexesRenderLastOffer() throws {
        for index in [3, Int.max] {
            let scene = try makeScene(initialOfferIndex: index)
            defer { scene.tearDown() }

            try assertScene(scene, currentGroup: 2, visibleIndexes: [2], viewableItems: 1)
        }
    }

    func test_restoredGroupSupportsNextAndPreviousNavigation() throws {
        let scene = try makeScene(initialOfferIndex: 1)
        defer { scene.tearDown() }

        try assertScene(scene, currentGroup: 1, visibleIndexes: [1], viewableItems: 1)
        scene.state.actionCollection[.progressControlNext](nil)
        try waitForRenderedOffer(2, in: scene)
        try assertScene(scene, currentGroup: 2, visibleIndexes: [2], viewableItems: 1)

        scene.state.actionCollection[.progressControlPrevious](nil)
        try waitForRenderedOffer(1, in: scene)
        try assertScene(scene, currentGroup: 1, visibleIndexes: [1], viewableItems: 1)
    }

    func test_restoredOfferRemainsVisibleWhenBreakpointChangesGroupSize() throws {
        let scene = try makeScene(initialOfferIndex: 2, viewableItems: [1, 2])
        defer { scene.tearDown() }

        try assertScene(scene, currentGroup: 2, visibleIndexes: [2], viewableItems: 1)
        scene.screen.width = 500
        try waitFor("The wider breakpoint has applied its grouping and rendered height") {
            guard let count = scene.state.items[LayoutState.viewableItemsKey] as? Binding<Int>,
                  let indexes = scene.state.items[LayoutState.visibleOfferIndexesKey] as? [Int] else { return false }
            return count.wrappedValue == 2 && abs(scene.measurement.height - scene.height(for: indexes)) < 0.5
        }
        try assertScene(scene, currentGroup: 1, visibleIndexes: [2], viewableItems: 2)
    }

    private func waitForRenderedOffer(_ index: Int, in scene: Scene,
                                      file: StaticString = #filePath, line: UInt = #line) throws {
        try waitFor("Grouped distribution has rendered offer \(index)", file: file, line: line) {
            scene.state.items[LayoutState.visibleOfferIndexesKey] as? [Int] == [index]
                && abs(scene.measurement.height - scene.height(for: [index])) < 0.5
        }
    }

    private func assertScene(_ scene: Scene, currentGroup: Int, visibleIndexes: [Int], viewableItems: Int,
                             file: StaticString = #filePath, line: UInt = #line) throws {
        let progress = try XCTUnwrap(scene.state.items[LayoutState.currentProgressKey] as? Binding<Int>,
                                     file: file, line: line)
        let count = try XCTUnwrap(scene.state.items[LayoutState.viewableItemsKey] as? Binding<Int>,
                                  file: file, line: line)
        XCTAssertEqual(progress.wrappedValue, currentGroup, "The mounted group binding must reflect restored state",
                       file: file, line: line)
        XCTAssertEqual(count.wrappedValue, viewableItems, file: file, line: line)
        XCTAssertEqual(scene.state.items[LayoutState.visibleOfferIndexesKey] as? [Int], visibleIndexes,
                       file: file, line: line)
        XCTAssertEqual(scene.measurement.height, scene.height(for: visibleIndexes), accuracy: 0.5,
                       "Distinct fixed offer heights identify the children actually rendered", file: file, line: line)
    }

    private func makeScene(initialOfferIndex: Int?, viewableItems: [UInt8] = [1]) throws -> Scene {
        let heights: [CGFloat] = [40, 80, 160]
        let slots = heights.indices.map { index in
            SlotModel(instanceGuid: "example-slot-\(index)", offer: .mock(), layoutVariant: nil, jwtToken: "")
        }
        let state = LayoutState(initialPluginViewState: .init(pluginId: "example-plugin", offerIndex: initialOfferIndex))
        state.items[LayoutState.layoutSettingsKey] = LayoutSettings(closeOnComplete: false, bottomSheetPresentation: nil)
        state.items[LayoutState.breakPointsSharedKey] = ["wide": Float(400)]
        let children = heights.enumerated().map { index, height in
            let style = BasicTextStyle(dimension: .init(minWidth: nil, maxWidth: nil, width: nil,
                                                        minHeight: nil, maxHeight: nil, height: .fixed(Float(height)),
                                                        rotateZ: nil),
                                       flexChild: nil, spacing: nil, background: nil, text: nil)
            return LayoutSchemaViewModel.basicText(BasicTextViewModel(value: "Example offer \(index)",
                                                                      defaultStyle: [style], pressedStyle: nil,
                                                                      hoveredStyle: nil, disabledStyle: nil,
                                                                      layoutState: state, diagnosticService: nil))
        }
        let model = GroupedDistributionViewModel(children: children, defaultStyle: nil, viewableItems: viewableItems,
                                                 transition: .fadeInOut(.init(duration: 0)), eventService: nil,
                                                 slots: slots, layoutState: state)
        let screen = GlobalScreenSize()
        screen.width = 300
        screen.height = 800
        let measurement = Measurement()
        let root = LayoutSchemaComponent(config: ComponentConfig(parent: .column, position: nil),
                                         layout: .groupDistribution(model), parentWidth: .constant(300),
                                         parentHeight: .constant(nil), styleState: .constant(.default))
            .fixedSize(horizontal: false, vertical: true)
            .readSize { measurement.height = $0.height }
            .frame(width: 300, height: 500, alignment: .topLeading)
            .environmentObject(screen)
        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 800))
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        let scene = Scene(state: state, screen: screen, window: window, measurement: measurement, heights: heights)
        do {
            try waitFor("Grouped distribution has mounted, registered bindings, and measured its child") {
                state.items[LayoutState.currentProgressKey] is Binding<Int>
                    && state.items[LayoutState.visibleOfferIndexesKey] is [Int]
                    && measurement.height > 0
            }
            return scene
        } catch {
            scene.tearDown()
            throw error
        }
    }

    private func waitFor(_ description: String, file: StaticString = #filePath, line: UInt = #line,
                         matches: @escaping () -> Bool) throws {
        let ready = expectation(for: NSPredicate { _, _ in matches() }, evaluatedWith: nil)
        ready.expectationDescription = description
        let result = XCTWaiter.wait(for: [ready], timeout: 3)
        XCTAssertEqual(result, .completed, description, file: file, line: line)
        guard result == .completed else { throw WaitError.timedOut }
    }

    private enum WaitError: Error { case timedOut }

    private final class Measurement {
        var height: CGFloat = 0
    }

    @MainActor
    private struct Scene {
        let state: LayoutState
        let screen: GlobalScreenSize
        let window: UIWindow
        let measurement: Measurement
        let heights: [CGFloat]

        func height(for indexes: [Int]) -> CGFloat {
            indexes.reduce(0) { result, index in result + (heights[safe: index] ?? 0) }
        }

        func tearDown() {
            window.isHidden = true
            window.rootViewController = nil
            state.actionCollection.reset()
        }
    }
}
