import Foundation

@Observable
final class AppSettings {
    /// Daily sitting quota in minutes. 0 means no quota is set.
    var dailyQuotaMinutes: Int {
        didSet { UserDefaults.standard.set(dailyQuotaMinutes, forKey: "dailyQuotaMinutes") }
    }

    var hasQuota: Bool { dailyQuotaMinutes > 0 }

    init() {
        dailyQuotaMinutes = UserDefaults.standard.integer(forKey: "dailyQuotaMinutes")
    }
}
