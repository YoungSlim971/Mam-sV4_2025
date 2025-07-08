import SwiftUI

struct StatisticsSection: View {
    @ObservedObject var statsService: StatistiquesService

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Vue d'ensemble")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                StatCard(
                    title: "Chiffre d'Affaires",
                    value: statsService.caMensuel.values.reduce(0, +).euroFormatted,
                    icon: "eurosign.circle.fill",
                    color: .green,
                    trend: .positive
                )

                StatCard(
                    title: "Total Factures",
                    value: "\(statsService.repartitionStatuts.values.reduce(0) { $0 + $1.count })",
                    icon: "doc.text.fill",
                    color: .blue,
                    trend: .neutral
                )

                StatCard(
                    title: "En Attente",
                    value: "\(statsService.repartitionStatuts[.envoyee, default: []].count)",
                    icon: "clock.fill",
                    color: .orange,
                    trend: statsService.repartitionStatuts[.envoyee, default: []].count > 0 ? .negative : .positive
                )

                StatCard(
                    title: "En Retard",
                    value: "\(statsService.repartitionStatuts[.enRetard, default: []].count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    trend: statsService.repartitionStatuts[.enRetard, default: []].count > 0 ? .negative : .positive
                )
            }
        }
    }
}

#Preview {
    StatisticsSection(statsService: StatistiquesService())
}