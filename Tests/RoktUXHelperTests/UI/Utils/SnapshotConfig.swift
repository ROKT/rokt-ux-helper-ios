import SnapshotTesting

/// Shared snapshot configuration so all snapshot tests use the same device and precision.
/// Update this single constant when changing the target device or tolerance.
let snapshotDevice: ViewImageConfig = .iPhone13Pro(.portrait)

/// Fraction of pixels that must clear `snapshotPerceptualPrecision` for a snapshot to pass.
///
/// CoreText rasterizes glyph edges with minor, non-deterministic anti-aliasing:
/// identical views re-rendered on the same pinned simulator differ by a few dozen
/// pixels (~0.001%) between runs, which makes exact-pixel matching flaky. Allowing a
/// small fraction of pixels to differ absorbs that edge noise while a genuine layout
/// or content change (thousands of pixels) still fails.
///
/// Kept deliberately tight: `0.998` still leaves ~200× headroom over the observed
/// ~0.001% run-to-run jitter, so it absorbs the flake while minimising the chance of
/// masking a real regression. (An earlier `0.99` was verified to swallow an entire
/// iOS 26.2→26.3 point-release rendering shift — larger than same-runtime jitter — i.e.
/// too loose.) This is the fraction escape-hatch; per-pixel anti-aliasing is absorbed by
/// `snapshotPerceptualPrecision` below, not here.
let snapshotPrecision: Float = 0.998

/// Per-pixel perceptual tolerance for the pixels that are compared. Absorbs broad,
/// subtle sub-pixel shifts in text rendering without hiding real visual changes.
let snapshotPerceptualPrecision: Float = 0.98
