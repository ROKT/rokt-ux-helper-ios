//
//  SnapshotConfig.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SnapshotTesting

/// Shared snapshot configuration so all snapshot tests use the same device and precision.
/// Update this single constant when changing the target device or tolerance.
let snapshotDevice: ViewImageConfig = .iPhone13Pro(.portrait)
