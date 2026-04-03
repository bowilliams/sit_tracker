import SwiftUI
import SwiftData

@main
struct SitTrackerApp: App {
    let modelContainer: ModelContainer
    @State private var appSettings = AppSettings()

    init() {
        do {
            // iOS does not guarantee that Library/Application Support exists on first launch.
            // Create it before SwiftData tries to write the store file there.
            let storeURL = Self.storeURL
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let config = ModelConfiguration(url: storeURL)
            modelContainer = try ModelContainer(for: Session.self, configurations: config)
        } catch {
            fatalError("Failed to set up data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
        .environment(appSettings)
    }

    private static var storeURL: URL {
        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else {
            fatalError("Application Support directory unavailable")
        }
        return appSupport.appending(path: "SitTracker/default.store")
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
