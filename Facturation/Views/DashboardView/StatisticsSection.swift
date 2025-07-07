import SwiftUI

struct StatisticsSection: View {
    let statistiques: (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int)

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Vue d'ensemble")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                StatCard(
                    title: "Chiffre d'Affaires",
                    value: statistiques.totalCA.euroFormatted,
                    icon: "eurosign.circle.fill",
                    color: .green,
                    trend: .positive
                )

                StatCard(
                    title: "Total Factures",
                    value: "\(statistiques.totalFactures)",
                    icon: "doc.text.fill",
                    color: .blue,
                    trend: .neutral
                )

                StatCard(
                    title: "En Attente",
                    value: "\(statistiques.facturesEnAttente)",
                    icon: "clock.fill",
                    color: .orange,
                    trend: statistiques.facturesEnAttente > 0 ? .negative : .positive
                )

                StatCard(
                    title: "En Retard",
                    value: "\(statistiques.facturesEnRetard)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    trend: statistiques.facturesEnRetard > 0 ? .negative : .positive
                )
            }
        }
    }
}

#Preview {
    StatisticsSection(statistiques: (totalCA: 15000.0, facturesEnAttente: 3, facturesEnRetard: 1, totalFactures: 25))
}