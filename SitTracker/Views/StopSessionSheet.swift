import SwiftUI

struct StopSessionSheet: View {
    @Environment(TimerManager.self) private var timerManager

    let session: Session
    @State private var editedStart: Date
    @State private var editedStop: Date

    init(session: Session) {
        self.session = session
        _editedStart = State(initialValue: session.startTime)
        _editedStop = State(initialValue: session.stopTime ?? Date())
    }

    private var durationMinutes: Int {
        max(0, Int(editedStop.timeIntervalSince(editedStart) / 60))
    }

    private var isValid: Bool { editedStop > editedStart }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Start", selection: $editedStart, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Stop", selection: $editedStop, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Total") {
                    Text("\(durationMinutes) minutes")
                        .foregroundStyle(isValid ? Color.primary : Color.red)
                }
            }
            .navigationTitle(session.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        timerManager.discardSession(session)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        timerManager.saveSession(session, startTime: editedStart, stopTime: editedStop)
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
