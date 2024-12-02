//
//  ComponentViewModel.swift
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
