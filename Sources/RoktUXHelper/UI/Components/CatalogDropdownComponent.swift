import SwiftUI
import DcuiSchema

@available(iOS 15, *)
struct CatalogDropdownComponent: View {
    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex: Int = 0
    @State var frameChangeIndex: Int = 0
    @State var isExpanded: Bool = false
    @State var showValidationError: Bool = false
    @State var buttonFrameInGlobal: CGRect = .zero

    let config: ComponentConfig
    let model: CatalogDropdownViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?

    let parentOverride: ComponentParentOverride?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headView
            if showValidationError {
                errorView
            }
        }
        .background(
            DropdownWindowOverlayPresenter(
                isPresented: $isExpanded,
                content: { expandedOverlayView() }
            )
        )
        .onChange(of: globalScreenSize.width) { newSize in
            DispatchQueue.main.async {
                breakpointIndex = model.updateBreakpointIndex(for: newSize)
                frameChangeIndex += 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.a11yLabel ?? "")
    }

    // MARK: - Head View (trigger)

    private var headView: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            HStack(spacing: 0) {
                Text(model.displayText(for: model.persistedSelectedIndex))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(isExpanded ? "▲" : "▼")
                    .font(.caption)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
        .buttonStyle(.plain)
        .background(
            ViewFrameReader { frame in
                buttonFrameInGlobal = frame
            }
        )
    }

    // MARK: - Expanded Overlay

    @ViewBuilder
    private func expandedOverlayView() -> some View {
        let screenHeight = UIScreen.main.bounds.height
        let spaceBelow = screenHeight - buttonFrameInGlobal.maxY
        let spaceAbove = buttonFrameInGlobal.minY
        let showBelow = spaceBelow >= spaceAbove

        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { isExpanded = false } }

            optionListView
                .frame(width: buttonFrameInGlobal.width)
                .offset(
                    x: buttonFrameInGlobal.minX,
                    y: showBelow
                        ? buttonFrameInGlobal.maxY
                        : max(0, spaceAbove - optionListEstimatedHeight)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private var optionListEstimatedHeight: CGFloat {
        CGFloat(model.options.count) * 44
    }

    // MARK: - Option List

    private var optionListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(model.options.enumerated()), id: \.offset) { index, option in
                    optionRow(index: index, option: option)
                }
            }
        }
        .frame(maxHeight: 300)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
    }

    private func optionRow(index: Int, option: CatalogItemGroupOption) -> some View {
        let isSelected = model.persistedSelectedIndex == index
        let isDisabled = model.isOptionDisabled(at: index)

        return Button {
            model.selectItem(at: index)
            withAnimation { isExpanded = false }
            if model.validatorFieldConfig?.validateOnChange == true {
                showValidationError = model.persistedSelectedIndex == nil
            }
        } label: {
            HStack {
                Text(option.label ?? "")
                    .foregroundColor(isDisabled ? Color.gray : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .background(isSelected ? Color(.systemGray6) : Color.clear)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    // MARK: - Error View

    private var errorView: some View {
        let errorMessage: String = {
            guard let validators = model.validatorFieldConfig?.validators else { return "" }
            for validator in validators {
                switch validator {
                case .required(let req):
                    return req.message
                }
            }
            return ""
        }()

        return Text(errorMessage)
            .foregroundColor(.red)
            .font(.caption)
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - View Frame Reader

private struct ViewFrameReader: UIViewRepresentable {
    let onFrameChange: (CGRect) -> Void

    func makeUIView(context: Context) -> FrameObserverView {
        let view = FrameObserverView()
        view.onFrameChange = onFrameChange
        return view
    }

    func updateUIView(_ uiView: FrameObserverView, context: Context) {}
}

private class FrameObserverView: UIView {
    var onFrameChange: ((CGRect) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let window else { return }
        let globalFrame = convert(bounds, to: window)
        onFrameChange?(globalFrame)
    }
}

// MARK: - Window Overlay Presenter

@available(iOS 15, *)
private struct DropdownWindowOverlayPresenter<OverlayContent: View>: UIViewRepresentable {
    @Binding var isPresented: Bool
    let content: () -> OverlayContent

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if isPresented {
            if context.coordinator.hostingController == nil {
                let hostingController = UIHostingController(rootView: content())
                hostingController.view.backgroundColor = .clear
                context.coordinator.hostingController = hostingController

                if let window = uiView.window {
                    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                    window.addSubview(hostingController.view)
                    NSLayoutConstraint.activate([
                        hostingController.view.topAnchor.constraint(equalTo: window.topAnchor),
                        hostingController.view.bottomAnchor.constraint(equalTo: window.bottomAnchor),
                        hostingController.view.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                        hostingController.view.trailingAnchor.constraint(equalTo: window.trailingAnchor)
                    ])
                    window.bringSubviewToFront(hostingController.view)
                }
            }
        } else {
            context.coordinator.hostingController?.view.removeFromSuperview()
            context.coordinator.hostingController = nil
        }
    }

    class Coordinator {
        var hostingController: UIHostingController<OverlayContent>?
    }
}
