//
//  CommonContainerStylingProperties.swift
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

import SwiftUI
import DcuiSchema

protocol CommonContainerStylingProperties {
    var justifyContent: FlexJustification? { get }
    var alignItems: FlexAlignment? { get }
    var shadow: Shadow? { get }
    var overflow: Overflow? { get }
    var blur: Float? { get }
}

extension ContainerStylingProperties: CommonContainerStylingProperties {}

extension ZStackContainerStylingProperties: CommonContainerStylingProperties {}
