import SwiftUI

struct QualityGauge: View {
    let qualityScore: QualityScore

    private var color: Color {
        switch qualityScore {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }

    private var progress: Double {
        switch qualityScore {
        case .excellent: return 1.0
        case .good: return 0.75
        case .fair: return 0.5
        case .poor: return 0.25
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Label
            Text(qualityScore.rawValue.capitalized)
                .font(.headline)
                .foregroundStyle(color)
        }
        .frame(width: 80, height: 80)
    }
}