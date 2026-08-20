import XCTest
import SwiftUI
@testable import RoktUXHelper

@available(iOS 15, *)
final class RoktUXParseExperienceTests: XCTestCase {

    // MARK: - Fixtures

    /// Builds a v2 selection-response (snake_case) embedding the given plugins JSON.
    private func makeExperienceResponse(
        sessionId: String = "test-session-id",
        pageId: String? = "test-page-id",
        pluginsJSON: String = "[]"
    ) -> String {
        let pageIdField = pageId.map { #""page_id": "\#($0)","# } ?? ""
        return """
        {
          "session_id": "\(sessionId)",
          "session_token": { "token": "session-token", "expires_at": 0 },
          "page_instance_guid": "test-page-instance-guid",
          "page_context": {
            \(pageIdField)
            "page_instance_guid": "test-page-instance-guid",
            "token": "context-token"
          },
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

        // The decoded response is exposed for session-token / real-time-event handling.
        XCTAssertEqual(result.response.sessionId, "test-session-id")
        XCTAssertEqual(result.response.sessionToken.token, "session-token")
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

    // MARK: - loadLayout failure reasons

    func test_loadLayout_emptyPlugins_emitsNoOffersFailureWithSessionId() {
        let sessionId = "empty-plugins-session"
        let response = makeExperienceResponse(sessionId: sessionId, pluginsJSON: "[]")
        let sut = RoktUX()
        let failureExpectation = expectation(description: "LayoutFailure.noOffers")

        sut.loadLayout(
            experienceResponse: response,
            onLoad: {},
            onUnload: {},
            onEmbeddedSizeChange: { _, _ in },
            onRoktUXEvent: { event in
                guard let failure = event as? RoktUXEvent.LayoutFailure else { return }
                XCTAssertEqual(failure.reason, .noOffers)
                XCTAssertEqual(failure.sessionId, sessionId)
                XCTAssertNil(failure.layoutId)
                failureExpectation.fulfill()
            },
            onRoktPlatformEvent: { _ in },
            onPluginViewStateChange: { _ in }
        )

        wait(for: [failureExpectation], timeout: 5)
        XCTAssertEqual(sut.sessionId, sessionId)
    }

    func test_loadLayout_invalidJSON_emitsInvalidResponseFailure() {
        let sut = RoktUX()
        let failureExpectation = expectation(description: "LayoutFailure.invalidResponse")

        sut.loadLayout(
            experienceResponse: #"{"sessionId":}"#,
            onLoad: {},
            onUnload: {},
            onEmbeddedSizeChange: { _, _ in },
            onRoktUXEvent: { event in
                guard let failure = event as? RoktUXEvent.LayoutFailure else { return }
                XCTAssertEqual(failure.reason, .invalidResponse)
                XCTAssertNil(failure.layoutId)
                failureExpectation.fulfill()
            },
            onRoktPlatformEvent: { _ in },
            onPluginViewStateChange: { _ in }
        )

        wait(for: [failureExpectation], timeout: 5)
    }

    func test_loadLayout_s2s_emptyPlugins_emitsNoOffersFailure() {
        let sessionId = "s2s-empty-plugins-session"
        // Both overloads decode SelectResponse; this covers the S2S entry point.
        let response = makeExperienceResponse(sessionId: sessionId, pluginsJSON: "[]")
        let sut = RoktUX()
        let failureExpectation = expectation(description: "S2S LayoutFailure.noOffers")

        sut.loadLayout(
            experienceResponse: response,
            onRoktUXEvent: { event in
                guard let failure = event as? RoktUXEvent.LayoutFailure else { return }
                XCTAssertEqual(failure.reason, .noOffers)
                XCTAssertEqual(failure.sessionId, sessionId)
                failureExpectation.fulfill()
            },
            onRoktPlatformEvent: { _ in },
            onEmbeddedSizeChange: { _, _ in }
        )

        wait(for: [failureExpectation], timeout: 5)
        XCTAssertEqual(sut.sessionId, sessionId)
    }

    func test_loadLayout_s2s_invalidJSON_emitsInvalidResponseFailure() {
        let sut = RoktUX()
        let failureExpectation = expectation(description: "S2S LayoutFailure.invalidResponse")

        sut.loadLayout(
            experienceResponse: #"{"sessionId":}"#,
            onRoktUXEvent: { event in
                guard let failure = event as? RoktUXEvent.LayoutFailure else { return }
                XCTAssertEqual(failure.reason, .invalidResponse)
                failureExpectation.fulfill()
            },
            onRoktPlatformEvent: { _ in },
            onEmbeddedSizeChange: { _, _ in }
        )

        wait(for: [failureExpectation], timeout: 5)
    }

    func test_loadLayout_pageModel_emptyPlugins_emitsNoOffersFailure() {
        let sessionId = "page-model-empty-plugins"
        let pageModel = RoktUXPageModel(
            pageId: "page-id",
            sessionId: sessionId,
            pageInstanceGuid: "page-instance-guid",
            layoutPlugins: [],
            token: "token",
            options: nil
        )
        let sut = RoktUX()
        let failureExpectation = expectation(description: "pageModel LayoutFailure.noOffers")

        sut.loadLayout(
            pageModel: pageModel,
            onEmbeddedSizeChange: { _, _ in },
            onRoktUXEvent: { event in
                guard let failure = event as? RoktUXEvent.LayoutFailure else { return }
                XCTAssertEqual(failure.reason, .noOffers)
                XCTAssertEqual(failure.sessionId, sessionId)
                failureExpectation.fulfill()
            },
            onRoktPlatformEvent: { _ in },
            onPluginViewStateChange: { _ in }
        )

        wait(for: [failureExpectation], timeout: 5)
        XCTAssertEqual(sut.sessionId, sessionId)
    }

    func test_loadLayout_missingEmbeddedLoader_emitsMissingEmbeddedTarget() throws {
        let response = makeExperienceResponse(pluginsJSON: try pluginsFromEmbeddedFixture())
        let sut = RoktUX()
        let failureExpectation = expectation(description: "LayoutFailure.missingEmbeddedTarget")

        // No LayoutLoader provided for the embedded target → integration failure.
        sut.loadLayout(
            experienceResponse: response,
            onLoad: {},
            onUnload: {},
            onEmbeddedSizeChange: { _, _ in },
            onRoktUXEvent: { event in
                guard let failure = event as? RoktUXEvent.LayoutFailure else { return }
                XCTAssertEqual(failure.reason, .missingEmbeddedTarget)
                XCTAssertEqual(failure.sessionId, "test-session-id")
                XCTAssertNotNil(failure.layoutId)
                failureExpectation.fulfill()
            },
            onRoktPlatformEvent: { _ in },
            onPluginViewStateChange: { _ in }
        )

        wait(for: [failureExpectation], timeout: 30)
    }

    func test_loadLayout_invalidColor_emitsInvalidSchemaFailure() throws {
        let plugins = try pluginsFromEmbeddedFixture()
            .replacingOccurrences(of: "#ECEEE9", with: "not-a-valid-color")
        let response = makeExperienceResponse(sessionId: "invalid-color-session", pluginsJSON: plugins)
        let sut = RoktUX()
        let failureExpectation = expectation(description: "LayoutFailure.invalidSchema")

        sut.loadLayout(
            experienceResponse: response,
            defaultLayoutLoader: MockLayoutLoader(),
            onLoad: {},
            onUnload: {},
            onEmbeddedSizeChange: { _, _ in },
            onRoktUXEvent: { event in
                guard let failure = event as? RoktUXEvent.LayoutFailure else { return }
                XCTAssertEqual(failure.reason, .invalidSchema)
                XCTAssertEqual(failure.sessionId, "invalid-color-session")
                XCTAssertNotNil(failure.layoutId)
                failureExpectation.fulfill()
            },
            onRoktPlatformEvent: { _ in },
            onPluginViewStateChange: { _ in }
        )

        wait(for: [failureExpectation], timeout: 30)
    }

    func test_loadLayout_overlayWithoutPresenter_emitsPresentationFailed() {
        // page_model.json is an S2S overlay experience. Without a presentable view
        // controller, showOverlay should emit presentationFailed.
        let response = ModelTestData.PageModelData.getJsonString(jsonFilename: "page_model")
        let sut = RoktUX()
        let failureExpectation = expectation(description: "LayoutFailure.presentationFailed")

        sut.loadLayout(
            experienceResponse: response,
            onRoktUXEvent: { event in
                guard let failure = event as? RoktUXEvent.LayoutFailure else { return }
                XCTAssertEqual(failure.reason, .presentationFailed)
                failureExpectation.fulfill()
            },
            onRoktPlatformEvent: { _ in },
            onEmbeddedSizeChange: { _, _ in }
        )

        wait(for: [failureExpectation], timeout: 30)
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
