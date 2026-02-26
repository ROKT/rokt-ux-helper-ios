//
//  CatalogDevicePayButtonComponent.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/
//

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

    @State var styleState: StyleState = .default

    var style: CatalogDevicePayButtonStyles? {
        switch styleState {
        case .hovered:
            return model.hoveredStyle?.count ?? -1 > breakpointIndex ? model.hoveredStyle?[breakpointIndex] : nil
        case .pressed:
            return model.pressedStyle?.count ?? -1 > breakpointIndex ? model.pressedStyle?[breakpointIndex] : nil
        case .disabled:
            return model.disabledStyle?.count ?? -1 > breakpointIndex ? model.disabledStyle?[breakpointIndex] : nil
        default:
            return model.defaultStyle?.count ?? -1 > breakpointIndex ? model.defaultStyle?[breakpointIndex] : nil
        }
    }

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex = 0
    @State var frameChangeIndex: Int = 0

    var containerStyle: ContainerStylingProperties? { style?.container }
    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    var borderStyle: BorderStylingProperties? { style?.border }
    var spacingStyle: SpacingStylingProperties? { style?.spacing }
    var backgroundStyle: BackgroundStylingProperties? { style?.background }

    let parentOverride: ComponentParentOverride?

    var passableBackgroundStyle: BackgroundStylingProperties? {
        backgroundStyle ?? parentOverride?.parentBackgroundStyle
    }

    var verticalAlignmentOverride: VerticalAlignment? {
        return containerStyle?.justifyContent?.asVerticalAlignment.vertical
    }
    var horizontalAlignmentOverride: HorizontalAlignment? {
        return containerStyle?.alignItems?.asHorizontalAlignment.horizontal
    }

    var verticalAlignment: VerticalAlignmentProperty {
        if let justifyContent = containerStyle?.alignItems?.asVerticalAlignmentProperty {
            return justifyContent
        } else if let parentAlign = parentOverride?.parentVerticalAlignment?.asVerticalAlignmentProperty {
            return parentAlign
        } else {
            return .top
        }
    }

    var horizontalAlignment: HorizontalAlignmentProperty {
        if let alignItems = containerStyle?.justifyContent?.asHorizontalAlignmentProperty {
            return alignItems
        } else if let parentAlign = parentOverride?.parentHorizontalAlignment?.asHorizontalAlignmentProperty {
            return parentAlign
        } else {
            return .start
        }
    }

    var body: some View {
        Group {
            build()
        }
            .applyLayoutModifier(
                verticalAlignmentProperty: verticalAlignment,
                horizontalAlignmentProperty: horizontalAlignment,
                spacing: spacingStyle,
                dimension: dimensionStyle,
                flex: flexStyle,
                border: borderStyle,
                background: backgroundStyle,
                container: containerStyle,
                parent: config.parent,
                parentWidth: $parentWidth,
                parentHeight: $parentHeight,
                parentOverride: parentOverride?.updateBackground(passableBackgroundStyle),
                verticalAlignmentOverride: verticalAlignmentOverride,
                horizontalAlignmentOverride: horizontalAlignmentOverride,
                defaultHeight: .wrapContent,
                defaultWidth: .wrapContent,
                isContainer: true,
                containerType: .row,
                applyAlignSelf: false,
                applyMargin: false,
                frameChangeIndex: $frameChangeIndex,
                imageLoader: model.imageLoader
            )
            // contentShape extends tappable area outside of children
            .contentShape(Rectangle())
            // alignSelf must apply after the touchable area and before margin
            .alignSelf(alignSelf: flexStyle?.alignSelf,
                       parent: config.parent,
                       parentHeight: parentHeight,
                       parentWidth: parentWidth,
                       parentVerticalAlignment: parentOverride?.parentVerticalAlignment,
                       parentHorizontalAlignment: parentOverride?.parentHorizontalAlignment,
                       applyAlignSelf: true)
            // margin must apply after the touchable area and before readSize
            .margin(spacing: spacingStyle, applyMargin: true)
    }

    @ViewBuilder
    func build() -> some View {
        if #available(iOS 16.0, *) {
            // For now use .buy. Will add custom mapping from DCUI property later
            PayWithApplePayButton(.buy, action: {
                handleButtonTapped()
            })
            .payWithApplePayButtonStyle(colorScheme == .dark ? .white : .black)
            .onChange(of: globalScreenSize.width) { newSize in
                DispatchQueue.main.async {
                    breakpointIndex = model.updateBreakpointIndex(for: newSize)
                    frameChangeIndex += 1
                }
            }
        } else {
            LegacyApplePayButton(colorScheme: colorScheme, action: {
                handleButtonTapped()
            })
            .id(colorScheme)
            .onChange(of: globalScreenSize.width) { newSize in
                DispatchQueue.main.async {
                    breakpointIndex = model.updateBreakpointIndex(for: newSize)
                    frameChangeIndex += 1
                }
            }
        }
    }

    private func handleButtonTapped() {
        model.handleTap()
    }

}

@available(iOS 15.0, *)
struct LegacyApplePayButton: UIViewRepresentable {
    var colorScheme: ColorScheme
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        // For now use .buy. Will add custom mapping from DCUI property later
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
