import Foundation

/// The result of parsing an experience response via ``RoktUX/parseExperience(_:)``.
///
/// Carries the decoded page model alongside the parse window so hosts can reuse the
/// model for rendering (avoiding a second decode) and report JSON parse timing metrics.
public struct RoktUXParseResult {
    /// The session identifier from the experience response. Available whenever the
    /// response decodes successfully, even if it contains no renderable layouts.
    public let sessionId: String
    /// The page identifier from the experience response, when present.
    public let pageId: String?
    /// The decoded page model, ready to be rendered via `loadLayout(pageModel:)`.
    /// `nil` when the response decodes but contains no renderable layouts.
    public let pageModel: RoktUXPageModel?
    /// The moment decoding of the experience response started.
    public let parseStart: Date
    /// The moment decoding of the experience response finished.
    public let parseEnd: Date
}
