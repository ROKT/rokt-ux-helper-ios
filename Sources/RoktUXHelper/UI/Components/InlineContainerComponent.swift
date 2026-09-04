import DcuiSchema
import SwiftUI

struct InlineContainerComponent: View {
    let config: ComponentConfig
    @ObservedObject var model: InlineContainerViewModel
    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    let parentOverride: ComponentParentOverride?
    @EnvironmentObject private var globalScreenSize: GlobalScreenSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.isEnabled) private var isEnabled
    @State private var contentHeight: CGFloat = 0

    private var style: BaseStyles? {
        guard let styles = model.defaultStyle, !styles.isEmpty else { return nil }
        return styles[model.updateBreakpointIndex(for: globalScreenSize.width)]
    }

    private var textAlignment: NSTextAlignment {
        switch style?.container?.justifyContent {
        case .center: return .center
        case .flexEnd: return layoutDirection == .rightToLeft ? .left : .right
        default: return .natural
        }
    }

    var body: some View {
        GeometryReader { geometry in
            InlineTextRepresentable(content: model.textContent(position: config.position,
                                                               colorScheme: colorScheme,
                                                               contentSize: UIContentSizeCategory(sizeCategory),
                                                               layoutDirection: layoutDirection,
                                                               alignment: textAlignment),
                                    accessibilityLabel: model.accessibilityLabel,
                                    width: geometry.size.width,
                                    isEnabled: isEnabled,
                                    height: $contentHeight,
                                    onInteractionStateChange: model.setStyleState)
        }
        .frame(height: contentHeight)
        .applyLayoutModifier(
            verticalAlignmentProperty: .top,
            horizontalAlignmentProperty: .start,
            spacing: style?.spacing,
            dimension: style?.dimension,
            flex: style?.flexChild,
            border: style?.border,
            background: style?.background,
            container: style?.container,
            parent: config.parent,
            parentWidth: $parentWidth,
            parentHeight: $parentHeight,
            parentOverride: parentOverride,
            defaultHeight: .wrapContent,
            defaultWidth: .fitWidth,
            isContainer: true,
            imageLoader: model.layoutState?.imageLoader
        )
        .onAppear { updateTextStyles() }
        .onChange(of: globalScreenSize.width) { _ in updateTextStyles() }
        .onChange(of: isEnabled) { _ in updateTextStyles() }
    }

    private func updateTextStyles() {
        model.updateTextStyles(width: globalScreenSize.width, state: isEnabled ? .default : .disabled)
    }
}

struct InlineTextRepresentable: UIViewRepresentable {
    let content: InlineTextContent
    let accessibilityLabel: String?
    let width: CGFloat
    let isEnabled: Bool
    @Binding var height: CGFloat
    let onInteractionStateChange: (StyleState, UUID) -> Void

    func makeUIView(context: Context) -> InlineTextContainerView { InlineTextContainerView() }

    func updateUIView(_ container: InlineTextContainerView, context: Context) {
        let view = container.textView
        container.accessibilityLabel = accessibilityLabel
        view.onInteractionStateChange = { id, state in onInteractionStateChange(state, id) }
        view.actionsEnabled = isEnabled
        view.setContent(content, accessibilityLabel: accessibilityLabel)
        context.coordinator.publish(view.measuredHeight(for: width), to: $height)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private var pendingHeight: CGFloat?
        private var scheduled = false

        func publish(_ height: CGFloat, to binding: Binding<CGFloat>) {
            pendingHeight = height
            guard !scheduled, binding.wrappedValue != height else { return }
            scheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.scheduled = false
                guard let latest = self.pendingHeight, binding.wrappedValue != latest else { return }
                binding.wrappedValue = latest
            }
        }
    }
}
