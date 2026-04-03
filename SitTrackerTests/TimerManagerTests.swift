import XCTest
import SwiftData
@testable import SitTracker

@MainActor
final class TimerManagerTests: XCTestCase {

    private var modelContext: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Session.self, configurations: config)
        modelContext = ModelContext(container)
    }

    override func tearDown() {
        modelContext = nil
    }

    /// Returns a date on today with the given hour and minute in the current calendar.
    private func makeDate(hour: Int, minute: Int) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
    }

    // MARK: - Timer switch flow

    func testTimerSwitch_stopsFirstSessionAndShowsSaveSheet() throws {
        let manager = TimerManager(modelContext: modelContext)

        manager.startTimer(for: .supported)
        let firstSession = manager.activeSession
        XCTAssertNotNil(firstSession)

        manager.startTimer(for: .legsElevated)

        // First session is stopped
        XCTAssertNotNil(firstSession?.stopTime)
        // No active session while sheet is showing
        XCTAssertNil(manager.activeSession)
        // Save sheet is presented for the first session
        XCTAssertEqual(manager.sessionToSave?.type, .supported)
    }

    func testTimerSwitch_afterSave_startsNewSession() throws {
        let manager = TimerManager(modelContext: modelContext)

        manager.startTimer(for: .supported)
        let firstSession = manager.activeSession!
        manager.startTimer(for: .legsElevated)

        manager.saveSession(firstSession, startTime: firstSession.startTime, stopTime: firstSession.stopTime!)

        XCTAssertEqual(manager.activeSession?.type, .legsElevated)
        XCTAssertNil(manager.sessionToSave)
    }

    func testTimerSwitch_afterDiscard_startsNewSession() throws {
        let manager = TimerManager(modelContext: modelContext)

        manager.startTimer(for: .unsupported)
        let firstSession = manager.activeSession!
        manager.startTimer(for: .supported)

        manager.discardSession(firstSession)

        XCTAssertEqual(manager.activeSession?.type, .supported)
        XCTAssertNil(manager.sessionToSave)
    }

    // MARK: - addManualSession

    func testAddManualSession_savesSessionWithCorrectFields() throws {
        let manager = TimerManager(modelContext: modelContext)
        let start = makeDate(hour: 10, minute: 0)
        let stop = makeDate(hour: 11, minute: 0)

        manager.addManualSession(startTime: start, stopTime: stop, type: .legsElevated)

        let sessions = try modelContext.fetch(FetchDescriptor<Session>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].startTime, start)
        XCTAssertEqual(sessions[0].stopTime, stop)
        XCTAssertEqual(sessions[0].type, .legsElevated)
        XCTAssertEqual(sessions[0].date, Calendar.current.startOfDay(for: start))
    }

    func testAddManualSession_replace_deletesExistingAndSavesNew() throws {
        let manager = TimerManager(modelContext: modelContext)

        // Existing session 10:00–11:00
        let existing = Session(startTime: makeDate(hour: 10, minute: 0), type: .supported)
        existing.stopTime = makeDate(hour: 11, minute: 0)
        modelContext.insert(existing)
        try modelContext.save()

        // Manual entry 10:30–12:00 replaces the existing one
        manager.addManualSession(
            startTime: makeDate(hour: 10, minute: 30),
            stopTime: makeDate(hour: 12, minute: 0),
            type: .supported,
            replacing: [existing]
        )

        let sessions = try modelContext.fetch(FetchDescriptor<Session>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].startTime, makeDate(hour: 10, minute: 30))
    }

    func testAddManualSession_merge_savesUnionOfTimeSpan() throws {
        let manager = TimerManager(modelContext: modelContext)

        // Existing session 10:00–11:00
        let existing = Session(startTime: makeDate(hour: 10, minute: 0), type: .supported)
        existing.stopTime = makeDate(hour: 11, minute: 0)
        modelContext.insert(existing)
        try modelContext.save()

        // Manual entry 10:30–12:00 — merge should yield 10:00–12:00
        let newStart = makeDate(hour: 10, minute: 30)
        let newStop = makeDate(hour: 12, minute: 0)
        let mergedStart = ([newStart, existing.startTime]).min()!
        let mergedStop = ([newStop, existing.stopTime!]).max()!

        manager.addManualSession(
            startTime: mergedStart,
            stopTime: mergedStop,
            type: .supported,
            replacing: [existing]
        )

        let sessions = try modelContext.fetch(FetchDescriptor<Session>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].startTime, makeDate(hour: 10, minute: 0))
        XCTAssertEqual(sessions[0].stopTime, makeDate(hour: 12, minute: 0))
    }

    func testAddManualSession_differentType_savesAlongside() throws {
        let manager = TimerManager(modelContext: modelContext)

        // Existing session of a different type
        let existing = Session(startTime: makeDate(hour: 10, minute: 0), type: .legsElevated)
        existing.stopTime = makeDate(hour: 11, minute: 0)
        modelContext.insert(existing)
        try modelContext.save()

        // Manual entry overlaps but is a different type — save both, no replacement
        manager.addManualSession(
            startTime: makeDate(hour: 10, minute: 30),
            stopTime: makeDate(hour: 11, minute: 30),
            type: .supported,
            replacing: []
        )

        let sessions = try modelContext.fetch(FetchDescriptor<Session>())
        XCTAssertEqual(sessions.count, 2)
    }

    // MARK: - saveSession updates session.date

    func testSaveSession_updatesDateWhenStartTimeDayChanges() throws {
        let manager = TimerManager(modelContext: modelContext)

        // Start and immediately stop a session
        manager.startTimer(for: .supported)
        let session = manager.activeSession!
        manager.stopTimer()

        // Edit start time to a different calendar day
        let originalDate = session.date
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: session.startTime)!
        let newStop = yesterday.addingTimeInterval(30 * 60)

        manager.saveSession(session, startTime: yesterday, stopTime: newStop)

        XCTAssertNotEqual(session.date, originalDate)
        XCTAssertEqual(session.date, Calendar.current.startOfDay(for: yesterday))
    }

    func testSaveSession_dateUnchangedWhenStartTimeSameDay() throws {
        let manager = TimerManager(modelContext: modelContext)

        manager.startTimer(for: .supported)
        let session = manager.activeSession!
        manager.stopTimer()

        let originalDate = session.date
        // Adjust start time by a few minutes — same day
        let adjustedStart = session.startTime.addingTimeInterval(-5 * 60)
        let adjustedStop = session.stopTime!

        manager.saveSession(session, startTime: adjustedStart, stopTime: adjustedStop)

        XCTAssertEqual(session.date, originalDate)
    }

    // MARK: - Background resume

    func testBackgroundResume_restoresActiveSessionWithCorrectElapsed() throws {
        // Simulate a session that started 5 minutes ago (e.g., app was killed mid-session)
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        let session = Session(startTime: fiveMinutesAgo, type: .legsElevated)
        modelContext.insert(session)
        try modelContext.save()

        // Creating a new TimerManager simulates app relaunch
        let manager = TimerManager(modelContext: modelContext)

        XCTAssertNotNil(manager.activeSession)
        XCTAssertEqual(manager.activeSession?.id, session.id)
        // Allow 2 seconds of tolerance for test execution time
        XCTAssertEqual(Double(manager.elapsedSeconds), 5 * 60, accuracy: 2)
    }

    func testBackgroundResume_noActiveSession_elapsedIsZero() throws {
        let manager = TimerManager(modelContext: modelContext)
        XCTAssertNil(manager.activeSession)
        XCTAssertEqual(manager.elapsedSeconds, 0)
    }
}
