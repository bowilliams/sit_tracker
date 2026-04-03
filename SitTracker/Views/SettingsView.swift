import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Form {
            Section {
                Toggle("Enable daily quota", isOn: Binding(
                    get: { settings.hasQuota },
                    set: { settings.dailyQuotaMinutes = $0 ? 60 : 0 }
                ))
                if settings.hasQuota {
                    HStack(spacing: 0) {
                        Picker("Hours", selection: hoursBinding) {
                            ForEach(0...8, id: \.self) { h in
                                Text("\(h)h").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Minutes", selection: minutesBinding) {
                            ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { m in
                                Text("\(m)m").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
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

    private var hoursBinding: Binding<Int> {
        Binding(
            get: { settings.dailyQuotaMinutes / 60 },
            set: { settings.dailyQuotaMinutes = $0 * 60 + settings.dailyQuotaMinutes % 60 }
        )
    }

    private var minutesBinding: Binding<Int> {
        Binding(
            get: { settings.dailyQuotaMinutes % 60 },
            set: { settings.dailyQuotaMinutes = (settings.dailyQuotaMinutes / 60) * 60 + $0 }
        )
    }
}
