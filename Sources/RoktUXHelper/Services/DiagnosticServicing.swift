//
//  DiagnosticServicing.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

enum Severity: String, Codable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

protocol DiagnosticServicing: AnyObject {
    
    var pluginInstanceGuid: String { get }
    var pluginConfigJWTToken: String { get }
    var useDiagnosticEvents: Bool { get }
    
    func sendEvent(
        _ eventType: EventType,
        parentGuid: String,
        extraMetadata: [EventNameValue],
        attributes: [String: String],
        jwtToken: String
    )
    
    func sendDiagnostics(
        message: String,
        callStack: String,
        severity: Severity
    )
    
    func sendFontDiagnostics(_ fontFamily: String)
}

extension DiagnosticServicing {
    
    func sendDiagnostics(
        message: String,
        callStack: String,
        severity: Severity = .error
    ) {
        guard useDiagnosticEvents else { return }
        sendEvent(
            .SignalSdkDiagnostic,
            parentGuid: pluginInstanceGuid,
            extraMetadata: [],
            attributes: [
                kErrorCode: message,
                kErrorStackTrace: callStack,
                kErrorSeverity: severity.rawValue
            ],
            jwtToken: pluginConfigJWTToken
        )
    }
    
    func sendFontDiagnostics(_ fontFamily: String) {
        sendDiagnostics(message: kViewErrorCode,
                        callStack: kUIFontErrorMessage + fontFamily)
    }
}
