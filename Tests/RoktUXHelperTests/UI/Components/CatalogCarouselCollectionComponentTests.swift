import XCTest
import SwiftUI
import Combine
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class CatalogCarouselCollectionComponentTests: XCTestCase {
    func test_collectionCombinesInheritedAndStyleDisabledStates() throws {
        for (inheritedEnabled, styleState) in [(false, StyleState.default), (true, .disabled), (true, .default)] {
            let mounted = expectation(description: "Catalog collection is mounted")
            let model = CatalogCarouselTestFixture.model(slots: try CatalogCarouselTestFixture.slots(count: 2),
                                                         callbacks: .init(onMount: { _ in mounted.fulfill() }))
            let screen = GlobalScreenSize()
            screen.width = 300
            let root = LayoutSchemaComponent(config: ComponentConfig(parent: .column, position: 1),
                                             layout: .catalogCarouselCollection(model),
                                             parentWidth: .constant(300), parentHeight: .constant(nil),
                                             styleState: .constant(styleState))
                .frame(width: 300)
                .environmentObject(screen)
                .disabled(!inheritedEnabled)
            let host = UIHostingController(rootView: root)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
            window.rootViewController = host
            window.isHidden = false
            defer {
                window.isHidden = true
                window.rootViewController = nil
            }
            host.view.layoutIfNeeded()
            wait(for: [mounted], timeout: 3)
            let controller = try XCTUnwrap(carouselController(in: host))
            XCTAssertEqual(controller.scrollView.isUserInteractionEnabled, inheritedEnabled && styleState != .disabled)
            XCTAssertEqual(controller.scrollView.isScrollEnabled, inheritedEnabled && styleState != .disabled)
        }
    }

    func test_componentDispatchMeasuresChangingContentAndViewportWidth() throws {
        let state = LayoutState()
        let slots = try CatalogCarouselTestFixture.slots(count: 2)
        var texts: [BasicTextViewModel] = []
        let model = CatalogCarouselCollectionViewModel(slots: slots, offerIndex: 1,
                                                       viewableItems: [1], peekThroughSize: [], layoutState: state) { context in
            let text = BasicTextViewModel(value: context.catalogItem.title, defaultStyle: nil, pressedStyle: nil,
                                          hoveredStyle: nil, disabledStyle: nil, layoutState: state,
                                          diagnosticService: nil, catalogItemContext: context)
            texts.append(text)
            return .basicText(text)
        }
        let screen = GlobalScreenSize()
        screen.width = 200
        screen.height = 800
        func root(width: CGFloat) -> some View {
            LayoutSchemaComponent(config: ComponentConfig(parent: .column, position: 1),
                                  layout: .catalogCarouselCollection(model),
                                  parentWidth: .constant(width), parentHeight: .constant(nil),
                                  styleState: .constant(.default))
                .frame(width: width)
                .environmentObject(screen)
        }
        let measured = expectation(description: "Initial card height measured")
        let initialMeasurement = model.$contentHeight.compactMap { $0 }.filter { $0 > 0 }.first().sink { _ in measured.fulfill() }
        let host = UIHostingController(rootView: root(width: 200))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 800))
        window.rootViewController = host
        window.isHidden = false
        defer {
            initialMeasurement.cancel()
            window.isHidden = true
            window.rootViewController = nil
        }
        host.view.layoutIfNeeded()
        wait(for: [measured], timeout: 3)
        let initialHeight = try XCTUnwrap(model.contentHeight)

        let expanded = expectation(description: "Expanded card height measured")
        let expansionMeasurement = model.$contentHeight.compactMap { $0 }.filter { $0 > initialHeight }.first()
            .sink { _ in expanded.fulfill() }
        defer { expansionMeasurement.cancel() }
        texts[0].updateDataBinding(dataBinding: .value(String(repeating: "Expanded product description ", count: 25)))
        wait(for: [expanded], timeout: 3)
        let expandedHeight = try XCTUnwrap(model.contentHeight)

        let rotated = expectation(description: "Wider cards remeasured")
        let rotationMeasurement = model.$contentHeight.compactMap { $0 }.filter { $0 > 0 && $0 < expandedHeight }.first()
            .sink { _ in rotated.fulfill() }
        defer { rotationMeasurement.cancel() }
        screen.width = 400
        window.frame.size.width = 400
        host.rootView = root(width: 400)
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        wait(for: [rotated], timeout: 3)
        XCTAssertLessThan(try XCTUnwrap(model.contentHeight), expandedHeight)
        XCTAssertNil(state.items[LayoutState.activeCatalogItemKey])
        XCTAssertNil(state.items[LayoutState.currentProgressKey])
    }

    private func carouselController(in parent: UIViewController) -> CatalogCarouselViewController? {
        if let carousel = parent as? CatalogCarouselViewController { return carousel }
        return parent.children.lazy.compactMap { self.carouselController(in: $0) }.first
    }
}
