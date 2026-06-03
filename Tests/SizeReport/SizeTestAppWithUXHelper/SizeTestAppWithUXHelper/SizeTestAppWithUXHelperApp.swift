import SwiftUI
import RoktUXHelper

@main
struct SizeTestAppWithUXHelperApp: App {
    init() {
        // Reference the RoktUXHelper entry point so the library is linked into the
        // app binary. This mirrors a minimal partner integration.
        RoktUX.setLogLevel(.none)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
