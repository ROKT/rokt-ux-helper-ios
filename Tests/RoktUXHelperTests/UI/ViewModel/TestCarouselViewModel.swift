import XCTest
import SwiftUI
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15, *)
final class TestCarouselViewModel: XCTestCase {
    var sut: CarouselViewModel!
    var mockLayoutState: MockLayoutState!
    var mockEventService: MockEventService!

    override func setUp() {
        super.setUp()
        mockLayoutState = MockLayoutState()
        mockEventService = MockEventService()

        // Create mock view models that will be converted to LayoutSchemaViewModel enum cases
        let mockViewModels = (0...3).map { index in
            BasicTextViewModel(
                value: "Item \(index)",
                defaultStyle: nil,
                pressedStyle: nil,
                hoveredStyle: nil,
                disabledStyle: nil,
                layoutState: mockLayoutState,
                diagnosticService: nil
            )
        }

        // Convert mock view models to LayoutSchemaViewModel enum cases
        let children = mockViewModels.map { LayoutSchemaViewModel.basicText($0) }

        sut = CarouselViewModel(
            children: children,
            defaultStyle: nil,
            viewableItems: [2], // Show 2 items at a time
            peekThroughSize: [],
            eventService: mockEventService,
            slots: [],
            layoutState: mockLayoutState
        )
        sut.viewableItems = 2 // Set viewable items to 2 for testing
    }

    override func tearDown() {
        mockEventService.reset()
        sut = nil
        mockLayoutState = nil
        mockEventService = nil
        super.tearDown()
    }

    // MARK: - goToPreviousPage Tests

    func testGoToPreviousPage_WhenIndexWithinPageIsZeroAndNotFirstPage_ShouldDecrementPage() {
        // Given
        sut.currentPage = 1
        sut.indexWithinPage = 0
        sut.currentLeadingOfferIndex = 2 // Starting at second page (2 items per page)

        // When
        sut.goToPreviousPage()

        // Then
        XCTAssertEqual(sut.currentPage, 0, "Current page should decrement")
        XCTAssertEqual(sut.indexWithinPage, 0, "Index within page should be reset to 0")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 0, "Leading offer index should be updated to first page")
    }

    func testGoToPreviousPage_WhenIndexWithinPageIsZeroAndFirstPage_ShouldStayOnFirstPage() {
        // Given
        sut.currentPage = 0
        sut.indexWithinPage = 0
        sut.currentLeadingOfferIndex = 0

        // When
        sut.goToPreviousPage()

        // Then
        XCTAssertEqual(sut.currentPage, 0, "Current page should remain at 0")
        XCTAssertEqual(sut.indexWithinPage, 0, "Index within page should remain at 0")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 0, "Leading offer index should remain at 0")
    }

    func testGoToPreviousPage_WhenIndexWithinPageIsNotZero_ShouldStayOnSamePage() {
        // Given
        sut.currentPage = 1
        sut.indexWithinPage = 1
        sut.currentLeadingOfferIndex = 2

        // When
        sut.goToPreviousPage()

        // Then
        XCTAssertEqual(sut.currentPage, 1, "Current page should not change")
        XCTAssertEqual(sut.indexWithinPage, 0, "Index within page should be reset to 0")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 2, "Leading offer index should be updated")
    }

    // MARK: - goToNextPage Tests

    func testGoToNextPage_WhenNotOnLastPage_ShouldIncrementPage() {
        // Given
        sut.currentPage = 0
        sut.indexWithinPage = 0
        sut.currentLeadingOfferIndex = 0

        // When
        sut.goToNextPage()

        // Then
        XCTAssertEqual(sut.currentPage, 1, "Current page should increment")
        XCTAssertEqual(sut.indexWithinPage, 0, "Index within page should be reset to 0")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 2, "Leading offer index should be updated to next page")
    }

    func testGoToNextPage_WhenOnLastPageAndCloseOnCompleteTrue_ShouldCallCloseOnComplete() {
        // Given
        var closeActionCalled = false
        mockLayoutState.actionCollection = ActionCollection()
        mockLayoutState.actionCollection[.close] = { _ in closeActionCalled = true }

        // Set to last page (with 4 items and 2 viewable items, last page is 1)
        sut.currentPage = 1
        sut.indexWithinPage = 0
        sut.currentLeadingOfferIndex = 2

        // Enable closeOnComplete
        mockLayoutState.shouldCloseOnComplete = true

        // When
        sut.goToNextPage()

        // Then
        XCTAssertTrue(closeActionCalled, "Close action should be called")
        XCTAssertEqual(sut.currentPage, 1, "Current page should remain unchanged")
        XCTAssertEqual(sut.indexWithinPage, 0, "Index within page should remain unchanged")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 2, "Leading offer index should remain unchanged")
    }

    func testGoToNextPage_WhenOnLastPageAndCloseOnCompleteFalse_ShouldStayOnLastPage() {
        // Given
        var closeActionCalled = false
        mockLayoutState.actionCollection = ActionCollection()
        mockLayoutState.actionCollection[.close] = { _ in closeActionCalled = true }

        // Set to last page
        sut.currentPage = 1
        sut.indexWithinPage = 0
        sut.currentLeadingOfferIndex = 2

        // Ensure closeOnComplete is false
        mockLayoutState.shouldCloseOnComplete = false

        // When
        sut.goToNextPage()

        // Then
        XCTAssertFalse(closeActionCalled, "Close action should not be called")
        XCTAssertEqual(sut.currentPage, 1, "Current page should remain unchanged")
        XCTAssertEqual(sut.indexWithinPage, 0, "Index within page should remain unchanged")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 2, "Leading offer index should remain unchanged")
    }

    // MARK: - goToNextOffer Tests

    func testGoToNextOffer_WhenViewableItemsIsNotOne_ShouldDoNothing() {
        // Given
        sut.viewableItems = 2
        sut.currentPage = 0
        sut.currentLeadingOfferIndex = 0

        // When
        sut.goToNextOffer()

        // Then
        XCTAssertEqual(sut.currentPage, 0, "Current page should remain unchanged")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 0, "Leading offer index should remain unchanged")
    }

    func testGoToNextOffer_WhenViewableItemsIsOneAndNotLastOffer_ShouldIncrementToNextOffer() {
        // Given
        sut.viewableItems = 1
        sut.currentPage = 0
        sut.currentLeadingOfferIndex = 0

        // When
        sut.goToNextOffer()

        // Then
        XCTAssertEqual(sut.currentPage, 1, "Current page should increment")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 1, "Leading offer index should increment")
    }

    func testGoToNextOffer_WhenOnLastOfferAndCloseOnCompleteTrue_ShouldCallCloseOnComplete() {
        // Given
        var closeActionCalled = false
        mockLayoutState.actionCollection = ActionCollection()
        mockLayoutState.actionCollection[.close] = { _ in closeActionCalled = true }

        sut.viewableItems = 1
        // Set to last offer (with 4 items total, last index is 3)
        sut.currentPage = 3
        sut.currentLeadingOfferIndex = 3

        // Enable closeOnComplete
        mockLayoutState.shouldCloseOnComplete = true

        // When
        sut.goToNextOffer()

        // Then
        XCTAssertTrue(closeActionCalled, "Close action should be called")
        XCTAssertEqual(sut.currentPage, 3, "Current page should remain unchanged")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 3, "Leading offer index should remain unchanged")
    }

    func testGoToNextOffer_WhenOnLastOfferAndCloseOnCompleteFalse_ShouldStayOnLastOffer() {
        // Given
        var closeActionCalled = false
        mockLayoutState.actionCollection = ActionCollection()
        mockLayoutState.actionCollection[.close] = { _ in closeActionCalled = true }

        sut.viewableItems = 1
        // Set to last offer
        sut.currentPage = 3
        sut.currentLeadingOfferIndex = 3

        // Ensure closeOnComplete is false
        mockLayoutState.shouldCloseOnComplete = false

        // When
        sut.goToNextOffer()

        // Then
        XCTAssertFalse(closeActionCalled, "Close action should not be called")
        XCTAssertEqual(sut.currentPage, 3, "Current page should remain unchanged")
        XCTAssertEqual(sut.currentLeadingOfferIndex, 3, "Leading offer index should remain unchanged")
    }

    // MARK: - CloseOnComplete Tests

    func testCloseOnComplete_WhenEmbeddedLayout_ShouldSendCollapsedEventAndExit() {
        // Given
        var closeActionCalled = false
        mockLayoutState.actionCollection = ActionCollection()
        mockLayoutState.actionCollection[.close] = { _ in closeActionCalled = true }
        mockLayoutState.shouldCloseOnComplete = true
        mockLayoutState.setLayoutType(.embeddedLayout)

        sut.viewableItems = 1
        sut.currentPage = 3 // Last offer
        sut.currentLeadingOfferIndex = 3

        // When
        sut.goToNextOffer() // This will trigger closeOnComplete

        // Then
        XCTAssertTrue(closeActionCalled, "Close action should be called")
        XCTAssertTrue(mockEventService.dismissalEventCalled, "Dismissal event should be sent")
        XCTAssertFalse(mockEventService.dismissalNoMoreOfferEventSent, "No more offer event should not be sent")
        XCTAssertEqual(mockEventService.dismissOption, .collapsed)
    }

    func testCloseOnComplete_WhenOverlayLayout_ShouldSendNoMoreOfferEventAndExit() {
        // Given
        var closeActionCalled = false
        mockLayoutState.actionCollection = ActionCollection()
        mockLayoutState.actionCollection[.close] = { _ in closeActionCalled = true }
        mockLayoutState.shouldCloseOnComplete = true
        mockLayoutState.setLayoutType(.overlayLayout)

        sut.viewableItems = 1
        sut.currentPage = 3 // Last offer
        sut.currentLeadingOfferIndex = 3

        // When
        sut.goToNextOffer() // This will trigger closeOnComplete

        // Then
        XCTAssertTrue(closeActionCalled, "Close action should be called")
        XCTAssertFalse(mockEventService.dismissalCollapsedEventSent, "Dismissal collapsed event should not be sent")
        XCTAssertEqual(mockEventService.dismissOption, .noMoreOffer)
    }

    // MARK: - Edge Cases

    func testGoToNextOffer_WhenChildrenIsNil_ShouldTreatAsEmpty() {
        // Given
        var closeActionCalled = false
        mockLayoutState.actionCollection = ActionCollection()
        mockLayoutState.actionCollection[.close] = { _ in closeActionCalled = true }
        mockLayoutState.shouldCloseOnComplete = true

        // Create a new CarouselViewModel with nil children
        sut = CarouselViewModel(
            children: nil,
            defaultStyle: nil,
            viewableItems: [1],
            peekThroughSize: [],
            eventService: mockEventService,
            slots: [],
            layoutState: mockLayoutState
        )
        sut.viewableItems = 1

        // When
        sut.goToNextOffer()

        // Then
        XCTAssertTrue(closeActionCalled, "Close action should be called immediately since children is nil")
        XCTAssertEqual(mockEventService.dismissOption, .noMoreOffer)
    }

    func testGoToNextPage_WhenChildrenIsNil_ShouldTreatAsEmpty() {
        // Given
        var closeActionCalled = false
        mockLayoutState.actionCollection = ActionCollection()
        mockLayoutState.actionCollection[.close] = { _ in closeActionCalled = true }
        mockLayoutState.shouldCloseOnComplete = true

        // Create a new CarouselViewModel with nil children
        sut = CarouselViewModel(
            children: nil,
            defaultStyle: nil,
            viewableItems: [2],
            peekThroughSize: [],
            eventService: mockEventService,
            slots: [],
            layoutState: mockLayoutState
        )
        sut.viewableItems = 2

        // When
        sut.goToNextPage()

        // Then
        XCTAssertTrue(closeActionCalled, "Close action should be called immediately since children is nil")
        XCTAssertEqual(mockEventService.dismissOption, .noMoreOffer)
    }

    // MARK: - Setup Bindings Tests

    func testSetupBindings_ShouldStoreValuesInLayoutState() {
        // Given
        let currentProgress = Binding.constant(2)
        let totalItems = 5
        let viewableItems = Binding.constant(3)
        let customStateMap: Binding<RoktUXCustomStateMap?> = Binding.constant(RoktUXCustomStateMap())

        // When
        sut.setupBindings(
            currentProgress: currentProgress,
            totalItems: totalItems,
            viewableItems: viewableItems,
            customStateMap: customStateMap
        )

        // Then
        XCTAssertEqual(
            mockLayoutState.items[LayoutState.currentProgressKey] as? Int,
            2,
            "Current progress should be stored in layout state"
        )
        XCTAssertEqual(
            mockLayoutState.items[LayoutState.totalItemsKey] as? Int,
            5,
            "Total items should be stored in layout state"
        )
        XCTAssertEqual(
            mockLayoutState.items[LayoutState.viewableItemsKey] as? Int,
            3,
            "Viewable items should be stored in layout state"
        )
        XCTAssertNotNil(mockLayoutState.items[LayoutState.customStateMap], "Custom state map should be stored in layout state")
        XCTAssertEqual(sut.viewableItems, 3, "Viewable items should be updated in view model")
    }

    func testSetupBindings_WithDifferentLayoutState_ShouldUpdateCorrectState() {
        // Given
        let currentProgress = Binding.constant(2)
        let totalItems = 5
        let viewableItems = Binding.constant(3)
        let customStateMap: Binding<RoktUXCustomStateMap?> = Binding.constant(RoktUXCustomStateMap())

        // Create a different layout state
        let differentLayoutState = MockLayoutState()

        // Create CarouselViewModel with different layout state
        sut = CarouselViewModel(
            children: [],
            defaultStyle: nil,
            viewableItems: [2],
            peekThroughSize: [],
            eventService: mockEventService,
            slots: [],
            layoutState: differentLayoutState
        )

        // When
        sut.setupBindings(
            currentProgress: currentProgress,
            totalItems: totalItems,
            viewableItems: viewableItems,
            customStateMap: customStateMap
        )

        // Then
        XCTAssertEqual(
            differentLayoutState.items[LayoutState.currentProgressKey] as? Int,
            2,
            "Current progress should be stored in the different layout state"
        )
        XCTAssertEqual(
            differentLayoutState.items[LayoutState.totalItemsKey] as? Int,
            5,
            "Total items should be stored in the different layout state"
        )
        XCTAssertEqual(
            differentLayoutState.items[LayoutState.viewableItemsKey] as? Int,
            3,
            "Viewable items should be stored in the different layout state"
        )
        XCTAssertNotNil(
            differentLayoutState.items[LayoutState.customStateMap],
            "Custom state map should be stored in the different layout state"
        )
        XCTAssertTrue(mockLayoutState.items.isEmpty, "Original layout state should remain empty")
        XCTAssertEqual(sut.viewableItems, 3, "Viewable items should be updated in view model")
    }

    func testSetupBindings_WithNilCustomStateMap_ShouldStoreNilInLayoutState() {
        // Given
        let currentProgress = Binding.constant(2)
        let totalItems = 5
        let viewableItems = Binding.constant(3)
        let customStateMap: Binding<RoktUXCustomStateMap?> = Binding.constant(nil)

        // When
        sut.setupBindings(
            currentProgress: currentProgress,
            totalItems: totalItems,
            viewableItems: viewableItems,
            customStateMap: customStateMap
        )

        // Then
        XCTAssertNil(mockLayoutState.items[LayoutState.customStateMap], "Nil custom state map should be stored as nil")
        XCTAssertEqual(sut.viewableItems, 3, "Viewable items should still be updated")
    }
}
