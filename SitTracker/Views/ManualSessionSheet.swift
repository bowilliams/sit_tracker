import SwiftUI

struct ManualSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TimerManager.self) private var timerManager

    @State private var editedStart: Date
    @State private var editedStop: Date
    @State private var editedType = SittingType.supported

    init() {
        let now = Date()
        _editedStart = State(initialValue: now)
        _editedStop = State(initialValue: now.addingTimeInterval(30 * 60))
    }

    private var isValid: Bool { editedStop > editedStart }

    private var durationMinutes: Int {
        max(0, Int(editedStop.timeIntervalSince(editedStart) / 60))
    }

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
            }
            .navigationTitle("Add Session")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: editedStart) { oldStart, newStart in
                // Keep the same duration when the start date/time changes.
                let duration = editedStop.timeIntervalSince(oldStart)
                editedStop = newStart.addingTimeInterval(duration)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        timerManager.addManualSession(
                            startTime: editedStart,
                            stopTime: editedStop,
                            type: editedType
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
