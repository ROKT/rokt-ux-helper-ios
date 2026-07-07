import XCTest
import SwiftUI
@testable import RoktUXHelper

@available(iOS 15, *)
final class RoktUXParseExperienceTests: XCTestCase {

    // MARK: - Fixtures

    /// Builds an SDK-shaped experience response embedding the given plugins JSON.
    private func makeExperienceResponse(
        sessionId: String = "test-session-id",
        pageId: String? = "test-page-id",
        pluginsJSON: String = "[]"
    ) -> String {
        let page = pageId.map { #""page": {"pageId": "\#($0)"},"# } ?? ""
        return """
        {
          "sessionId": "\(sessionId)",
          \(page)
          "placementContext": {
            "roktTagId": "123",
            "pageInstanceGuid": "test-page-instance-guid",
            "token": "context-token"
          },
          "placements": [],
          "token": "",
          "plugins": \(pluginsJSON)
        }
        """
    }

    /// Extracts the plugins array (with a complete layout schema) from the
    /// embedded one-by-one fixture so the SDK-shaped response renders.
    private func pluginsFromEmbeddedFixture() throws -> String {
        let data = ModelTestData.toData(jsonFilename: "embedded_onebyone")
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let plugins = try XCTUnwrap(json["plugins"])
        let pluginsData = try JSONSerialization.data(withJSONObject: plugins)
        return try XCTUnwrap(String(data: pluginsData, encoding: .utf8))
    }

    // MARK: - parseExperience

    func test_parseExperience_validResponse_returnsPageModelAndParseWindow() throws {
        let response = makeExperienceResponse(pluginsJSON: try pluginsFromEmbeddedFixture())

        let result = try XCTUnwrap(RoktUX.parseExperience(response))

        XCTAssertEqual(result.sessionId, "test-session-id")
        XCTAssertEqual(result.pageId, "test-page-id")
        let pageModel = try XCTUnwrap(result.pageModel)
        XCTAssertEqual(pageModel.sessionId, "test-session-id")
        XCTAssertEqual(pageModel.pageInstanceGuid, "test-page-instance-guid")
        XCTAssertEqual(pageModel.layoutPlugins?.count, 1)
        XCTAssertGreaterThanOrEqual(result.parseEnd, result.parseStart)
    }

    func test_parseExperience_noPlugins_returnsSessionIdWithoutPageModel() throws {
        let response = makeExperienceResponse(pluginsJSON: "[]")

        let result = try XCTUnwrap(RoktUX.parseExperience(response))

        XCTAssertEqual(result.sessionId, "test-session-id")
        XCTAssertEqual(result.pageId, "test-page-id")
        XCTAssertNil(result.pageModel)
        XCTAssertGreaterThanOrEqual(result.parseEnd, result.parseStart)
    }

    func test_parseExperience_missingPage_returnsNilPageId() throws {
        let response = makeExperienceResponse(pageId: nil, pluginsJSON: "[]")

        let result = try XCTUnwrap(RoktUX.parseExperience(response))

        XCTAssertNil(result.pageId)
        XCTAssertNil(result.pageModel)
    }

    func test_parseExperience_invalidJSON_returnsNil() {
        XCTAssertNil(RoktUX.parseExperience(#"{"sessionId":}"#))
    }

    func test_parseExperience_unexpectedShape_returnsNil() {
        XCTAssertNil(RoktUX.parseExperience(#"{"unrelated": true}"#))
    }

    // MARK: - loadLayout(pageModel:)

    func test_loadLayout_withPreParsedPageModel_rendersWithoutReDecoding() throws {
        let response = makeExperienceResponse(pluginsJSON: try pluginsFromEmbeddedFixture())
        let pageModel = try XCTUnwrap(RoktUX.parseExperience(response)?.pageModel)
        let sut = RoktUX()
        let layoutLoader = MockLayoutLoader()

        // The pre-parsed overload renders straight from the page model — the embedded
        // layout reaching the loader proves the whole pipeline ran without re-decoding.
        let loaderInvoked = expectation(description: "layout loader invoked")
        layoutLoader.onLoad = { loaderInvoked.fulfill() }

        sut.loadLayout(
            pageModel: pageModel,
            defaultLayoutLoader: layoutLoader,
            onEmbeddedSizeChange: { _, _ in },
            onRoktUXEvent: { _ in },
            onRoktPlatformEvent: { _ in },
            onPluginViewStateChange: { _ in }
        )

        // Generous timeout: the first layout render on a cold simulator can be slow.
        wait(for: [loaderInvoked], timeout: 30)
    }
}

private final class MockLayoutLoader: LayoutLoader {
    var onLoad: (() -> Void)?

    func load<Content: View>(
        onSizeChanged: @escaping ((CGFloat) -> Void),
        @ViewBuilder injectedView: @escaping () -> Content
    ) {
        onLoad?()
    }

    func updateEmbeddedSize(_ size: CGFloat) {}

    func closeEmbedded() {}
}
