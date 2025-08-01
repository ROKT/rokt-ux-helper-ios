//
//  CarouselUIModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import SwiftUI
import DcuiSchema

@available(iOS 15, *)
class CarouselViewModel: DistributionViewModel, Identifiable, ObservableObject {
    let id: UUID = UUID()
    var children: [LayoutSchemaViewModel]?

    var totalOffers: Int {
        children?.count ?? 0
    }

    var totalPages: Int {
        pages.count
    }

    var pages: [[LayoutSchemaViewModel]] {
        guard let children else {
            return []
        }
        return stride(from: 0, to: totalOffers, by: viewableItems).map {
            Array(children[$0..<$0.advanced(by: min(viewableItems, children.endIndex - $0))])
        }
    }

    let defaultStyle: [CarouselDistributionStyles]?
    let allBreakpointViewableItems: [UInt8]
    let peekThroughSize: [PeekThroughSize]
    @Published var currentPage: Int = 0
    @Published var indexWithinPage: Int = 0
    @Published var viewableItems: Int = 1

    /// The left most offer index in a RTL layout
    @Published var currentLeadingOfferIndex: Int = 0

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(children: [LayoutSchemaViewModel]?,
         defaultStyle: [CarouselDistributionStyles]?,
         viewableItems: [UInt8],
         peekThroughSize: [PeekThroughSize],
         eventService: EventServicing?,
         slots: [SlotModel],
         layoutState: any LayoutStateRepresenting) {
        self.children = children ?? []
        self.defaultStyle = defaultStyle
        self.allBreakpointViewableItems = viewableItems
        self.peekThroughSize = peekThroughSize

        // Calculate initial page before super.init
        if let initialIndex = layoutState.items[LayoutState.currentProgressKey] as? Int,
           let childrenCount = children?.count,
           let firstViewableItems = viewableItems.first.map(Int.init) {
            let viewableItemCount = min(firstViewableItems, childrenCount)
            if initialIndex + viewableItemCount > childrenCount - 1 {
                self.currentPage = (childrenCount - viewableItemCount)/viewableItemCount
            } else if initialIndex >= 0 {
                self.currentPage = initialIndex/viewableItemCount
            }
        }

        super.init(eventService: eventService, slots: slots, layoutState: layoutState)

        self.currentLeadingOfferIndex = initialCurrentIndex ?? 0
    }

    func sendViewableImpressionEvents(currentLeadingOffer: Int) {
        for offer in currentLeadingOffer..<currentLeadingOffer + viewableItems {
            sendImpressionEvents(currentOffer: offer)
        }
    }

    func getGlobalBreakpointIndex(_ width: CGFloat?) -> Int {
        layoutState?.getGlobalBreakpointIndex(width) ?? 0
    }

    func registerActions() {
        layoutState?.actionCollection[.progressControlPrevious] = goToPreviousPage
        layoutState?.actionCollection[.progressControlNext] = goToNextPage
        layoutState?.actionCollection[.nextOffer] = goToNextOffer
    }

    func setupBindings(
        currentProgress: Binding<Int>,
        totalItems: Int,
        viewableItems: Binding<Int>,
        customStateMap: Binding<RoktUXCustomStateMap?>
    ) {
        // Store the raw values instead of bindings
        layoutState?.items[LayoutState.currentProgressKey] = currentProgress.wrappedValue
        layoutState?.items[LayoutState.totalItemsKey] = totalItems
        layoutState?.items[LayoutState.viewableItemsKey] = viewableItems.wrappedValue
        layoutState?.items[LayoutState.customStateMap] = customStateMap.wrappedValue
        self.viewableItems = viewableItems.wrappedValue
    }

    func goToNextOffer(_: Any?) {
        guard viewableItems == 1 else { return }
        if currentPage + 1 < children?.count ?? 0 {
            animateStateChange {
                self.currentPage += 1
                self.currentLeadingOfferIndex = self.currentPage
            }
        } else if layoutState?.closeOnComplete() == true {
            // when on last offer AND closeOnComplete is true
            closeOnComplete()
        }
    }

    func goToNextPage(_: Any?) {
        let totalPages = calculateTotalPages()
        if currentPage < totalPages - 1 {
            animateStateChange {
                self.currentPage += 1
                self.currentLeadingOfferIndex = (self.currentPage * self.viewableItems)
                self.indexWithinPage = 0
            }
        } else if layoutState?.closeOnComplete() == true {
            closeOnComplete()
        }
    }

    func goToPreviousPage(_: Any?) {
        let newCurrentPage = if indexWithinPage == 0 && currentPage != 0 {
            currentPage - 1
        } else {
            currentPage
        }
        animateStateChange {
            self.currentPage = newCurrentPage
            self.indexWithinPage = 0
            self.currentLeadingOfferIndex = self.currentPage * self.viewableItems
        }
    }

    private func closeOnComplete() {
        // when on last offer AND closeOnComplete is true
        if case .embeddedLayout = layoutState?.layoutType() {
            sendDismissalCollapsedEvent()
        } else {
            sendDismissalNoMoreOfferEvent()
        }
        close()
    }

    func close() {
        layoutState?.actionCollection[.close](nil)
    }

    private func calculateTotalPages() -> Int {
        guard let children = children, !children.isEmpty else { return 0 }
        let viewableItemCount = Int(allBreakpointViewableItems[getGlobalBreakpointIndex(nil)])
        return Int(ceil(Double(children.count)/Double(viewableItemCount)))
    }

    func animateStateChange(_ change: @escaping () -> Void) {
        withAnimation(.linear) {
            change()
        }
    }
}
