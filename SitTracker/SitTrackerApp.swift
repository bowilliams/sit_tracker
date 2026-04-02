import SwiftUI
import SwiftData

@main
struct SitTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Session.self)
    }
}
