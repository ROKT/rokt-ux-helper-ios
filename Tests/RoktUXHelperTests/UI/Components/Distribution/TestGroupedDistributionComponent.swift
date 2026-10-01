import XCTest
import SwiftUI
import ViewInspector
import Combine
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15.0, *)
final class TestGroupedDistributionComponent: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()

    func test_grouped_distribution() throws {
        var closeActionCalled = false
        
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeGroupedDistribution(layoutState:eventService:)
        )

        let groupedComponent = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(GroupedDistributionComponent.self)
            .actualView()
        
        let grouped = try groupedComponent
            .inspect()
            .vStack()
        
        // test custom modifier class
        let paddingModifier = try grouped.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 3, right: 4, bottom: 5, left: 6))
        
        // test the effect of custom modifier
        let padding = try grouped.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 3.0, leading: 6.0, bottom: 5.0, trailing: 4.0))
        
        XCTAssertEqual(try grouped.accessibilityLabel().string(), "Page 1 of 1")

        groupedComponent.goToNextOffer()
        XCTAssertTrue(closeActionCalled)
    }
    
    func test_goToNextGroup_with_closeOnComplete_default() throws {
        var closeActionCalled = false
        
        let view = try TestPlaceHolder.make(
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeGroupedDistribution(layoutState:eventService:)
        )

        let groupedComponent = try view.inspect()
            .view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(GroupedDistributionComponent.self)
            .actualView()

        groupedComponent.goToNextGroup()
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
            layoutMaker: LayoutSchemaViewModel.makeGroupedDistribution(layoutState:eventService:)
        )
        
        let groupedComponent = try view.inspect()
            .view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(GroupedDistributionComponent.self)
            .actualView()

        groupedComponent.goToNextOffer()
        XCTAssertFalse(closeActionCalled)
    }
    
    func test_goToNextGroup_with_closeOnComplete_false() throws {
        var closeActionCalled = false
        let closeOnCompleteSettings = LayoutSettings(closeOnComplete: false, bottomSheetPresentation: nil)
        
        let view = try TestPlaceHolder.make(
            layoutSettings: closeOnCompleteSettings,
            eventHandler: { event in
                if event.eventType == .SignalDismissal {
                    closeActionCalled = true
                }
            },
            layoutMaker: LayoutSchemaViewModel.makeGroupedDistribution(layoutState:eventService:)
        )
        
        let groupedComponent = try view.inspect()
            .view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(GroupedDistributionComponent.self)
            .actualView()

        groupedComponent.goToNextGroup()
        XCTAssertFalse(closeActionCalled)
    }

    // MARK: - viewableItems

    // An empty `viewableItems` array previously floored the breakpoint index to 0 and indexed it
    // directly, trapping. A `[0]` array passed the index lookup but then zero stride-by-zero
    // trapped on the very next read of `pages`/`totalPages`. Both now resolve to a usable,
    // positive viewableItems count instead.
    @MainActor
    func test_setViewableItemsForBreakpoint_withEmptyViewableItems_leavesViewableItemsUnchanged() throws {
        let component = try makeGroupedDistributionComponent(viewableItems: [], childCount: 4)

        component.setViewableItemsForBreakpoint(320)

        XCTAssertGreaterThanOrEqual(component.viewableItems, 1)
    }

    @MainActor
    func test_setViewableItemsForBreakpoint_withZeroViewableItems_resolvesToAtLeastOne() throws {
        let component = try makeGroupedDistributionComponent(viewableItems: [0], childCount: 4)

        component.setViewableItemsForBreakpoint(320)

        XCTAssertGreaterThanOrEqual(component.viewableItems, 1)
        // Must not trap reading pages/totalPages with the resolved viewableItems.
        XCTAssertGreaterThan(component.totalPages, 0)
    }

    // MARK: - Helpers

    private func makeGroupedDistributionComponent(
        viewableItems: [UInt8],
        childCount: Int
    ) throws -> GroupedDistributionComponent {
        let children: [LayoutSchemaViewModel] = (0..<childCount).map { index in
            .basicText(BasicTextViewModel(
                value: "Offer \(index)",
                defaultStyle: nil,
                pressedStyle: nil,
                hoveredStyle: nil,
                disabledStyle: nil,
                layoutState: nil,
                diagnosticService: nil
            ))
        }
        let model = GroupedDistributionViewModel(
            children: children,
            defaultStyle: nil,
            viewableItems: viewableItems,
            transition: .fadeInOut(FadeInOutTransitionSettings(duration: 0)),
            eventService: nil,
            slots: [],
            layoutState: nil
        )

        return GroupedDistributionComponent(
            config: .init(parent: .column, position: 1),
            model: model,
            parentWidth: .constant(240),
            parentHeight: .constant(nil),
            styleState: .constant(.default),
            parentOverride: nil
        )
    }
}

@available(iOS 15.0, *)
extension LayoutSchemaViewModel {

    static func makeGroupedDistribution(
        layoutState: LayoutState,
        eventService: EventService
    ) throws -> Self {
        let slots = ModelTestData.PageModelData.withBNF().layoutPlugins?.first?.slots
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: slots!),
                                            layoutState: layoutState,
                                            eventService: eventService)
        let model = ModelTestData.GroupedDistributionData.groupedDistribution()
        return LayoutSchemaViewModel.groupDistribution(
            try transformer.getGroupedDistribution(
                groupedModel: model!, context: .outer(slots!.map(\.offer))
            )
        )
    }
}
