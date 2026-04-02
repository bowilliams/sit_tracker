import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var startTime: Date
    var stopTime: Date?
    var type: SittingType
    // Date the sitting started (for midnight rollover — session belongs to this calendar day)
    var date: Date

    init(startTime: Date, type: SittingType) {
        self.id = UUID()
        self.startTime = startTime
        self.stopTime = nil
        self.type = type
        self.date = Calendar.current.startOfDay(for: startTime)
    }

    // MARK: - Computed properties

    var durationMinutes: Double {
        let end = stopTime ?? Date()
        return end.timeIntervalSince(startTime) / 60
    }

    var isActive: Bool { stopTime == nil }
}

// MARK: - Aggregation helpers

extension [Session] {
    /// Total minutes for a given type across the sessions in this collection.
    func totalMinutes(for type: SittingType) -> Double {
        filter { $0.type == type }.reduce(0) { $0 + $1.durationMinutes }
    }

    /// Total minutes across all sitting types.
    var totalMinutes: Double {
        reduce(0) { $0 + $1.durationMinutes }
    }

    /// Sessions that belong to a specific calendar day.
    func sessions(on day: Date) -> [Session] {
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        return filter { $0.date >= start && $0.date < end }
    }

    /// Rolling average of daily total minutes over the last `days` days ending on `endDate`.
    func rollingAverage(days: Int = 7, endingOn endDate: Date = Date()) -> Double {
        guard days > 0 else { return 0 }
        var total = 0.0
        for offset in 0..<days {
            guard let day = Calendar.current.date(byAdding: .day, value: -(days - 1 - offset), to: Calendar.current.startOfDay(for: endDate)) else { continue }
            total += sessions(on: day).totalMinutes
        }
        return total / Double(days)
    }
}
