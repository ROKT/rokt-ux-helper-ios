import SwiftUI
import Combine
import DcuiSchema

@available(iOS 15.0, *)
struct ExternalAsyncImage: View {
    @ObservedObject var imageDownloader: ImageDownloader
    let scale: ImageRenderScale?
    let altString: String
    @State private var image: UIImage?

    init(urlString: String, scale: ImageRenderScale?, altString: String, loader: RoktUXImageLoader) {
        self.imageDownloader = ImageDownloader(urlString: urlString, loader: loader)
        self.scale = scale
        self.altString = altString
    }

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .scaleIfNeeded(scale: scale)
                .accessibilityLabel(altString)
                .accessibilityHidden(altString.isEmpty)
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
