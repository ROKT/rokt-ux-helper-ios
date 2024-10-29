//
//  ComponentConfig.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
struct ComponentConfig {
    let parent: ComponentParentType
    let position: Int?
    
    func updateParent(_ parent: ComponentParentType) -> ComponentConfig {
        return ComponentConfig(parent: parent, position: self.position)
    }    
    
    func updatePosition(_ position: Int?) -> ComponentConfig {
        return ComponentConfig(parent: self.parent, position: position)
    }
}
