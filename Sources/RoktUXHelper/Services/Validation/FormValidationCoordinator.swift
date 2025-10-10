//
//  FormValidationCoordinator.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

enum ValidationStatus: Equatable {
    case valid
    case invalid
}

protocol FormValidationCoordinating: AnyObject {
    typealias ValidationClosure = () -> ValidationStatus

    func registerField(
        key: String,
        validation: @escaping ValidationClosure,
        onStatusChange: @escaping (ValidationStatus) -> Void
    )

    func unregisterField(for key: String)

    @discardableResult
    func validate(fields keys: [String]) -> Bool

    @discardableResult
    func validate(field key: String) -> Bool
}

final class FormValidationCoordinator: FormValidationCoordinating {
    private struct Registration {
        var validation: ValidationClosure
        var onStatusChange: (ValidationStatus) -> Void
        var lastStatus: ValidationStatus?
    }

    private var registrations: [String: Registration] = [:]
    private let queue = DispatchQueue(label: "com.roktuxhelper.validation", attributes: .concurrent)

    func registerField(
        key: String,
        validation: @escaping ValidationClosure,
        onStatusChange: @escaping (ValidationStatus) -> Void
    ) {
        queue.async(flags: .barrier) {
            self.registrations[key] = Registration(
                validation: validation,
                onStatusChange: onStatusChange,
                lastStatus: nil
            )
        }
    }

    func unregisterField(for key: String) {
        queue.async(flags: .barrier) {
            self.registrations.removeValue(forKey: key)
        }
    }

    @discardableResult
    func validate(fields keys: [String]) -> Bool {
        keys.allSatisfy { validate(field: $0) }
    }

    @discardableResult
    func validate(field key: String) -> Bool {
        var registration: Registration?
        queue.sync {
            registration = registrations[key]
        }

        guard var registration else { return true }

        let status = registration.validation()
        registration.lastStatus = status

        queue.async(flags: .barrier) {
            self.registrations[key] = registration
        }

        DispatchQueue.main.async {
            registration.onStatusChange(status)
        }

        return status == .valid
    }
}
