import SwiftUI
import Charts

struct LatencyChart: View {
    let metrics: [NetworkMetrics]

    var body: some View {
        Chart(metrics) { metric in
            // Min/max range as area
            AreaMark(
                x: .value("Time", metric.timestamp),
                yStart: .value("Min", metric.latency.min),
                yEnd: .value("Max", metric.latency.max)
            )
            .foregroundStyle(.blue.opacity(0.15))

            // Average latency as line
            LineMark(
                x: .value("Time", metric.timestamp),
                y: .value("Average", metric.latency.average)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartYAxisLabel("Latency (ms)")
        .chartXAxisLabel("Time")
        .frame(height: 200)
    }
}