import XCTest
import SwiftUI
import ViewInspector
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestAsyncImageView: XCTestCase {

    private func sut(_ url: String) -> AsyncImageView {
        AsyncImageView(imageUrl: ThemeUrl(light: url, dark: url),
                       scale: nil,
                       alt: nil,
                       imageLoader: nil,
                       isImageValid: .constant(true))
    }

    // MARK: - Well formed data URIs

    func test_dataURI_stripsTheScheme() {
        let view = sut("data:image/png;base64,iVBORw0KGgo=")

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "iVBORw0KGgo=")
    }

    func test_dataURI_withSubtypeContainingPunctuation_stripsTheScheme() {
        let view = sut("data:image/svg+xml;base64,PHN2Zz48L3N2Zz4=")

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "PHN2Zz48L3N2Zz4=")
    }

    // MARK: - Strings that are not data URIs

    func test_remoteURL_isLeftAlone() {
        let view = sut("https://example.test/logo.png")

        XCTAssertFalse(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "https://example.test/logo.png")
    }

    func test_emptyURL_isLeftAlone() {
        let view = sut("")

        XCTAssertFalse(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "")
    }

    // MARK: - Markers in the wrong order

    func test_suffixBeforePrefix_isLeftAlone() {
        let view = sut("https://example.test/a;base64,b#data:image/png")

        XCTAssertFalse(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "https://example.test/a;base64,b#data:image/png")
    }

    func test_suffixBeforePrefix_rendersAsARemoteImage() throws {
        let view = sut("https://example.test/a;base64,b#data:image/png")

        XCTAssertNoThrow(try view.inspect().asyncImage())
    }

    func test_suffixWithoutItsComma_isLeftAlone() {
        let view = sut("data:image/png;base64")

        XCTAssertFalse(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "data:image/png;base64")
    }
}
