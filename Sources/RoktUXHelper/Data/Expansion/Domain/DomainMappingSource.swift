//
//  DomainMappingSource.swift
//  RoktUXHelper
//
//  Copyright 2020 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

/// Entities with values that can be used to transform `DomainMappable` properties
protocol DomainMappingSource {}

@available(iOS 13, *)
extension OfferModel: DomainMappingSource {}

@available(iOS 13, *)
extension CatalogItem: DomainMappingSource {}
