import SwiftUI
import DcuiSchema

// MARK: - GalleryGestureView

/// UIKit gesture layer that disambiguates horizontal pan from vertical scroll,
/// allowing the gallery swipe to coexist with a parent ScrollView(.vertical).
@available(iOS 15, *)
struct GalleryGestureView: UIViewRepresentable {
    var onTap: (CGPoint) -> Void
    var onPanChanged: ((CGFloat) -> Void)?
    var onPanEnded: ((CGFloat) -> Void)?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        return view
    }

    func updateUIView(_: UIView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onPanChanged = onPanChanged
        context.coordinator.onPanEnded = onPanEnded
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap, onPanChanged: onPanChanged, onPanEnded: onPanEnded)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: (CGPoint) -> Void
        var onPanChanged: ((CGFloat) -> Void)?
        var onPanEnded: ((CGFloat) -> Void)?

        init(
            onTap: @escaping (CGPoint) -> Void,
            onPanChanged: ((CGFloat) -> Void)?,
            onPanEnded: ((CGFloat) -> Void)?
        ) {
            self.onTap = onTap
            self.onPanChanged = onPanChanged
            self.onPanEnded = onPanEnded
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: sender.view)
            onTap(location)
        }

        @objc func handlePan(_ sender: UIPanGestureRecognizer) {
            let translation = sender.translation(in: sender.view).x
            switch sender.state {
            case .changed:
                onPanChanged?(translation)
            case .ended, .cancelled:
                onPanEnded?(translation)
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

// MARK: - CatalogHSPageView

/// Horizontal pager that tracks drag offset for interactive swipe animation.
@available(iOS 15, *)
struct CatalogHSPageView<Content: View>: View {
    @Binding var page: Int
    let pages: Int
    let content: Content
    let onSwipe: ((Bool) -> Void)?
    @State private var dragOffset: CGFloat = 0

    init(
        page: Binding<Int>,
        pages: Int,
        onSwipe: ((Bool) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        _page = page
        self.pages = pages
        self.onSwipe = onSwipe
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            _VariadicView.Tree(
                CatalogHSStackPager(width: geo.size.width, page: page, dragOffset: dragOffset),
                content: { content }
            )
            .animation(.easeOut(duration: 0.25), value: page)
            .animation(.easeOut(duration: 0.25), value: dragOffset)

            GalleryGestureView(
                onTap: { point in
                    let isLeft = point.x < geo.size.width/2
                    if isLeft {
                        page = max(page - 1, 0)
                    } else {
                        page = min(page + 1, pages - 1)
                    }
                },
                onPanChanged: { translation in
                    dragOffset = translation
                },
                onPanEnded: { translation in
                    let threshold = geo.size.width/2
                    var newPage = page
                    var swipeDirection: Bool?

                    if translation < -threshold {
                        newPage += 1
                        swipeDirection = true
                    } else if translation > threshold {
                        newPage -= 1
                        swipeDirection = false
                    }

                    if let direction = swipeDirection {
                        onSwipe?(direction)
                    }

                    dragOffset = 0
                    page = max(min(newPage, pages - 1), 0)
                }
            )
        }
    }

    struct CatalogHSStackPager: _VariadicView_UnaryViewRoot {
        let width: CGFloat
        let page: Int
        let dragOffset: CGFloat

        func body(children: _VariadicView.Children) -> some View {
            HStack(spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    child.frame(width: width)
                }
            }
            .offset(x: -CGFloat(page) * width + dragOffset)
        }
    }
}

// MARK: - CatalogImageGalleryComponent

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

    @State private var page: Int = 0
    @State private var previousPage: Int = 0
    @State private var isUpdatingFromSelectedIndex = false
    @State private var isUpdatingFromSwipe = false
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?

    private var passableBackgroundStyle: BackgroundStylingProperties? {
        parentOverride?.parentBackgroundStyle
    }

    var body: some View {
        VStack(spacing: 0) {
            mainImageArea
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
        let overlayAlignment = indicatorOverlayAlignment(for: breakpointIndex)

        return ZStack {
            imageViewComponent(for: model.images[0]).opacity(0.0)
            CatalogHSPageView(
                page: $page,
                pages: model.images.count,
                onSwipe: { isForward in
                    isUpdatingFromSwipe = true
                    if isForward {
                        model.goForward()
                    } else {
                        model.goBackward()
                    }
                },
                content: {
                    ForEach(0..<model.images.count, id: \.self) { index in
                        imageViewComponent(for: model.images[index])
                    }
                }
            )
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .overlay(alignment: overlayAlignment) {
            indicatorOverlay(alignment: overlayAlignment)
        }
        .readSize(spacing: nil) { size in
            availableWidth = size.width
            availableHeight = size.height
        }
        .onChange(of: page) { newValue in
            previousPage = page
            model.selectedIndex = newValue
            isUpdatingFromSelectedIndex = false
            isUpdatingFromSwipe = false
        }
        .onChange(of: model.selectedIndex) { newIndex in
            guard page != newIndex else { return }
            previousPage = page
            isUpdatingFromSelectedIndex = true
            page = newIndex
        }
    }

    @State private var imageStyleState: StyleState = .default

    private func imageViewComponent(for viewModel: DataImageViewModel) -> some View {
        DataImageViewComponent(
            config: config.updateParent(.column),
            model: viewModel,
            parentWidth: $availableWidth,
            parentHeight: $availableHeight,
            styleState: $imageStyleState,
            parentOverride: ComponentParentOverride(
                parentVerticalAlignment: .center,
                parentHorizontalAlignment: .center,
                parentBackgroundStyle: passableBackgroundStyle,
                stretchChildren: false
            ),
            expandsToContainerOnSelfAlign: false
        )
    }

    // MARK: - Indicator Overlay

    private func indicatorOverlayAlignment(for breakpointIndex: Int) -> Alignment {
        guard let alignSelf = model.indicatorAlignSelf(for: breakpointIndex) else {
            return .bottom
        }
        let vertical = alignSelf.asVerticalAlignment.asVerticalType ?? .bottom
        return Alignment(horizontal: .center, vertical: vertical)
    }

    @ViewBuilder
    private func indicatorOverlay(alignment: Alignment) -> some View {
        if model.showIndicators,
           let containerViewModel = model.indicatorContainerViewModel(for: breakpointIndex) {
            RowComponent(
                config: config,
                model: containerViewModel,
                parentWidth: $availableWidth,
                parentHeight: $availableHeight,
                styleState: .constant(.default),
                parentOverride: ComponentParentOverride(
                    parentVerticalAlignment: alignment.asVerticalType ?? .center,
                    parentHorizontalAlignment: alignment.asHorizontalType ?? .center,
                    parentBackgroundStyle: passableBackgroundStyle,
                    stretchChildren: false
                )
            )
        }
    }
}
