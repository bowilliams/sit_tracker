import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(TimerManager.self) private var timerManager
    @Environment(AppSettings.self) private var settings
    @Query private var allSessions: [Session]
    @State private var showingManualEntry = false
    @State private var showingSettings = false
    @State private var showingProgress = false

    private var todayCompleted: [Session] {
        allSessions.sessions(on: Date()).filter { $0.stopTime != nil }
    }

    private var todayTotalMinutes: Double { todayCompleted.totalMinutes }

    private var sevenDayAverage: Double { allSessions.rollingAverage() }

    private var chartData: [DayData] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<7).compactMap { daysAgo in
            Calendar.current.date(byAdding: .day, value: -(6 - daysAgo), to: today)
        }.map { day in
            DayData(
                day: day,
                minutes: allSessions.sessions(on: day).filter { $0.stopTime != nil }.totalMinutes
            )
        }
    }

    var body: some View {
        @Bindable var manager = timerManager

        NavigationStack {
            List {
                summarySection
                timerSection
            }
            .navigationTitle("Sit Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Session") { showingManualEntry = true }
                }
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
                    .environment(settings)
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualSessionSheet()
                .environment(timerManager)
        }
        .sheet(isPresented: $showingProgress) {
            HowImDoingView(chartData: chartData, sevenDayAverage: sevenDayAverage)
                .environment(settings)
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

    // MARK: - Sections

    @ViewBuilder
    private var summarySection: some View {
        Section {
            LabeledContent("Today") {
                Text(todayTotalMinutes.formattedAsHoursMinutes)
                    .monospacedDigit()
            }
            if settings.hasQuota {
                let remaining = Double(settings.dailyQuotaMinutes) - todayTotalMinutes
                LabeledContent("Remaining") {
                    Text(remaining >= 0
                         ? remaining.formattedAsHoursMinutes
                         : "\((-remaining).formattedAsHoursMinutes) over")
                        .monospacedDigit()
                        .foregroundStyle(remaining < 0 ? .orange : .primary)
                }
            }
            LabeledContent("7-day avg") {
                Text("\(sevenDayAverage.formattedAsHoursMinutes)/day")
                    .monospacedDigit()
            }
            Button("How I'm doing →") { showingProgress = true }
        }
    }

    @ViewBuilder
    private var timerSection: some View {
        Section {
            ForEach(SittingType.allCases) { type in
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
        .environment(AppSettings())
}
