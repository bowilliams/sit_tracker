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
