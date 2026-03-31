import SwiftUI
import PassKit
import DcuiSchema

@available(iOS 15, *)
struct CatalogDevicePayButtonComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    let config: ComponentConfig
    let model: CatalogDevicePayButtonViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?

    let parentOverride: ComponentParentOverride?

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex = 0
    @State var frameChangeIndex: Int = 0

    init(
        config: ComponentConfig,
        model: CatalogDevicePayButtonViewModel,
        parentWidth: Binding<CGFloat?>,
        parentHeight: Binding<CGFloat?>,
        parentOverride: ComponentParentOverride?
    ) {
        self.config = config
        self.model = model
        _parentWidth = parentWidth
        _parentHeight = parentHeight
        self.parentOverride = parentOverride
        self.model.position = config.position
    }

    var body: some View {
        buildPayButton()
            .onChange(of: globalScreenSize.width) { newSize in
                DispatchQueue.main.async {
                    breakpointIndex = model.updateBreakpointIndex(for: newSize)
                    frameChangeIndex += 1
                }
            }
    }

    @ViewBuilder
    private func buildPayButton() -> some View {
        switch model.provider {
        case .applePay:
            buildApplePay()
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func buildApplePay() -> some View {
        if #available(iOS 16.0, *) {
            PayWithApplePayButton(.buy, action: {
                model.handleTap()
            })
            .payWithApplePayButtonStyle(colorScheme == .dark ? .white : .black)
        } else {
            LegacyApplePayButton(colorScheme: colorScheme, action: {
                model.handleTap()
            })
            .id(colorScheme)
        }
    }
}

@available(iOS 15.0, *)
private struct LegacyApplePayButton: UIViewRepresentable {
    var colorScheme: ColorScheme
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: colorScheme == .dark ? .white : .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func buttonTapped() {
            action()
        }
    }
}
