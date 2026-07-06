import SnapshotTesting

/// Shared snapshot configuration so all snapshot tests use the same device and precision.
/// Update this single constant when changing the target device or tolerance.
let snapshotDevice: ViewImageConfig = .iPhone13Pro(.portrait)

/// Fraction of pixels that must match for an image snapshot to pass.
///
/// CoreText rasterizes glyph edges with minor, non-deterministic anti-aliasing:
/// identical views re-rendered on the same pinned simulator differ by a few dozen
/// pixels (~0.001%) between runs, which makes exact-pixel matching flaky. Allowing a
/// small fraction of pixels to differ absorbs that edge noise while a genuine layout
/// or content change (thousands of pixels) still fails.
let snapshotPrecision: Float = 0.99

/// Per-pixel perceptual tolerance for the pixels that are compared. Absorbs broad,
/// subtle sub-pixel shifts in text rendering without hiding real visual changes.
let snapshotPerceptualPrecision: Float = 0.98
