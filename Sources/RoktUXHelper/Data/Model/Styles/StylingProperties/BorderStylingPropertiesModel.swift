//
//  BorderStylingPropertiesModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import DcuiSchema

@available(iOS 13, *)
struct BorderStylingPropertiesModel: Decodable, Hashable {
    let borderRadius: Float?
    let borderColor: ThemeColor?
    let borderWidth: Float?
    let borderStyle: BorderStyle?
}
