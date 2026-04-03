import SwiftUI
import SwiftData

struct ManualSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TimerManager.self) private var timerManager
    @Query private var allSessions: [Session]

    @State private var editedStart: Date
    @State private var editedStop: Date
    @State private var editedType = SittingType.supported
    @State private var overlapConflict: OverlapConflict?

    init() {
        let now = Date()
        _editedStart = State(initialValue: now)
        _editedStop = State(initialValue: now.addingTimeInterval(30 * 60))
    }

    // MARK: - Derived state

    private var isValid: Bool { editedStop > editedStart }

    private var durationMinutes: Int {
        max(0, Int(editedStop.timeIntervalSince(editedStart) / 60))
    }

    private var completedSessionsForDay: [Session] {
        allSessions.sessions(on: editedStart).filter { $0.stopTime != nil }
    }

    private var sameTypeOverlaps: [Session] {
        completedSessionsForDay
            .filter { $0.type == editedType }
            .overlapping(start: editedStart, stop: editedStop)
    }

    private var differentTypeOverlaps: [Session] {
        completedSessionsForDay
            .filter { $0.type != editedType }
            .overlapping(start: editedStart, stop: editedStop)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Start", selection: $editedStart, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Stop", selection: $editedStop, displayedComponents: [.date, .hourAndMinute])
                    Picker("Type", selection: $editedType) {
                        ForEach(SittingType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                Section("Total") {
                    Text("\(durationMinutes) minutes")
                        .foregroundStyle(isValid ? Color.primary : Color.red)
                }
                if !differentTypeOverlaps.isEmpty {
                    Section {
                        Label(differentTypeOverlapMessage, systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Add Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                        .disabled(!isValid)
                }
            }
        }
        .confirmationDialog(
            "Session Overlap",
            isPresented: Binding(
                get: { overlapConflict != nil },
                set: { if !$0 { overlapConflict = nil } }
            ),
            titleVisibility: .visible,
            presenting: overlapConflict
        ) { conflict in
            Button("Replace Existing") {
                commitSave(startTime: editedStart, stopTime: editedStop, replacing: conflict.sessions)
            }
            Button("Merge") {
                let mergedStart = ([editedStart] + conflict.sessions.map(\.startTime)).min()!
                let mergedStop = ([editedStop] + conflict.sessions.compactMap(\.stopTime)).max()!
                commitSave(startTime: mergedStart, stopTime: mergedStop, replacing: conflict.sessions)
            }
            Button("Keep Existing") {
                // Manual entry is abandoned; existing sessions are unchanged.
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                // Stay in the form so the user can adjust times.
            }
        } message: { conflict in
            let count = conflict.sessions.count
            Text("This overlaps with \(count) existing \(editedType.displayName.lowercased()) session\(count == 1 ? "" : "s"). How would you like to handle it?")
        }
    }

    // MARK: - Actions

    private func attemptSave() {
        guard isValid else { return }
        let overlaps = sameTypeOverlaps
        if overlaps.isEmpty {
            commitSave(startTime: editedStart, stopTime: editedStop, replacing: [])
        } else {
            overlapConflict = OverlapConflict(sessions: overlaps)
        }
    }

    private func commitSave(startTime: Date, stopTime: Date, replacing: [Session]) {
        timerManager.addManualSession(
            startTime: startTime,
            stopTime: stopTime,
            type: editedType,
            replacing: replacing
        )
        dismiss()
    }

    // MARK: - Helpers

    private var differentTypeOverlapMessage: String {
        let typeNames = Set(differentTypeOverlaps.map { $0.type.displayName.lowercased() }).sorted()
        let typeList: String
        if typeNames.count == 1 {
            typeList = "a \(typeNames[0])"
        } else {
            typeList = typeNames.dropLast().joined(separator: ", ") + " and \(typeNames.last!)"
        }
        return "Also overlaps with \(typeList) session\(typeNames.count == 1 ? "" : "s"). Both will be saved."
    }
}

private struct OverlapConflict: Identifiable {
    let id = UUID()
    let sessions: [Session]
}
