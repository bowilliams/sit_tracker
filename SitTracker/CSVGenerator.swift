import Foundation
import UniformTypeIdentifiers
import CoreTransferable

enum CSVGenerator {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func generate(from sessions: [Session]) -> String {
        let completed = sessions
            .filter { $0.stopTime != nil }
            .sorted { $0.startTime < $1.startTime }

        var rows: [String] = ["date,start_time,stop_time,type,minutes"]
        for session in completed {
            let stop = session.stopTime!
            let date = dateFormatter.string(from: session.startTime)
            let start = timeFormatter.string(from: session.startTime)
            let stopStr = timeFormatter.string(from: stop)
            let minutes = String(format: "%.1f", session.durationMinutes)
            let type = escape(session.type.rawValue)
            rows.append("\(date),\(start),\(stopStr),\(type),\(minutes)")
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

struct CSVDocument: Transferable {
    let csv: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { doc in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("sit_tracker_export.csv")
            try doc.csv.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}
