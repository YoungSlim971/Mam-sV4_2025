import SwiftUI
import AppKit

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection

    enum TrendDirection {
        case positive, negative, neutral

        var color: Color {
            switch self {
                case .positive: return .green
                case .negative: return .red
                case .neutral: return .gray
            }
        }

        var icon: String {
            switch self {
                case .positive: return "arrow.up.right"
                case .negative: return "arrow.down.right"
                case .neutral: return "minus"
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()

                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(height: 100)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatCard(
            title: "Chiffre d'Affaires",
            value: "15,000 €",
            icon: "eurosign.circle.fill",
            color: .green,
            trend: .positive
        )
        
        EmptyStateView(
            icon: "doc.text.fill",
            title: "Aucune facture",
            description: "Créez votre première facture pour commencer"
        )
    }
    .padding()
}