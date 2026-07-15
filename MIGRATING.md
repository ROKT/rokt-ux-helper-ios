# Migration guide

This document provides guidance on migrating to newer versions of `rokt-ux-helper-ios`.

## Migrating to 1.0.0

Version **1.0.0** trims the public API surface ahead of the first stable release. The changes below are the only ones that can affect callers.

> Note: log **configuration** is unchanged — `RoktUXLogLevel`, `RoktUX.setLogLevel(_:)`, and `RoktUXConfig.Builder.logLevel(_:)` all remain public. Only the deprecated `enableLogging(_:)` and the internal `RoktUXLogger` implementation are affected.

### Removed: `RoktUXConfig.Builder.enableLogging(_:)`

The deprecated `enableLogging(_:)` builder method has been removed. Use `logLevel(_:)` instead.

```swift
// Before
let config = RoktUXConfig.Builder()
    .enableLogging(true)
    .build()

// After
let config = RoktUXConfig.Builder()
    .logLevel(.debug)   // use .none to disable logging
    .build()
```

### `RoktUXLogger` is now internal

The `RoktUXLogger` implementation class is no longer part of the public API. Configure logging through the public log-level API instead of touching the logger directly.

```swift
// Before
RoktUXLogger.shared.logLevel = .debug

// After
RoktUX.setLogLevel(.debug)
// or per-configuration:
let config = RoktUXConfig.Builder().logLevel(.debug).build()
```

### Removed: `RoktUXPaymentProvider`

The unused `RoktUXPaymentProvider` type alias has been removed. Reference `PaymentProvider` directly (for example, via `CartItemDevicePay.paymentProvider`).

```swift
// Before
let provider: RoktUXPaymentProvider = cartItem.paymentProvider

// After
let provider: PaymentProvider = cartItem.paymentProvider
```

## Migrating from versions < 0.3.0

From version **0.3.0 onwards**, the `ImageLoader` class has been **renamed** to `RoktUXImageLoader` to maintain consistency with the library's naming conventions.
