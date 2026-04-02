import SwiftUI
import SwiftData

@main
struct SitTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Session.self)
    }
}

/// Bridges the SwiftData ModelContext into TimerManager and injects it into the environment.
private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var timerManager: TimerManager?

    var body: some View {
        Group {
            if let manager = timerManager {
                ContentView()
                    .environment(manager)
            }
        }
        .onAppear {
            guard timerManager == nil else { return }
            timerManager = TimerManager(modelContext: modelContext)
        }
    }
}
