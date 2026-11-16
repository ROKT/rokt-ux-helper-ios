import SwiftUI
import Combine
import DcuiSchema

@available(iOS 15, *)
struct AsyncImageView: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    let imageUrl: ThemeUrl?
    let scale: ImageRenderScale?
    var alt: String?
    var imageLoader: RoktUXImageLoader?

    private var altString: String {
        alt ?? ""
    }

    private var imgURL: String {
        switch colorScheme {
        case .dark:
            imageUrl?.dark ?? ""
        default:
            imageUrl?.light ?? ""
        }
    }

    private var trimmedURL: String {
        imgURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // True when the trimmed URL begins with a `data:` scheme prefix (case-insensitive).
    // Any `data:` URI that does not match a valid `data:image/<subtype>;base64,` URI or an
    // in-limit non-base64 `data:image/<subtype>,` URI (when a host `imageLoader` is configured)
    // is rejected rather than forwarded to remote image loaders.
    var isDataURI: Bool {
        trimmedURL.range(of: "data:", options: [.anchored, .caseInsensitive]) != nil
    }

    // True when the trimmed URL is a non-base64 `data:image/<subtype>[,;...],<payload>` URI
    // with a non-empty subtype and a non-empty payload within `Base64Image.maxBase64PayloadBytes`.
    var isInLimitNonBase64ImageDataURI: Bool {
        guard let dataImagePrefix = trimmedURL.range(of: "data:image/",
                                                     options: [.anchored, .caseInsensitive]),
              let commaRange = trimmedURL.range(of: ",",
                                                range: dataImagePrefix.upperBound..<trimmedURL.endIndex)
        else { return false }

        let header = trimmedURL[dataImagePrefix.upperBound..<commaRange.lowerBound]
        let subtype = header.prefix { $0 != ";" }
        guard !subtype.isEmpty,
              header.range(of: ";base64", options: .caseInsensitive) == nil
        else { return false }

        let payload = trimmedURL[commaRange.upperBound...]
        return !payload.isEmpty && payload.utf8.count <= Base64Image.maxBase64PayloadBytes
    }

    // the payload of a data:image/<subtype>;base64,<payload> URI, or nil when the
    // string is not one. The prefix must appear at the start of the trimmed URL
    // and the suffix is searched for after the prefix, so the two markers cannot
    // pair up out of order or match inside a remote URL.
    private var base64Payload: String? {
        guard let dataImagePrefix = trimmedURL.range(of: "data:image/",
                                                     options: [.anchored, .caseInsensitive]),
              let base64Suffix = trimmedURL.range(of: ";base64,",
                                                  options: .caseInsensitive,
                                                  range: dataImagePrefix.upperBound..<trimmedURL.endIndex),
              dataImagePrefix.upperBound < base64Suffix.lowerBound,
              !trimmedURL[dataImagePrefix.upperBound..<base64Suffix.lowerBound].contains(",")
        else { return nil }

        return String(trimmedURL[base64Suffix.upperBound...])
    }

    var stringBase64: String {
        base64Payload ?? imgURL
    }

    var isURLBase64Image: Bool {
        base64Payload != nil
    }

    var decodedBase64Image: UIImage? {
        guard let payload = base64Payload else { return nil }
        return Base64Image.decode(base64String: payload)
    }

    @Binding var isImageValid: Bool

    var body: some View {
        if imageUrl != nil {
            if let payload = base64Payload {
                switch Base64Image.decodeResult(base64String: payload) {
                case .decoded(let base64Image):
                    Base64Image(scale: scale,
                                altString: altString,
                                base64Image: base64Image)
                case .unsupportedFormat:
                    if let imageLoader {
                        ExternalAsyncImage(urlString: imgURL,
                                           scale: scale,
                                           altString: altString,
                                           loader: imageLoader)
                    } else {
                        let _ = setImageAsInvalid() // swiftlint:disable:this redundant_discardable_let
                        EmptyView()
                    }
                case .rejected:
                    let _ = setImageAsInvalid() // swiftlint:disable:this redundant_discardable_let
                    EmptyView()
                }
            } else if isInLimitNonBase64ImageDataURI {
                if let imageLoader {
                    ExternalAsyncImage(urlString: imgURL,
                                       scale: scale,
                                       altString: altString,
                                       loader: imageLoader)
                } else {
                    let _ = setImageAsInvalid() // swiftlint:disable:this redundant_discardable_let
                    EmptyView()
                }
            } else if isDataURI {
                let _ = setImageAsInvalid() // swiftlint:disable:this redundant_discardable_let
                EmptyView()
            } else if let imageLoader {
                ExternalAsyncImage(urlString: imgURL,
                                   scale: scale,
                                   altString: altString,
                                   loader: imageLoader)
            } else {
                AsyncImage(url: URL(string: imgURL)) { phase in
                    if let image = phase.image { // valid
                        image.scaleIfNeeded(scale: scale)
                    } else if phase.error != nil { // error
                        let _ = setImageAsInvalid() // swiftlint:disable:this redundant_discardable_let
                        EmptyView()
                    } else { // placeholder
                        EmptyView()
                    }
                }
                .accessibilityLabel(altString)
                .accessibilityHidden(altString.isEmpty)
            }
        } else {
            EmptyView()
        }
    }

    func setImageAsInvalid() {
        DispatchQueue.main.async {
            isImageValid = false
        }
    }
}
