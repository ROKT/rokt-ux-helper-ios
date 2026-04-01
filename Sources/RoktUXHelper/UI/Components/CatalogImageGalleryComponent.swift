import SwiftUI
import DcuiSchema

@available(iOS 15, *)
struct CatalogImageGalleryComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @ObservedObject var model: CatalogImageGalleryViewModel
    @State var breakpointIndex: Int = 0
    @State var frameChangeIndex: Int = 0

    let config: ComponentConfig

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?

    let parentOverride: ComponentParentOverride?

    var body: some View {
        VStack(spacing: 0) {
            mainImageArea
            if model.showIndicators {
                indicatorDots
            }
        }
        .onChange(of: globalScreenSize.width) { newSize in
            DispatchQueue.main.async {
                breakpointIndex = model.updateBreakpointIndex(for: newSize)
                frameChangeIndex += 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.a11yLabel ?? "")
    }

    // MARK: - Main Image Area

    private var mainImageArea: some View {
        ZStack {
            if let image = model.selectedImage {
                LayoutSchemaComponent(
                    config: config.updateParent(.row),
                    layout: .dataImage(image),
                    parentWidth: $parentWidth,
                    parentHeight: $parentHeight,
                    styleState: .constant(.default),
                    parentOverride: parentOverride
                )
            }

            HStack {
                if model.canGoBackward {
                    navButton(
                        themedImage: model.backwardImage,
                        fallbackIcon: "◀"
                    ) {
                        model.goBackward()
                    }
                }
                Spacer()
                if model.canGoForward {
                    navButton(
                        themedImage: model.forwardImage,
                        fallbackIcon: "▶"
                    ) {
                        model.goForward()
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .clipped()
    }

    @ViewBuilder
    private func navButton(
        themedImage: CatalogImageGalleryThemedImageUrl?,
        fallbackIcon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            if let themedImage {
                themedImageView(themedImage)
                    .frame(width: 32, height: 32)
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
            } else {
                Text(fallbackIcon)
                    .font(.title2)
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func themedImageView(_ themedImage: CatalogImageGalleryThemedImageUrl) -> some View {
        let urlString = colorScheme == .dark ? themedImage.dark : themedImage.light
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                default:
                    Color.clear
                }
            }
        } else {
            Color.clear
        }
    }

    // MARK: - Indicator Dots

    private var indicatorDots: some View {
        HStack(spacing: 6) {
            ForEach(model.images.indices, id: \.self) { index in
                Circle()
                    .fill(index == model.selectedIndex ? Color.primary : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .onTapGesture { model.selectImage(at: index) }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Aspect Ratio Modifier
