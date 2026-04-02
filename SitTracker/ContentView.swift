import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var sessions: [Session]

    var body: some View {
        NavigationStack {
            List {
                ForEach(SittingType.allCases) { type in
                    HStack {
                        Text(type.displayName)
                        Spacer()
                        Text("0:00")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Sit Tracker")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Session.self, inMemory: true)
}
