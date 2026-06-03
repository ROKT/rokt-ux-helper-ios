import SwiftUI
import RoktUXHelper

struct ContentView: View {
    private let roktUX = RoktUX()

    var body: some View {
        VStack {
            Text("RoktUXHelper Size Test")
                .font(.headline)
            Text("This app integrates RoktUXHelper for size measurement.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .onAppear {
            loadExperience()
        }
    }

    // Exercises the RoktUXHelper rendering entry point so the full layout
    // pipeline is linked into the app — representative of a partner integration.
    // The empty response is handled internally; this app only measures size.
    func loadExperience() {
        roktUX.loadLayout(
            experienceResponse: "",
            onRoktUXEvent: { event in
                print("RoktUX event: \(event)")
            },
            onRoktPlatformEvent: { _ in },
            onEmbeddedSizeChange: { _, _ in }
        )
    }
}

#Preview {
    ContentView()
}
