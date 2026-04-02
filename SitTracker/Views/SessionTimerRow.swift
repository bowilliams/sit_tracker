import SwiftUI

struct SessionTimerRow: View {
    let type: SittingType
    let dailyMinutes: Double
    let isActive: Bool
    let elapsedSeconds: Int
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.headline)
                Text(dailyMinutes.formattedAsHoursMinutes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isActive {
                Text(elapsedSeconds.formattedAsElapsed)
                    .font(.title3)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
            }
            Button(action: onTap) {
                Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(isActive ? .red : .accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

private extension Double {
    /// Formats a minute count as "Xh Ym" or "Ym today".
    var formattedAsHoursMinutes: String {
        let total = Int(self)
        let h = total / 60
        let m = total % 60
        if h > 0 { return "\(h)h \(m)m today" }
        return "\(m)m today"
    }
}

private extension Int {
    /// Formats a second count as "H:MM" per the plan spec.
    var formattedAsElapsed: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }
}
