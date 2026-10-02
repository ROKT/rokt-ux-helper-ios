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

    // the payload of a data:content/type;base64,<payload> URI, or nil when the
    // string is not one. The suffix is searched for after the prefix, so the two
    // markers cannot pair up out of order.
    private var base64Payload: String? {
        guard let dataImagePrefix = imgURL.range(of: "data:image/"),
              let base64Suffix = imgURL.range(of: ";base64,",
                                              range: dataImagePrefix.upperBound..<imgURL.endIndex)
        else { return nil }

        let uriScheme = imgURL[dataImagePrefix.lowerBound..<base64Suffix.upperBound]

        return imgURL.replacingOccurrences(of: uriScheme, with: "")
    }

    var stringBase64: String {
        base64Payload ?? imgURL
    }

    var isURLBase64Image: Bool {
        base64Payload != nil
    }

    @Binding var isImageValid: Bool

    var body: some View {
        if imageUrl != nil {
            if isURLBase64Image,
               let base64Data = Data(base64Encoded: stringBase64),
               let base64Image = UIImage(data: base64Data) {
                Base64Image(scale: scale,
                            altString: altString,
                            base64Image: base64Image)
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
