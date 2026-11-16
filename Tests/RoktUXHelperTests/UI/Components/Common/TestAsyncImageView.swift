import XCTest
import SwiftUI
import ViewInspector
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestAsyncImageView: XCTestCase {

    private final class SpyImageLoader: RoktUXImageLoader {
        private(set) var requestedURLs: [String] = []

        func loadImage(urlString: String,
                       completion: @escaping (Result<UIImage?, Error>) -> Void) {
            requestedURLs.append(urlString)
        }
    }

    private func sut(_ url: String,
                     imageLoader: RoktUXImageLoader? = nil,
                     isImageValid: Binding<Bool> = .constant(true)) -> AsyncImageView {
        AsyncImageView(imageUrl: ThemeUrl(light: url, dark: url),
                       scale: nil,
                       alt: nil,
                       imageLoader: imageLoader,
                       isImageValid: isImageValid)
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

    func test_dataURI_withSurroundingWhitespace_stripsTheScheme() {
        let view = sut("  \n\tdata:image/png;base64,iVBORw0KGgo=\n  ")

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "iVBORw0KGgo=")
    }

    func test_dataURI_whenPayloadContainsSchemeMarker_preservesPayload() {
        let view = sut("data:image/png;base64,iVBORw0KGgo=data:image/png;base64,")

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "iVBORw0KGgo=data:image/png;base64,")
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

    func test_dataURISubstringInsideRemoteURL_isNotTreatedAsBase64Image() throws {
        let remoteWithEmbeddedDataURI = "https://example.test/track?img=data:image/png;base64,iVBORw0KGgo="
        let view = sut(remoteWithEmbeddedDataURI)

        XCTAssertFalse(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, remoteWithEmbeddedDataURI)
        XCTAssertNil(view.decodedBase64Image)
        XCTAssertNoThrow(try view.inspect().asyncImage())
    }

    func test_dataURIWithEmptySubtype_isRejectedAndDoesNotReachLoaders() {
        let loader = SpyImageLoader()
        let viewWithoutLoader = sut("data:image/;base64,iVBORw0KGgo=")
        let viewWithLoader = sut("data:image/;base64,iVBORw0KGgo=", imageLoader: loader)

        XCTAssertTrue(viewWithoutLoader.isDataURI)
        XCTAssertFalse(viewWithoutLoader.isURLBase64Image)
        XCTAssertEqual(viewWithoutLoader.stringBase64, "data:image/;base64,iVBORw0KGgo=")
        XCTAssertThrowsError(try viewWithoutLoader.inspect().asyncImage())
        XCTAssertThrowsError(try viewWithLoader.inspect().find(ExternalAsyncImage.self))
        XCTAssertTrue(loader.requestedURLs.isEmpty)
    }

    func test_malformedOrNonImageDataURIs_areRejectedAndDoNotReachLoaders() {
        let malformedDataURIs = [
            "data:application/octet-stream;base64,iVBORw0KGgo=",
            "data:image/,rawbytes",
            "data:image/png;base64",
            "data:text/plain,hello",
            "  DATA:text/plain;base64,SGVsbG8= "
        ]

        for uri in malformedDataURIs {
            let loader = SpyImageLoader()
            let viewWithoutLoader = sut(uri)
            let viewWithLoader = sut(uri, imageLoader: loader)

            XCTAssertTrue(viewWithoutLoader.isDataURI, "Expected isDataURI to be true for \(uri)")
            XCTAssertFalse(viewWithoutLoader.isURLBase64Image, "Expected isURLBase64Image to be false for \(uri)")
            XCTAssertFalse(viewWithoutLoader.isInLimitNonBase64ImageDataURI,
                           "Expected isInLimitNonBase64ImageDataURI to be false for \(uri)")
            XCTAssertThrowsError(try viewWithoutLoader.inspect().find(Base64Image.self))
            XCTAssertThrowsError(try viewWithoutLoader.inspect().asyncImage())
            XCTAssertThrowsError(try viewWithLoader.inspect().find(ExternalAsyncImage.self))
            XCTAssertTrue(loader.requestedURLs.isEmpty)
        }
    }

    // MARK: - Markers in the wrong order

    func test_suffixBeforePrefix_isLeftAlone() {
        let view = sut("https://example.test/a;base64,b#data:image/png")

        XCTAssertFalse(view.isDataURI)
        XCTAssertFalse(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "https://example.test/a;base64,b#data:image/png")
    }

    func test_suffixBeforePrefix_rendersAsARemoteImage() throws {
        let view = sut("https://example.test/a;base64,b#data:image/png")

        XCTAssertNoThrow(try view.inspect().asyncImage())
    }

    func test_suffixWithoutItsComma_isLeftAlone() {
        let view = sut("data:image/png;base64")

        XCTAssertTrue(view.isDataURI)
        XCTAssertFalse(view.isURLBase64Image)
        XCTAssertEqual(view.stringBase64, "data:image/png;base64")
        XCTAssertThrowsError(try view.inspect().asyncImage())
    }

    // MARK: - Bounded decoding (payload size and pixel dimensions)

    func test_validSmallPNGDataURI_decodesAndRendersBase64Image() throws {
        let oneByOnePNG = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let view = sut(oneByOnePNG)

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertNotNil(view.decodedBase64Image)
        XCTAssertEqual(view.decodedBase64Image?.size, CGSize(width: 1, height: 1))
        XCTAssertNoThrow(try view.inspect().find(Base64Image.self))
    }

    func test_svgDataURIWithinSizeLimit_withImageLoader_fallsBackToExternalAsyncImage() throws {
        let svgURI = "data:image/svg+xml;base64,PHN2Zz48L3N2Zz4="
        let loader = SpyImageLoader()
        let view = sut(svgURI, imageLoader: loader)

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertNil(view.decodedBase64Image)
        XCTAssertNoThrow(try view.inspect().find(ExternalAsyncImage.self))
        XCTAssertEqual(loader.requestedURLs, [svgURI])
    }

    func test_svgDataURIWithinSizeLimit_withoutImageLoader_isRejectedWithoutAsyncImageFallback() {
        let svgURI = "data:image/svg+xml;base64,PHN2Zz48L3N2Zz4="
        let view = sut(svgURI)

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertNil(view.decodedBase64Image)
        XCTAssertThrowsError(try view.inspect().find(Base64Image.self))
        XCTAssertThrowsError(try view.inspect().find(ExternalAsyncImage.self))
        XCTAssertThrowsError(try view.inspect().asyncImage())
    }

    func test_nonBase64SVGDataURIWithinSizeLimit_withImageLoader_fallsBackToExternalAsyncImage() throws {
        let svgURIs = [
            "data:image/svg+xml,%3Csvg%20xmlns%3D%22http://www.w3.org/2000/svg%22%3E%3C/svg%3E",
            "data:image/svg+xml;utf8,<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>"
        ]

        for svgURI in svgURIs {
            let loader = SpyImageLoader()
            let view = sut(svgURI, imageLoader: loader)

            XCTAssertTrue(view.isDataURI)
            XCTAssertFalse(view.isURLBase64Image)
            XCTAssertTrue(view.isInLimitNonBase64ImageDataURI)
            XCTAssertNoThrow(try view.inspect().find(ExternalAsyncImage.self))
            XCTAssertEqual(loader.requestedURLs, [svgURI])
        }
    }

    func test_nonBase64SVGDataURIWithinSizeLimit_withoutImageLoader_marksInvalidAndIsRejected() {
        let svgURIs = [
            "data:image/svg+xml,%3Csvg%20xmlns%3D%22http://www.w3.org/2000/svg%22%3E%3C/svg%3E",
            "data:image/svg+xml;utf8,<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>"
        ]

        for svgURI in svgURIs {
            var isValid = true
            let binding = Binding(get: { isValid }, set: { isValid = $0 })
            let view = sut(svgURI, isImageValid: binding)

            XCTAssertTrue(view.isDataURI)
            XCTAssertFalse(view.isURLBase64Image)
            XCTAssertTrue(view.isInLimitNonBase64ImageDataURI)
            XCTAssertThrowsError(try view.inspect().find(Base64Image.self))
            XCTAssertThrowsError(try view.inspect().find(ExternalAsyncImage.self))
            XCTAssertThrowsError(try view.inspect().asyncImage())

            let invalidated = expectation(description: "isImageValid updated for \(svgURI)")
            DispatchQueue.main.async {
                invalidated.fulfill()
            }
            wait(for: [invalidated], timeout: 1.0)
            XCTAssertFalse(isValid)
        }
    }

    func test_oversizedOrInvalidNonBase64DataURIs_withImageLoader_areRejected() {
        let oversizedPayload = String(repeating: "a", count: Base64Image.maxBase64PayloadBytes + 1)
        let invalidNonBase64URIs = [
            "data:image/svg+xml," + oversizedPayload,
            "data:image/svg+xml,",
            "data:image/,<svg></svg>",
            "data:image/;utf8,<svg></svg>",
            "data:text/plain,hello"
        ]

        for uri in invalidNonBase64URIs {
            let loader = SpyImageLoader()
            let view = sut(uri, imageLoader: loader)

            XCTAssertTrue(view.isDataURI, "Expected isDataURI to be true for \(uri.prefix(40))")
            XCTAssertFalse(view.isURLBase64Image, "Expected isURLBase64Image to be false for \(uri.prefix(40))")
            XCTAssertFalse(view.isInLimitNonBase64ImageDataURI,
                           "Expected isInLimitNonBase64ImageDataURI to be false for \(uri.prefix(40))")
            XCTAssertThrowsError(try view.inspect().find(Base64Image.self))
            XCTAssertThrowsError(try view.inspect().find(ExternalAsyncImage.self))
            XCTAssertThrowsError(try view.inspect().asyncImage())
            XCTAssertTrue(loader.requestedURLs.isEmpty)
        }
    }

    func test_oversizedSVGDataURI_withImageLoader_isRejectedAndDoesNotFallbackToImageLoader() {
        let oversizedPayload = String(repeating: "A", count: Base64Image.maxBase64PayloadBytes + 4)
        let loader = SpyImageLoader()
        let view = sut("data:image/svg+xml;base64," + oversizedPayload, imageLoader: loader)

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertNil(view.decodedBase64Image)
        XCTAssertThrowsError(try view.inspect().find(Base64Image.self))
        XCTAssertThrowsError(try view.inspect().find(ExternalAsyncImage.self))
        XCTAssertTrue(loader.requestedURLs.isEmpty)
    }

    func test_oversizedBase64Payload_isRejectedAndDoesNotFallbackToRemoteLoader() {
        let oversizedPayload = String(repeating: "A", count: Base64Image.maxBase64PayloadBytes + 4)
        let loader = SpyImageLoader()
        let view = sut("data:image/png;base64," + oversizedPayload)
        let viewWithLoader = sut("data:image/png;base64," + oversizedPayload, imageLoader: loader)

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertNil(view.decodedBase64Image)
        XCTAssertNil(Base64Image.decode(base64String: oversizedPayload))
        XCTAssertThrowsError(try view.inspect().find(Base64Image.self))
        XCTAssertThrowsError(try view.inspect().asyncImage())
        XCTAssertThrowsError(try viewWithLoader.inspect().find(ExternalAsyncImage.self))
        XCTAssertTrue(loader.requestedURLs.isEmpty)
    }

    func test_oversizedDecodedData_isRejected() {
        let oversizedData = Data(count: Base64Image.maxBase64PayloadBytes + 1)

        XCTAssertNil(Base64Image.decode(data: oversizedData))
    }

    func test_declaredHugeDimensionsInSmallPNGPayload_isRejectedBeforeBitmapAllocation() {
        // 68-byte PNG whose IHDR chunk declares 30000x30000 pixels (~3.6 GB if rasterized as RGBA).
        let hugeHeaderPNG = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAdTAAAHUwCAQAAADMLjAxAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let loader = SpyImageLoader()
        let view = sut(hugeHeaderPNG)
        let viewWithLoader = sut(hugeHeaderPNG, imageLoader: loader)

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertNil(view.decodedBase64Image)
        XCTAssertThrowsError(try view.inspect().find(Base64Image.self))
        XCTAssertThrowsError(try view.inspect().asyncImage())
        XCTAssertThrowsError(try viewWithLoader.inspect().find(ExternalAsyncImage.self))
        XCTAssertTrue(loader.requestedURLs.isEmpty)
    }

    func test_imageExceedingMaxPixelDimension_isRejected() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let tooWideImage = UIGraphicsImageRenderer(
            size: CGSize(width: Base64Image.maxPixelDimension + 1, height: 1),
            format: format
        ).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: Base64Image.maxPixelDimension + 1, height: 1))
        }
        let pngData = try XCTUnwrap(tooWideImage.pngData())
        let dataURI = "data:image/png;base64," + pngData.base64EncodedString()
        let view = sut(dataURI)

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertNil(view.decodedBase64Image)
        XCTAssertNil(Base64Image.decode(data: pngData))
    }

    func test_imageExceedingMaxTotalPixels_isRejected() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let side = 2_049 // 2049 <= maxPixelDimension (4096), but 2049 * 2049 = 4,198,401 > maxTotalPixels (4,194,304)
        let tooManyPixelsImage = UIGraphicsImageRenderer(
            size: CGSize(width: side, height: side),
            format: format
        ).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
        let pngData = try XCTUnwrap(tooManyPixelsImage.pngData())
        let dataURI = "data:image/png;base64," + pngData.base64EncodedString()
        let view = sut(dataURI)

        XCTAssertTrue(view.isURLBase64Image)
        XCTAssertNil(view.decodedBase64Image)
        XCTAssertNil(Base64Image.decode(data: pngData))
    }
}
