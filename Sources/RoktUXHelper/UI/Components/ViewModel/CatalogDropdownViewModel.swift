import Foundation
import DcuiSchema
import Combine

@available(iOS 15, *)
class CatalogDropdownViewModel: Identifiable, Hashable, ScreenSizeAdaptive {
    let id: UUID = UUID()

    let ownStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?
    let headStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?
    let iconStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?
    let optionListStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?
    let optionStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?
    let errorStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?

    let placeholderValue: String?
    let unavailableValue: String?
    let validatorFieldConfig: ValidatorFieldConfig?
    let a11yLabel: String?

    weak var layoutState: (any LayoutStateRepresenting)?
    weak var eventService: EventServicing?

    // ScreenSizeAdaptive conformance
    var defaultStyle: [CatalogDropdownStyles]? {
        ownStyles?.compactMap { $0.default }
    }

    var imageLoader: RoktUXImageLoader? {
        layoutState?.imageLoader
    }

    init(ownStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?,
         headStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?,
         iconStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?,
         optionListStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?,
         optionStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?,
         errorStyles: [FormStateStylingBlock<CatalogDropdownStyles>]?,
         placeholderValue: String?,
         unavailableValue: String?,
         validatorFieldConfig: ValidatorFieldConfig?,
         a11yLabel: String?,
         layoutState: (any LayoutStateRepresenting)?,
         eventService: EventServicing?) {
        self.ownStyles = ownStyles
        self.headStyles = headStyles
        self.iconStyles = iconStyles
        self.optionListStyles = optionListStyles
        self.optionStyles = optionStyles
        self.errorStyles = errorStyles
        self.placeholderValue = placeholderValue
        self.unavailableValue = unavailableValue
        self.validatorFieldConfig = validatorFieldConfig
        self.a11yLabel = a11yLabel
        self.layoutState = layoutState
        self.eventService = eventService
    }

    // MARK: - Data Access

    var catalogItemGroup: CatalogItemGroup? {
        guard let offer = layoutState?.items[LayoutState.fullOfferKey] as? OfferModel else { return nil }
        return offer.catalogItemGroup
    }

    var catalogItems: [CatalogItem]? {
        guard let offer = layoutState?.items[LayoutState.fullOfferKey] as? OfferModel else { return nil }
        return offer.catalogItems
    }

    var options: [CatalogItemGroupOption] {
        catalogItemGroup?.attributes?.first?.options ?? []
    }

    var attributeLabel: String? {
        catalogItemGroup?.attributes?.first?.label
    }

    func catalogItem(for option: CatalogItemGroupOption) -> CatalogItem? {
        guard let catalogItemId = option.catalogItemIds?.first,
              let items = catalogItems else { return nil }
        return items.first { $0.catalogItemId == catalogItemId }
    }

    func isOptionDisabled(at index: Int) -> Bool {
        guard index < options.count else { return false }
        let option = options[index]
        guard let item = catalogItem(for: option) else { return false }
        return item.inventoryStatus?.caseInsensitiveCompare("OutOfStock") == .orderedSame
    }

    // MARK: - Selection State

    var persistedSelectedIndex: Int? {
        get {
            guard let dict = layoutState?.items[LayoutState.catalogDropdownSelectedIndexKey] as? [String: Int] else {
                return nil
            }
            return dict[id.uuidString]
        }
        set {
            var dict = (layoutState?.items[LayoutState.catalogDropdownSelectedIndexKey] as? [String: Int]) ?? [:]
            dict[id.uuidString] = newValue
            layoutState?.items[LayoutState.catalogDropdownSelectedIndexKey] = dict
        }
    }

    func displayText(for selectedIndex: Int?) -> String {
        if let index = selectedIndex, index < options.count {
            let option = options[index]
            if isOptionDisabled(at: index) {
                return unavailableValue ?? option.label ?? ""
            }
            return option.label ?? ""
        }
        return placeholderValue ?? ""
    }

    func selectItem(at index: Int) {
        guard index < options.count, !isOptionDisabled(at: index) else { return }

        persistedSelectedIndex = index

        let option = options[index]
        if let item = catalogItem(for: option) {
            layoutState?.items[LayoutState.activeCatalogItemKey] = item
        }

        layoutState?.publishStateChange()
    }

    // MARK: - Hashable

    static func == (lhs: CatalogDropdownViewModel, rhs: CatalogDropdownViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
