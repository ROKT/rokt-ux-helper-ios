//
//  TestEventRequest.swift
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

import Foundation

extension Date {
    private static let EVENT_DATE_FORMAT = "yyyy-MM-dd'T'hh:mm:ss.SSS'Z'"
    private static let EVENT_DATE_LOCALE = "en"
    private static let EVENT_DATE_TIMEZONE = "UTC"
    
    /// Formats a date into the format used on Rokt Backend 
    func toIso8601String() -> String {
        return Date.eventDateFormatter.string(from: self)
    }

    private static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = EVENT_DATE_FORMAT
        formatter.locale = Locale(identifier: EVENT_DATE_LOCALE)
        formatter.timeZone = TimeZone(abbreviation: EVENT_DATE_TIMEZONE)
        return formatter
    }()
}
