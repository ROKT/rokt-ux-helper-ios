//
//  RoktDecoder.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Foundation

@available(iOS 13, *)
struct RoktDecoder {

    func decode<T: Decodable>(_ type: T.Type, _ string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw RoktUXError.experienceResponseMapping
        }

        var result: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        let decodingThread = Thread {
            defer { semaphore.signal() }
            do {
                let decoded = try JSONDecoder().decode(type, from: data)
                result = .success(decoded)
            } catch {
                result = .failure(error)
            }
        }
        decodingThread.name = "com.rokt.decoder"
        decodingThread.stackSize = max(decodingThread.stackSize, 8 * 1024 * 1024)
        decodingThread.qualityOfService = Thread.current.qualityOfService
        decodingThread.start()

        semaphore.wait()

        return try result
            .unwrap(orThrow: RoktUXError.experienceResponseMapping)
            .get()
    }
}
