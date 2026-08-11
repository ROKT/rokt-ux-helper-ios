import XCTest
import SwiftUI
@testable import RoktUXHelper

@available(iOS 15, *)
final class RoktUXEmbeddedSizeTests: XCTestCase {

    // MARK: - Fixtures

    /// Builds a v2 selection response embedding the given plugins JSON.
    private func makeExperienceResponse(pluginsJSON: String) -> String {
        """
        {
          "session_id": "test-session-id",
          "session_token": { "token": "session-token", "expires_at": 0 },
          "page_instance_guid": "test-page-instance-guid",
          "page_context": {
            "page_id": "test-page-id",
            "page_instance_guid": "test-page-instance-guid",
            "token": "context-token"
          },
          "plugins": \(pluginsJSON)
        }
        """
    }

    /// Extracts the plugins array (with a complete layout schema) from the
    /// embedded one-by-one fixture so the selection response renders.
    private func pluginsFromEmbeddedFixture() throws -> String {
        let data = ModelTestData.toData(jsonFilename: "embedded_onebyone")
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let plugins = try XCTUnwrap(json["plugins"])
        let pluginsData = try JSONSerialization.data(withJSONObject: plugins)
        return try XCTUnwrap(String(data: pluginsData, encoding: .utf8))
    }

    /// Renders an embedded layout into a mock loader and returns the loader once
    /// the size-change closure has been handed to it.
    private func loadEmbeddedLayout(
        onEmbeddedSizeChange: @escaping (String, CGFloat) -> Void
    ) throws -> MockLayoutLoader {
        let response = makeExperienceResponse(pluginsJSON: try pluginsFromEmbeddedFixture())
        let pageModel = try XCTUnwrap(RoktUX.parseExperience(response)?.pageModel)
        let layoutLoader = MockLayoutLoader()

        let loaderInvoked = expectation(description: "layout loader invoked")
        layoutLoader.onLoad = { loaderInvoked.fulfill() }

        RoktUX().loadLayout(
            pageModel: pageModel,
            defaultLayoutLoader: layoutLoader,
            onEmbeddedSizeChange: onEmbeddedSizeChange,
            onRoktUXEvent: { _ in },
            onRoktPlatformEvent: { _ in },
            onPluginViewStateChange: { _ in }
        )

        // Generous timeout: the first layout render on a cold simulator can be slow.
        wait(for: [loaderInvoked], timeout: 30)
        return layoutLoader
    }

    // MARK: - Embedded size rounding

    /// The height written to the embedded view's constraint and the height published to
    /// the host must be the same value. A host that constrains the view to the published
    /// height would otherwise conflict with our own constraint by a fraction of a point.
    func test_embeddedSizeChange_publishedHeightMatchesAppliedHeight() throws {
        var publishedHeights: [CGFloat] = []
        let layoutLoader = try loadEmbeddedLayout { _, height in publishedHeights.append(height) }
        let onSizeChanged = try XCTUnwrap(layoutLoader.capturedOnSizeChanged)

        for size in [163.5, 163.01, 99.999, 250, 0] as [CGFloat] {
            onSizeChanged(size)
        }

        XCTAssertEqual(layoutLoader.appliedHeights, publishedHeights)
    }

    /// Fractional heights round up, so the embedded content is never given less room
    /// than it measured.
    func test_embeddedSizeChange_roundsFractionalHeightsUp() throws {
        var publishedHeights: [CGFloat] = []
        let layoutLoader = try loadEmbeddedLayout { _, height in publishedHeights.append(height) }
        let onSizeChanged = try XCTUnwrap(layoutLoader.capturedOnSizeChanged)

        for size in [163.5, 163.01, 99.999, 250, 0] as [CGFloat] {
            onSizeChanged(size)
        }

        XCTAssertEqual(publishedHeights, [164, 164, 100, 250, 0])
    }
}

@available(iOS 15, *)
private final class MockLayoutLoader: LayoutLoader {
    var onLoad: (() -> Void)?
    private(set) var capturedOnSizeChanged: ((CGFloat) -> Void)?
    private(set) var appliedHeights: [CGFloat] = []

    func load<Content: View>(
        onSizeChanged: @escaping ((CGFloat) -> Void),
        @ViewBuilder injectedView: @escaping () -> Content
    ) {
        capturedOnSizeChanged = onSizeChanged
        onLoad?()
    }

    func updateEmbeddedSize(_ size: CGFloat) {
        appliedHeights.append(size)
    }

    func closeEmbedded() {}
}
