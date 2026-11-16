import SwiftUI
import Combine
import DcuiSchema
import ImageIO

@available(iOS 15, *)
struct Base64Image: View {
    enum DecodeResult {
        case decoded(UIImage)
        case unsupportedFormat
        case rejected
    }

    /// Maximum encoded base64 payload size accepted for an inline `data:image/` URI (1 MiB).
    static let maxBase64PayloadBytes = 1_048_576
    /// Maximum width or height in pixels accepted for an inline base64 image.
    static let maxPixelDimension = 4_096
    /// Maximum total pixel area (`width * height`) accepted for an inline base64 image (4 megapixels).
    static let maxTotalPixels = 2_048 * 2_048

    let scale: ImageRenderScale?
    let altString: String
    let base64Image: UIImage

    /// Decodes a base64-encoded image string only when its encoded size and declared pixel
    /// dimensions fall within safe limits, checking `CGImageSource` header properties before
    /// allocating a bitmap.
    static func decode(base64String: String) -> UIImage? {
        if case .decoded(let image) = decodeResult(base64String: base64String) {
            return image
        }
        return nil
    }

    static func decode(data: Data) -> UIImage? {
        if case .decoded(let image) = decodeResult(data: data) {
            return image
        }
        return nil
    }

    /// Classifies a base64-encoded image payload as `.decoded`, `.unsupportedFormat` (valid
    /// in-limit base64 payload whose container type `ImageIO` does not recognise, such as SVG),
    /// or `.rejected` (empty, invalid base64, exceeding `maxBase64PayloadBytes`, corrupt raster
    /// header, or exceeding pixel dimension limits).
    static func decodeResult(base64String: String) -> DecodeResult {
        let trimmedPayload = base64String.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPayload.isEmpty,
              trimmedPayload.utf8.count <= maxBase64PayloadBytes,
              let data = Data(base64Encoded: trimmedPayload),
              !data.isEmpty,
              data.count <= maxBase64PayloadBytes
        else {
            return .rejected
        }

        return decodeResult(data: data)
    }

    static func decodeResult(data: Data) -> DecodeResult {
        guard !data.isEmpty,
              data.count <= maxBase64PayloadBytes
        else {
            return .rejected
        }

        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary),
              CGImageSourceGetType(imageSource) != nil
        else {
            return .unsupportedFormat
        }

        guard CGImageSourceGetCount(imageSource) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(
                  imageSource,
                  0,
                  sourceOptions as CFDictionary
              ) as? [CFString: Any],
              let widthNumber = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let heightNumber = properties[kCGImagePropertyPixelHeight] as? NSNumber
        else {
            return .rejected
        }

        let pixelWidth = widthNumber.intValue
        let pixelHeight = heightNumber.intValue
        guard pixelWidth > 0,
              pixelHeight > 0,
              pixelWidth <= maxPixelDimension,
              pixelHeight <= maxPixelDimension,
              pixelWidth * pixelHeight <= maxTotalPixels
        else {
            return .rejected
        }

        let decodeOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: false
        ]
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, decodeOptions as CFDictionary),
              cgImage.width > 0,
              cgImage.height > 0,
              cgImage.width <= maxPixelDimension,
              cgImage.height <= maxPixelDimension,
              cgImage.width * cgImage.height <= maxTotalPixels
        else {
            return .rejected
        }

        return .decoded(UIImage(cgImage: cgImage, scale: 1.0, orientation: imageOrientation(from: properties)))
    }

    private static func imageOrientation(from properties: [CFString: Any]) -> UIImage.Orientation {
        guard let rawOrientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value,
              let cgOrientation = CGImagePropertyOrientation(rawValue: rawOrientation)
        else {
            return .up
        }

        switch cgOrientation {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
        case .left:
            return .left
        }
    }

    var body: some View {
        Image(uiImage: base64Image)
            .scaleIfNeeded(scale: scale)
            .accessibilityLabel(altString)
            .accessibilityHidden(altString.isEmpty)
    }
}
