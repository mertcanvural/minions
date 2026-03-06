import SwiftUI
import Charts

// MARK: - Data Model

struct HourlyCompletion: Identifiable {
    let id = UUID()
    let hour: Int
    let count: Int
}

// MARK: - Chart View

struct PipelineActivityChart: View {
    let data: [HourlyCompletion]

    @Environment(\.colorScheme) private var colorScheme

    static let sampleData: [HourlyCompletion] = [
        HourlyCompletion(hour: 0, count: 1),
        HourlyCompletion(hour: 1, count: 0),
        HourlyCompletion(hour: 2, count: 0),
        HourlyCompletion(hour: 3, count: 1),
        HourlyCompletion(hour: 4, count: 2),
        HourlyCompletion(hour: 5, count: 1),
        HourlyCompletion(hour: 6, count: 3),
        HourlyCompletion(hour: 7, count: 5),
        HourlyCompletion(hour: 8, count: 7),
        HourlyCompletion(hour: 9, count: 8),
        HourlyCompletion(hour: 10, count: 6),
        HourlyCompletion(hour: 11, count: 9),
        HourlyCompletion(hour: 12, count: 5),
        HourlyCompletion(hour: 13, count: 7),
        HourlyCompletion(hour: 14, count: 8),
        HourlyCompletion(hour: 15, count: 10),
        HourlyCompletion(hour: 16, count: 6),
        HourlyCompletion(hour: 17, count: 4),
        HourlyCompletion(hour: 18, count: 3),
        HourlyCompletion(hour: 19, count: 2),
        HourlyCompletion(hour: 20, count: 3),
        HourlyCompletion(hour: 21, count: 1),
        HourlyCompletion(hour: 22, count: 2),
        HourlyCompletion(hour: 23, count: 1)
    ]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Hour", item.hour),
                y: .value("Completions", item.count)
            )
            .foregroundStyle(DesignTokens.accent.gradient)
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 4)) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(hourLabel(hour))
                            .font(DesignTokens.Typography.codeSmall)
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                }
                AxisGridLine()
                    .foregroundStyle(DesignTokens.border(for: colorScheme).opacity(0.5))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(DesignTokens.border(for: colorScheme).opacity(0.5))
                AxisValueLabel()
                    .font(DesignTokens.Typography.codeSmall)
            }
        }
        .chartXScale(domain: 0...23)
        .frame(height: 140)
    }

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        default:
            let h = hour < 12 ? hour : hour - 12
            let suffix = hour < 12 ? "a" : "p"
            return "\(h)\(suffix)"
        }
    }
}

#Preview {
    PipelineActivityChart(data: PipelineActivityChart.sampleData)
        .padding()
        .background(DesignTokens.backgroundLight)
}
