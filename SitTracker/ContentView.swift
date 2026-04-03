import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(TimerManager.self) private var timerManager
    @Query private var allSessions: [Session]
    @State private var showingManualEntry = false

    private var todayCompleted: [Session] {
        allSessions.sessions(on: Date()).filter { $0.stopTime != nil }
    }

    var body: some View {
        @Bindable var manager = timerManager

        NavigationStack {
            List(SittingType.allCases) { type in
                SessionTimerRow(
                    type: type,
                    dailyMinutes: todayCompleted.totalMinutes(for: type),
                    isActive: timerManager.activeSession?.type == type,
                    elapsedSeconds: timerManager.activeSession?.type == type ? timerManager.elapsedSeconds : 0
                ) {
                    if timerManager.activeSession?.type == type {
                        timerManager.stopTimer()
                    } else {
                        timerManager.startTimer(for: type)
                    }
                }
            }
            .navigationTitle("Sit Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Session") { showingManualEntry = true }
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualSessionSheet()
                .environment(timerManager)
        }
        .sheet(item: $manager.sessionToSave) { session in
            StopSessionSheet(session: session)
                .environment(timerManager)
        }
        .alert("Could not save data", isPresented: Binding(
            get: { manager.persistenceError != nil },
            set: { if !$0 { manager.persistenceError = nil } }
        )) {
            Button("OK") { manager.persistenceError = nil }
        } message: {
            Text(manager.persistenceError?.localizedDescription ?? "")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Session.self, configurations: config)
    let manager = TimerManager(modelContext: ModelContext(container))
    return ContentView()
        .modelContainer(container)
        .environment(manager)
}
