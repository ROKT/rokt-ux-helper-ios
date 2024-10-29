//
//  UIFont+Extension.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import UIKit

extension UIFont {
    func including(symbolicTraits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        var currentTraits = self.fontDescriptor.symbolicTraits
        currentTraits.update(with: symbolicTraits)
        return withOnly(symbolicTraits: currentTraits)
    }

    private func withOnly(symbolicTraits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        guard let fontDescriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) else { return nil }
        return .init(descriptor: fontDescriptor, size: pointSize)
    }
}
