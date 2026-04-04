import XCTest
@testable import SitTracker

final class CSVGeneratorTests: XCTestCase {

    // MARK: - Helpers

    private func makeSession(startISO: String, minutes: Double, type: SittingType) -> Session {
        let s = Session(startTime: parseISO(startISO), type: type)
        s.stopTime = s.startTime.addingTimeInterval(minutes * 60)
        return s
    }

    private func parseISO(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso)!
    }

    // MARK: - Header

    func testGenerate_headerRow() {
        let csv = CSVGenerator.generate(from: [])
        let firstLine = csv.components(separatedBy: "\n").first
        XCTAssertEqual(firstLine, "date,start_time,stop_time,type,minutes")
    }

    func testGenerate_emptyInput_onlyHeader() {
        let csv = CSVGenerator.generate(from: [])
        XCTAssertEqual(csv, "date,start_time,stop_time,type,minutes")
    }

    // MARK: - Row format

    func testGenerate_singleSession_rowFormat() {
        // 2026-03-01 09:00 UTC, 30 minutes, supported
        let session = makeSession(startISO: "2026-03-01T09:00:00Z", minutes: 30, type: .supported)
        let lines = CSVGenerator.generate(from: [session]).components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2)
        let row = lines[1]
        // date column
        XCTAssertTrue(row.hasPrefix("2026-03-01,"), "Expected date 2026-03-01, got: \(row)")
        // type column
        XCTAssertTrue(row.contains(",supported,"), "Expected type 'supported', got: \(row)")
        // minutes column (30)
        XCTAssertTrue(row.hasSuffix(",30"), "Expected minutes 30, got: \(row)")
    }

    // MARK: - Active sessions excluded

    func testGenerate_activeSessionExcluded() {
        let active = Session(startTime: Date(), type: .supported) // no stopTime
        let csv = CSVGenerator.generate(from: [active])
        XCTAssertEqual(csv, "date,start_time,stop_time,type,minutes")
    }

    func testGenerate_mixedSessions_onlyCompletedIncluded() {
        let completed = makeSession(startISO: "2026-03-01T09:00:00Z", minutes: 30, type: .supported)
        let active = Session(startTime: Date(), type: .legsElevated)
        let lines = CSVGenerator.generate(from: [completed, active]).components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2) // header + 1 completed row
    }

    // MARK: - Sort order

    func testGenerate_sortedByStartTime() {
        let earlier = makeSession(startISO: "2026-03-01T08:00:00Z", minutes: 10, type: .supported)
        let later = makeSession(startISO: "2026-03-01T10:00:00Z", minutes: 10, type: .legsElevated)
        // Pass in reverse order
        let lines = CSVGenerator.generate(from: [later, earlier]).components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[1].contains(",supported,"), "Earlier session should come first")
        XCTAssertTrue(lines[2].contains(",legs_elevated,"), "Later session should come second")
    }

    // MARK: - CSV escaping

    func testGenerate_typeWithNoSpecialChars_notQuoted() {
        let session = makeSession(startISO: "2026-03-01T09:00:00Z", minutes: 10, type: .legsElevated)
        let lines = CSVGenerator.generate(from: [session]).components(separatedBy: "\n")
        XCTAssertTrue(lines[1].contains(",legs_elevated,"))
    }
}
