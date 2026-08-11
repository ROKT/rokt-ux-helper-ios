# Migration guide

This document provides guidance on migrating to newer versions of `rokt-ux-helper-ios`.

## Migrating to the LayoutFailure reason API

`RoktUXEvent.LayoutFailure` now includes `sessionId` and a `reason` so partners can tell
**no offer returned** apart from **rendering / integration failures**.

Existing checks for `event is RoktUXEvent.LayoutFailure` continue to work. Switch on
`reason` when you need the split:

```swift
if let failure = event as? RoktUXEvent.LayoutFailure {
    switch failure.reason {
    case .noOffers:
        // Offers request succeeded but nothing to show — not an integration bug.
        // Share failure.sessionId with your account manager.
        break
    case .invalidResponse:
        // Experience response could not be decoded or mapped.
        break
    case .invalidSchema:
        // Layout schema failed validation/transform.
        break
    case .missingEmbeddedTarget:
        // Host app did not provide a LayoutLoader for the embedded selector.
        break
    case .presentationFailed:
        // Overlay/bottom sheet could not find a suitable view controller to present from.
        break
    }
}
```

| Reason | Meaning |
|--------|---------|
| `.noOffers` | Response decoded but contained no renderable offers/layouts |
| `.invalidResponse` | Response could not be decoded or mapped |
| `.invalidSchema` | Layout schema validation/transform failed |
| `.missingEmbeddedTarget` | No `LayoutLoader` for the embedded placement target |
| `.presentationFailed` | Overlay/bottom sheet could not be presented |

Console logging (when enabled via `RoktUX.setLogLevel` / `RoktUXConfig`) now appends
`| sessionId=<id>` once the session is known, and uses distinct messages for `.noOffers`
versus rendering failures.

## Migrating to 2.0.0

Version **2.0.0** makes `SelectResponse` the single canonical response model. The raw
rendering entry points now decode the snake_case offers selection response directly,
and the legacy camel-case wire-response model tree has been removed. Rendering,
events, catalog and payment behaviour are unchanged — only the accepted input shape
and a handful of response model types are affected.

### Raw responses must be the snake_case selection response

`loadLayout(experienceResponse:)` (both overloads) and `parseExperience(_:)` now expect
the snake_case offers selection response (for example `session_id`, `session_token`,
`page_context`, `plugins[].plugin.config`, `outer_layout_schema`). Camel-case responses
from earlier versions are no longer accepted and will fail to decode. Direct and
server-to-server integrations should pass the response through unchanged rather than
re-serialising it.

### Removed response model types

The legacy wire-response types have been removed. They were only reachable when
decoding the old camel-case response and have no replacement — decode the snake_case
`SelectResponse` instead:

- `RoktUXExperienceResponse`
- `RoktUXS2SExperienceResponse`
- `RoktUXPlacementResponse`, `RoktUXPlacement`, `RoktUXPlacementContext`
- `RoktUXPage`, `RoktUXPageContext`
- `RoktUXOffer`, `RoktUXCreative`, `RoktUXSlot`

### `RoktUXParseResult` now carries the decoded response

`parseExperience(_:)` still returns a `RoktUXParseResult`, which now also exposes the
decoded `response: SelectResponse` alongside the existing `pageModel`. Render with
`pageModel` as before; use `response` for session-token and real-time-event handling.

> Note: `parseExperience(_:)`, `loadLayout(pageModel:)`, `RoktUXParseResult`,
> `RoktUXPageModel` and `SelectResponse` are intended for the Rokt mobile SDK and are
> not supported public integration APIs.

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
