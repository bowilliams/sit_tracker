import SwiftUI
import Charts

struct HowImDoingView: View {
    @Environment(AppSettings.self) private var settings

    let chartData: [DayData]
    let sevenDayAverage: Double

    var body: some View {
        NavigationStack {
            List {
                Section("Last 7 Days") {
                    Chart {
                        ForEach(chartData) { entry in
                            BarMark(
                                x: .value("Day", entry.day, unit: .day),
                                y: .value("Minutes", entry.minutes)
                            )
                            .foregroundStyle(barColor(for: entry.minutes))
                        }
                        if settings.hasQuota {
                            RuleMark(y: .value("Quota", Double(settings.dailyQuotaMinutes)))
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Quota")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let mins = value.as(Double.self) {
                                    Text(mins.formattedAsHoursMinutes)
                                }
                            }
                        }
                    }
                    .frame(height: 220)
                    .padding(.vertical, 8)
                }

                Section("Summary") {
                    LabeledContent("7-day average") {
                        Text("\(sevenDayAverage.formattedAsHoursMinutes)/day")
                    }
                    if settings.hasQuota {
                        LabeledContent("Daily quota") {
                            Text(Double(settings.dailyQuotaMinutes).formattedAsHoursMinutes)
                        }
                    }
                }
            }
            .navigationTitle("How I'm Doing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func barColor(for minutes: Double) -> Color {
        guard settings.hasQuota else { return .accentColor }
        return minutes > Double(settings.dailyQuotaMinutes) ? .orange : .accentColor
    }
}

struct DayData: Identifiable {
    let day: Date
    let minutes: Double
    var id: Date { day }
}
