//
//  LazyPublished.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation
import Combine

@available(iOS 14.0, *)
@propertyWrapper
class LazyPublished<Value: Equatable>: ObservableObject {

    static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, LazyPublished>
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath].storage
        }
        set {
            let oldValue = instance[keyPath: storageKeyPath].storage
            if oldValue != newValue {
                (instance.objectWillChange as? ObservableObjectPublisher)?.send()
            }
            instance[keyPath: storageKeyPath].storage = newValue
        }
    }

    @available(
        *, unavailable,
         message: "@LazyPublished can only be applied to classes"
    )
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    var projectedValue: Published<Value>.Publisher {
        get { $storage }
        set { $storage = newValue }
    }

    @Published private var storage: Value

    init(wrappedValue: Value) {
        storage = wrappedValue
    }
}
