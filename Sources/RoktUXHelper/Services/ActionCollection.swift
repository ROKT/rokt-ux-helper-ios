//
//  EventBus.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

enum RoktActionType: String {
    case close
    case nextOffer
    case unload
    case positiveEngaged
    case nextGroup
    case previousGroup
    case checkBoundingBox
    case checkBoundingBoxMissized
    case toggleCustomState
}

protocol ActionCollecting {
    typealias ShareFunction = ((Any?) -> Void)
    
    subscript(actionType: RoktActionType) -> ShareFunction { get set }
    
    func reset()
}

class ActionCollection: ActionCollecting {
    private let internalQueue = DispatchQueue(label: "com.rokt.actions",
                                              qos: .default,
                                              attributes: .concurrent)
    
    private var callbackMap: [RoktActionType: ShareFunction] = [RoktActionType: ShareFunction]()
    
    subscript(actionType: RoktActionType) -> ShareFunction {
        get {
            internalQueue.sync {
                if let callback = self.callbackMap[actionType] {
                    return { (param: Any?) in return callback(param) }
                }
                return { (_: Any?) in return }
            }
        }
        
        set {
            internalQueue.sync {
                callbackMap[actionType] = newValue
            }
        }
    }
    
    func reset() {
        internalQueue.sync {
            callbackMap.removeAll()
        }
    }
}
