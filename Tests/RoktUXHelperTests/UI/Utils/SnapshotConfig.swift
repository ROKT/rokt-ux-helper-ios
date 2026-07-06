import SnapshotTesting

/// Shared snapshot configuration so all snapshot tests use the same device and precision.
/// Update this single constant when changing the target device or tolerance.
let snapshotDevice: ViewImageConfig = .iPhone13Pro(.portrait)

/// Fraction of pixels that must clear `snapshotPerceptualPrecision` to pass. Kept tight
/// (~200× headroom over the observed ~0.001% anti-aliasing jitter) to catch real regressions.
let snapshotPrecision: Float = 0.998

/// Per-pixel perceptual tolerance; absorbs sub-pixel anti-aliasing shifts in text rendering.
let snapshotPerceptualPrecision: Float = 0.98
