//
//  FontDiagnosticsViewModel.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

class FontDiagnosticsViewModel {
    public init(processedFontDiagnostics: Set<FontDiagnostics> = Set<FontDiagnostics>()) {
        self.processedFontDiagnostics = processedFontDiagnostics
    }

    public var processedFontDiagnostics = Set<FontDiagnostics>()

    public func insertProcessedFontDiagnostics(_ fontFamily: String) -> Bool {
        let pendingFontDiagnostics = FontDiagnostics(fontFamily: fontFamily)
        return processedFontDiagnostics.insert(pendingFontDiagnostics).inserted
    }
}
