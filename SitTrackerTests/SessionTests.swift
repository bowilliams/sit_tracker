import XCTest
@testable import SitTracker

final class SessionTests: XCTestCase {

    // MARK: - Duration

    func testDurationMinutes_completedSession() {
        let start = Date()
        let session = Session(startTime: start, type: .supported)
        session.stopTime = start.addingTimeInterval(90 * 60) // 90 minutes
        XCTAssertEqual(session.durationMinutes, 90, accuracy: 0.001)
    }

    func testDurationMinutes_activeSession_isAtMostOneMinute() {
        let session = Session(startTime: Date(), type: .supported)
        // Active session uses Date() internally; duration rounds up to 1 minute immediately after creation
        XCTAssertEqual(session.durationMinutes, 1, accuracy: 0.001)
    }

    // MARK: - Daily total per type

    func testTotalMinutes_forType_sumsCorrectType() {
        let base = Date()
        let s1 = makeSession(start: base, minutes: 30, type: .supported)
        let s2 = makeSession(start: base, minutes: 20, type: .supported)
        let s3 = makeSession(start: base, minutes: 15, type: .legsElevated)

        let sessions = [s1, s2, s3]
        XCTAssertEqual(sessions.totalMinutes(for: .supported), 50, accuracy: 0.001)
        XCTAssertEqual(sessions.totalMinutes(for: .legsElevated), 15, accuracy: 0.001)
        XCTAssertEqual(sessions.totalMinutes(for: .unsupported), 0, accuracy: 0.001)
    }

    func testTotalMinutes_allTypes() {
        let base = Date()
        let sessions = [
            makeSession(start: base, minutes: 10, type: .supported),
            makeSession(start: base, minutes: 20, type: .legsElevated),
            makeSession(start: base, minutes: 30, type: .unsupported),
        ]
        XCTAssertEqual(sessions.totalMinutes, 60, accuracy: 0.001)
    }

    // MARK: - Quota remaining

    func testQuotaRemaining_underQuota() {
        let base = Calendar.current.startOfDay(for: Date())
        let sessions = [makeSession(start: base, minutes: 30, type: .supported)]
        let quota = 60
        let remaining = Double(quota) - sessions.totalMinutes
        XCTAssertEqual(remaining, 30, accuracy: 0.001)
        XCTAssertGreaterThan(remaining, 0)
    }

    func testQuotaRemaining_overQuota() {
        let base = Calendar.current.startOfDay(for: Date())
        let sessions = [makeSession(start: base, minutes: 75, type: .supported)]
        let quota = 60
        let remaining = Double(quota) - sessions.totalMinutes
        XCTAssertLessThan(remaining, 0, "Negative remaining means over quota")
        XCTAssertEqual(remaining, -15, accuracy: 0.001)
    }

    func testQuotaRemaining_exactlyAtQuota() {
        let base = Calendar.current.startOfDay(for: Date())
        let sessions = [makeSession(start: base, minutes: 60, type: .supported)]
        let quota = 60
        let remaining = Double(quota) - sessions.totalMinutes
        XCTAssertEqual(remaining, 0, accuracy: 0.001)
    }

    func testQuotaRemaining_noSessions() {
        let sessions: [Session] = []
        let quota = 60
        let remaining = Double(quota) - sessions.totalMinutes
        XCTAssertEqual(remaining, 60, accuracy: 0.001)
    }

    // MARK: - Rolling 7-day average

    func testRollingAverage_uniformDays() {
        // 7 days, 60 minutes each → average = 60
        let today = Calendar.current.startOfDay(for: Date())
        var sessions: [Session] = []
        for offset in 0..<7 {
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: today)!
            sessions.append(makeSession(start: day, minutes: 60, type: .supported))
        }
        XCTAssertEqual(sessions.rollingAverage(days: 7, endingOn: today), 60, accuracy: 0.001)
    }

    func testRollingAverage_someDaysEmpty() {
        // Only today has data (60 min), other 6 days are empty → average = 60/7
        let today = Calendar.current.startOfDay(for: Date())
        let sessions = [makeSession(start: today, minutes: 60, type: .supported)]
        XCTAssertEqual(sessions.rollingAverage(days: 7, endingOn: today), 60.0 / 7.0, accuracy: 0.001)
    }

    func testRollingAverage_sessionOutsideWindow_notCounted() {
        let today = Calendar.current.startOfDay(for: Date())
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: today)!
        let sessions = [makeSession(start: eightDaysAgo, minutes: 120, type: .supported)]
        XCTAssertEqual(sessions.rollingAverage(days: 7, endingOn: today), 0, accuracy: 0.001)
    }

    // MARK: - sessions(on:)

    func testSessionsOnDay_returnsOnlyMatchingDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let s1 = makeSession(start: today, minutes: 10, type: .supported)
        let s2 = makeSession(start: today, minutes: 20, type: .legsElevated)
        let s3 = makeSession(start: yesterday, minutes: 30, type: .supported)

        let sessions = [s1, s2, s3]
        XCTAssertEqual(sessions.sessions(on: today).count, 2)
        XCTAssertEqual(sessions.sessions(on: yesterday).count, 1)
        XCTAssertEqual(sessions.sessions(on: yesterday).first?.type, .supported)
    }

    func testSessionsOnDay_emptyForDayWithNoSessions() {
        let today = Calendar.current.startOfDay(for: Date())
        let sessions = [makeSession(start: today, minutes: 10, type: .supported)]
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        XCTAssertTrue(sessions.sessions(on: tomorrow).isEmpty)
    }

    func testSessionsOnDay_usesStoredDateNotStartTime() {
        // session.date is set to startOfDay(startTime) at creation; sessions(on:)
        // filters by session.date, so a session starting near midnight belongs to
        // the day it started on, not any later day.
        let today = Calendar.current.startOfDay(for: Date())
        // 1 second before midnight — still "today"
        let nearMidnight = Calendar.current.date(byAdding: .second, value: -1, to:
            Calendar.current.date(byAdding: .day, value: 1, to: today)!)!
        let s = makeSession(start: nearMidnight, minutes: 5, type: .supported)
        XCTAssertEqual([s].sessions(on: today).count, 1)
    }

    // MARK: - Helpers

    private func makeSession(start: Date, minutes: Double, type: SittingType) -> Session {
        let s = Session(startTime: start, type: type)
        s.stopTime = start.addingTimeInterval(minutes * 60)
        return s
    }
}
