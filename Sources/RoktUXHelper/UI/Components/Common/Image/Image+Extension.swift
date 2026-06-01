import SwiftUI

@available(iOS 15.0, *)
extension Image {
    func scaleIfNeeded(scale: ImageRenderScale?) -> some View {
        let imageScale = scale ?? .fit

        switch imageScale {
        case .crop:
            return AnyView(self) // No resizing or scaling
        case .fill:
            return AnyView(self
                .resizable()
                .aspectRatio(contentMode: imageScale.contentMode)
                .clipped())
        case .fit:
            return AnyView(self
                .resizable()
                .aspectRatio(contentMode: imageScale.contentMode))
        }
    }
}
