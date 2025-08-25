//
//  View+Extension.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import DcuiSchema

@available(iOS 15, *)
extension View {
    func readSize(spacing: SpacingStylingProperties? = nil, onChange: ((CGSize) -> Void)?) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size.precised())
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { value in
            var newSize = CGSize(width: value.width, height: value.height)

            if let padding = spacing?.padding {
                let paddingFrame = FrameAlignmentProperty.getFrameAlignment(padding)
                newSize.width = newSize.width - paddingFrame.left - paddingFrame.right
                newSize.height = newSize.height - paddingFrame.top - paddingFrame.bottom
            }

            if let margin = spacing?.margin {
                let marginFrame = FrameAlignmentProperty.getFrameAlignment(margin)
                newSize.width = newSize.width - marginFrame.left - marginFrame.right
                newSize.height = newSize.height - marginFrame.top - marginFrame.bottom
            }

            DispatchQueue.main.async {
                onChange?(newSize)
            }
        }
    }

    func readSize(
        weightProperties: WeightModifier.Properties? = nil,
        onChange: ((CGSizeWithMax, Alignment) -> Void)?
    ) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size.precised())
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { value in
            var newSizeWithMax = CGSizeWithMax(size: CGSize(width: value.width, height: value.height))
            var alignment = Alignment.center // SwiftUI default frame alignment

            if let weightProperties {
                let weight = WeightModifier(props: weightProperties)
                newSizeWithMax.maxWidth = weight.frameMaxWidth
                newSizeWithMax.maxHeight = weight.frameMaxHeight
                alignment = weight.alignment
            }

            DispatchQueue.main.async {
                onChange?(newSizeWithMax, alignment)
            }
        }
    }

    // Ensure continuous visibility above threshold for the full time window,
    // cancel when dropping below threshold, and trigger once per offer.
    func onBecomingViewed(
        currentOffer: Int? = nil,
        execute: ((_ visibilityInfo: ComponentVisibilityInfo) -> Void)?
    ) -> some View {
        modifier(BecomingViewedModifier(currentOffer: currentOffer, execute: execute))
    }

    @ViewBuilder func `ifLet`<Content: View, T>(
        _ optional: T?,
        transform: (Self, T) -> Content
    ) -> some View {
        if let optional {
            transform(self, optional)
        } else {
            self
        }
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

@available(iOS 15, *)
struct CGSizeWithMax {
    let size: CGSize
    var maxWidth: CGFloat?
    var maxHeight: CGFloat?
}

class ComponentVisibilityInfo {
    let isVisible: Bool
    let isObscured: Bool
    let incorrectlySized: Bool

    init(isVisible: Bool = false, isObscured: Bool = false, incorrectlySized: Bool = false) {
        self.isVisible = isVisible
        self.isObscured = isObscured
        self.incorrectlySized = incorrectlySized
    }

    var isInViewAndCorrectSize: Bool {
        return isVisible && !isObscured && !incorrectlySized
    }
}

// MARK: - Internal visibility tracking

@available(iOS 15, *)
private struct BecomingViewedModifier: ViewModifier {
    let currentOffer: Int?
    let execute: ((_ visibilityInfo: ComponentVisibilityInfo) -> Void)?

    @State private var visibilityTimer: Timer?
    @State private var lastTriggeredOffer: Int?

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    let intersectPercent = UIScreen.main.bounds.intersectPercent(proxy)
                    Color.clear
                        .onAppear {
                            handleVisibilityChange(intersectPercent: intersectPercent, proxy: proxy)
                        }
                        .onChange(of: intersectPercent) { newValue in
                            handleVisibilityChange(intersectPercent: newValue, proxy: proxy)
                        }
                        .onChange(of: currentOffer) { _ in
                            // Reset once per offer gate and cancel any pending timer when the offer changes
                            cancelTimer()
                            lastTriggeredOffer = nil
                            handleVisibilityChange(intersectPercent: intersectPercent, proxy: proxy)
                        }
                        .onDisappear { cancelTimer() }
                }
            )
    }

    private func handleVisibilityChange(intersectPercent: CGFloat, proxy: GeometryProxy) {
        let aboveThreshold = intersectPercent > 0.5

        if aboveThreshold {
            guard shouldTriggerForCurrentOffer() else { return }

            if visibilityTimer == nil {
                let proxySize = proxy.size
                let proxyFrame = proxy.frame(in: .global)
                visibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    let currentIntersect = UIScreen.main.bounds.intersectPercentWithFrame(proxyFrame)
                    if currentIntersect > 0.5 {
                        let info = ComponentVisibilityInfo(
                            isVisible: true,
                            isObscured: currentIntersect < 1.0,
                            incorrectlySized: proxySize.width <= 0 || proxySize.height <= 0
                        )
                        execute?(info)
                        if info.isInViewAndCorrectSize {
                            lastTriggeredOffer = currentOffer
                        }
                    }
                    cancelTimer()
                }
            }
        } else {
            cancelTimer()
        }
    }

    private func cancelTimer() {
        visibilityTimer?.invalidate()
        visibilityTimer = nil
    }

    // To skip multiple executions for the same offer in OneByOne distribution
    private func shouldTriggerForCurrentOffer() -> Bool {
        guard let offer = currentOffer else { return true }
        return lastTriggeredOffer != offer
    }
}
