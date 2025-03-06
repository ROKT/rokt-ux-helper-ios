//
//  CountdownTimerComponent.swift
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
struct CountdownTimerComponent: ExtensionComponent {
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    typealias Model = CountdownTimerModel
    
    let config: ComponentConfig
    let model: CountdownTimerModel
    let data: ExtensionData
    weak var layoutState: (any LayoutStateRepresenting)?
    weak var eventService: EventDiagnosticServicing?
    let slot: SlotOfferModel?
    
    var currentIndex: Binding<Int> = .constant(0)

    @State private var timeLeft: Int
    @State private var timer: Timer?

    static func create(from data: ExtensionData, config: ComponentConfig, layoutState: (any LayoutStateRepresenting)?, eventService: EventDiagnosticServicing?, slot: SlotOfferModel?) -> CountdownTimerComponent? {
        guard let modelData = try? JSONDecoder().decode(CountdownTimerModel.self, from: data.body.data(using: .utf8) ?? Data()) else {
            // TODO: error reporting
            return nil
        }
        return CountdownTimerComponent(
            config: config,
            model: modelData,
            data: data,
            layoutState: layoutState,
            eventService: eventService,
            slot: slot
        )
    }
    
    init(
        config: ComponentConfig,
        model: CountdownTimerModel,
        data: ExtensionData,
        layoutState: (any LayoutStateRepresenting)?,
        eventService: EventDiagnosticServicing?,
        slot: SlotOfferModel?
    ) {
        self.config = config
        self.model = model
        self.data = data
        self.layoutState = layoutState
        self.eventService = eventService
        self.slot = slot
        self._timeLeft = State(initialValue: model.duration)
        self.currentIndex = layoutState?.items[LayoutState.currentProgressKey] as? Binding<Int> ?? .constant(0)
    }
    
    var body: some View {
        TimerText(
            secondsLeft: timeLeft,
            backgroundColor: Color(hex: model.backgroundColor),
            textColor: Color(hex: model.textColor),
            textSize: CGFloat(model.textSize)
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: currentIndex.wrappedValue) { _ in
            resetTimer()
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                resetTimer()
                layoutState?.actionCollection[.nextOffer](nil)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        timeLeft = model.duration
    }
}

@available(iOS 15, *)
private struct TimerText: View {
    let secondsLeft: Int
    let backgroundColor: Color
    let textColor: Color
    let textSize: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "stopwatch") 
                .foregroundColor(backgroundColor)
                .padding(4)
            
            Text(String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60))
                .font(.system(size: textSize))
                .foregroundColor(textColor)
                .padding(4)
        }
        .background(Color(hex: "#f2f4f7"))
        .cornerRadius(30)
        .padding(2)
    }
}
