import SwiftUI
import Combine
import DcuiSchema

@available(iOS 15.0, *)
struct ExternalAsyncImage: View {
    @ObservedObject var imageDownloader: ImageDownloader
    let scale: BackgroundImageScale?
    let altString: String
    var decorativeAccessibilityDuplicateOfOfferCopy: Bool = false
    @State private var image: UIImage?

    private var hideFromAccessibility: Bool {
        altString.isEmpty || decorativeAccessibilityDuplicateOfOfferCopy
    }

    init(urlString: String, scale: BackgroundImageScale?, altString: String, loader: RoktUXImageLoader,
         decorativeAccessibilityDuplicateOfOfferCopy: Bool = false) {
        self.imageDownloader = ImageDownloader(urlString: urlString, loader: loader)
        self.scale = scale
        self.altString = altString
        self.decorativeAccessibilityDuplicateOfOfferCopy = decorativeAccessibilityDuplicateOfOfferCopy
    }

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .scaleIfNeeded(scale: scale)
                .accessibilityLabel(altString)
                .accessibilityHidden(hideFromAccessibility)
                .onReceive(imageDownloader.imageSubject) { newImage in
                    self.image = newImage
                }
        } else {
            EmptyView()
                .onReceive(imageDownloader.imageSubject) { newImage in
                    self.image = newImage
                }
        }

    }
}
