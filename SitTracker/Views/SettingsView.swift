import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Enable daily quota", isOn: Binding(
                    get: { settings.hasQuota },
                    set: { settings.dailyQuotaMinutes = $0 ? 60 : 0 }
                ))
                if settings.hasQuota {
                    Stepper(
                        "\(settings.dailyQuotaMinutes.formattedAsHoursMinutes) per day",
                        value: $settings.dailyQuotaMinutes,
                        in: 5...480,
                        step: 5
                    )
                }
            } header: {
                Text("Daily Quota")
            } footer: {
                Text("When set, the main screen shows how much sitting time you have remaining today.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Int {
    var formattedAsHoursMinutes: String {
        Double(self).formattedAsHoursMinutes
    }
}
