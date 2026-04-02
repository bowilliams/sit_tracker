import Foundation

enum SittingType: String, Codable, CaseIterable, Identifiable {
    case supported = "Supported"
    case legsElevated = "Legs Elevated"
    case unsupported = "Unsupported"

    var id: String { rawValue }

    var displayName: String { rawValue }
}
