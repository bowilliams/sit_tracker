import Foundation

enum SittingType: String, Codable, CaseIterable, Identifiable {
    case supported = "supported"
    case legsElevated = "legs_elevated"
    case unsupported = "unsupported"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .supported:     return "Supported"
        case .legsElevated:  return "Legs Elevated"
        case .unsupported:   return "Unsupported"
        }
    }
}
