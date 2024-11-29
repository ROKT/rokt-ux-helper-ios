//
//  LayoutSchemaUIModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

protocol ComponentViewModel {}

@available(iOS 15, *)
extension OverlayViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension BottomSheetViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension RowViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension ColumnViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension ZStackViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension WhenViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension OneByOneViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension CarouselViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension GroupedDistributionViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension RichTextViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension BasicTextViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension CreativeResponseViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension StaticImageViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension DataImageViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension ProgressIndicatorViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension CloseButtonViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension StaticLinkViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension ProgressControlViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension ToggleButtonViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension CatalogStackedCollectionViewModel: ComponentViewModel {}

@available(iOS 15, *)
extension CatalogResponseButtonViewModel: ComponentViewModel {}

@available(iOS 15, *)
enum LayoutSchemaViewModel: Hashable {
    // top-level
    case overlay(OverlayViewModel)
    case bottomSheet(BottomSheetViewModel)

    case row(RowViewModel)
    case column(ColumnViewModel)
    case zStack(ZStackViewModel)
    case scrollableRow(RowViewModel)
    case scrollableColumn(ColumnViewModel)
    case when(WhenViewModel)
    case oneByOne(OneByOneViewModel)
    case carousel(CarouselViewModel)
    case groupDistribution(GroupedDistributionViewModel)

    case richText(RichTextViewModel)
    case basicText(BasicTextViewModel)
    case creativeResponse(CreativeResponseViewModel)
    case staticImage(StaticImageViewModel)
    case dataImage(DataImageViewModel)
    case progressIndicator(ProgressIndicatorViewModel)
    case closeButton(CloseButtonViewModel)
    case staticLink(StaticLinkViewModel)
    case progressControl(ProgressControlViewModel)
    case toggleButton(ToggleButtonViewModel)
    case catalogStackedCollection(CatalogStackedCollectionViewModel)
    case catalogResponseButton(CatalogResponseButtonViewModel)
    case empty
}

@available(iOS 15, *)
extension LayoutSchemaViewModel {
    var componentViewModel: ComponentViewModel? {
        switch self {
        case .overlay(let componentViewModel):
            componentViewModel
        case .bottomSheet(let componentViewModel):
            componentViewModel
        case .row(let componentViewModel):
            componentViewModel
        case .column(let componentViewModel):
            componentViewModel
        case .zStack(let componentViewModel):
            componentViewModel
        case .scrollableRow(let componentViewModel):
            componentViewModel
        case .scrollableColumn(let componentViewModel):
            componentViewModel
        case .when(let componentViewModel):
            componentViewModel
        case .oneByOne(let componentViewModel):
            componentViewModel
        case .carousel(let componentViewModel):
            componentViewModel
        case .groupDistribution(let componentViewModel):
            componentViewModel
        case .richText(let componentViewModel):
            componentViewModel
        case .basicText(let componentViewModel):
            componentViewModel
        case .creativeResponse(let componentViewModel):
            componentViewModel
        case .staticImage(let componentViewModel):
            componentViewModel
        case .dataImage(let componentViewModel):
            componentViewModel
        case .progressIndicator(let componentViewModel):
            componentViewModel
        case .closeButton(let componentViewModel):
            componentViewModel
        case .staticLink(let componentViewModel):
            componentViewModel
        case .progressControl(let componentViewModel):
            componentViewModel
        case .toggleButton(let componentViewModel):
            componentViewModel
        case .catalogStackedCollection(let componentViewModel):
            componentViewModel
        case .catalogResponseButton(let componentViewModel):
            componentViewModel
        case .empty:
            nil
        }
    }

    var isDomainMappableParent: Bool {
        componentViewModel is DomainMappableParent
    }
}

@available(iOS 15, *)
extension LayoutSchemaViewModel: Hashable {

    static func == (lhs: LayoutSchemaViewModel, rhs: LayoutSchemaViewModel) -> Bool {
        switch (lhs, rhs) {
        case (.richText(let lhsModel), .richText(let rhsModel)):
            return lhsModel == rhsModel
        case (.basicText(let lhsModel), .basicText(let rhsModel)):
            return lhsModel == rhsModel
        case (.catalogResponseButton(let lhs), .catalogResponseButton(let rhs)):
            return lhs == rhs
        case (.catalogStackedCollection(let lhs), .catalogStackedCollection(let rhs)):
            return lhs == rhs
        case (.column(let lhsModel), .column(let rhsModel)):
            return lhsModel == rhsModel
        case (.row(let lhsModel), .row(let rhsModel)):
            return lhsModel == rhsModel
        case (.zStack(let lhsModel), .zStack(let rhsModel)):
            return lhsModel == rhsModel
        case (.scrollableRow(let lhsModel), .scrollableRow(let rhsModel)):
            return lhsModel == rhsModel
        case (.scrollableColumn(let lhsModel), .scrollableColumn(let rhsModel)):
            return lhsModel == rhsModel
        case (.creativeResponse(let lhsModel), .creativeResponse(let rhsModel)):
            return lhsModel == rhsModel
        case (.staticImage(let lhsModel), .staticImage(let rhsModel)):
            return lhsModel == rhsModel
        case (.dataImage(let lhsModel), .dataImage(let rhsModel)):
            return lhsModel == rhsModel
        case (.progressIndicator(let lhsModel), .progressIndicator(let rhsModel)):
            return lhsModel == rhsModel
        case (.oneByOne(let lhsModel), .oneByOne(let rhsModel)):
            return lhsModel == rhsModel
        case (.carousel(let lhsModel), .carousel(let rhsModel)):
            return lhsModel == rhsModel
        case (.groupDistribution(let lhsModel), .groupDistribution(let rhsModel)):
            return lhsModel == rhsModel
        case (.when(let lhsModel), .when(let rhsModel)):
            return lhsModel == rhsModel
        case (.closeButton(let lhsModel), .closeButton(let rhsModel)):
            return lhsModel == rhsModel
        case (.staticLink(let lhsModel), .staticLink(let rhsModel)):
            return lhsModel == rhsModel
        case (.progressControl(let lhsModel), .progressControl(let rhsModel)):
            return lhsModel == rhsModel
        case (.toggleButton(let lhsModel), .toggleButton(let rhsModel)):
            return lhsModel == rhsModel
        case (.empty, .empty):
            return true
        default:
            return false
        }
    }
}
