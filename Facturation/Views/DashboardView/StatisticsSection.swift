import SwiftUI
import DataLayer

struct StatisticsSection: View {
    @ObservedObject var statsService: StatistiquesService_DTO

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
                    color: .green
                )

                StatCard(
                    title: "Total Factures",
                    value: "\(statsService.repartitionStatuts.values.reduce(0) { $0 + $1.count })",
                    icon: "doc.text.fill",
                    color: .blue
                )

                StatCard(
                    title: "En Attente",
                    value: "\(statsService.repartitionStatuts[.envoyee, default: []].count)",
                    icon: "clock.fill",
                    color: .orange
                )

                StatCard(
                    title: "En Retard",
                    value: "\(statsService.repartitionStatuts[.enRetard, default: []].count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
    }
}

#Preview {
    StatisticsSection(statsService: StatistiquesService_DTO())
}