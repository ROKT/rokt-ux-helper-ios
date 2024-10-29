//
//  SSOT+Extension.swift
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

@available(iOS 13, *)
extension FontJustification {
    var asHorizontalAlignmentProperty: HorizontalAlignmentProperty {
        switch self {
        case .right:
            return .end
        case .center:
            return .center
        case .left:
            return .start
        case .end:
            return (DeviceLanguage.direction() == .leftToRight) ? .end : .start
        case .start, .justify:
            return (DeviceLanguage.direction() == .leftToRight) ? .start : .end
        }
    }

    var asAlignment: Alignment {
        switch self {
        case .right:
            return .trailing
        case .center:
            return .center
        case .left:
            return .leading
        case .end:
            return (DeviceLanguage.direction() == .leftToRight) ? .trailing : .leading
        case .start, .justify:
            return (DeviceLanguage.direction() == .leftToRight) ? .leading : .trailing
        }
    }

    var asTextAlignment: TextAlignment {
        switch self {
        case .right:
            return .trailing
        case .center:
            return .center
        case .left:
            return .leading
        case .end:
            return (DeviceLanguage.direction() == .leftToRight) ? .trailing : .leading
        case .start, .justify:
            return (DeviceLanguage.direction() == .leftToRight) ? .leading : .trailing
        }
    }
}

struct DeviceLanguage {
    static func direction() -> Locale.LanguageDirection {
        guard let language = Locale.current.languageCode else { return .leftToRight }

        return Locale.characterDirection(forLanguage: language)
    }
}
