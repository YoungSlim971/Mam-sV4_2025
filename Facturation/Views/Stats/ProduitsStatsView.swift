import SwiftUI
import Charts

struct ProduitsStatsView: View {
    @ObservedObject var statistiquesService: StatistiquesService
    @Binding var selectedProduit: ProduitDTO?

    var body: some View {
        VStack(spacing: 20) {
            // Résumé des statistiques produits
            HStack(spacing: 20) {
                StatCard(
                    title: "Total Produits Vendus",
                    value: String(format: "%.0f", statistiquesService.totalProduitsVendus),
                    icon: "cart.fill",
                    color: .blue,
                    trend: .neutral
                )
                
                StatCard(
                    title: "CA Total Produits",
                    value: String(format: "%.2f €", statistiquesService.chiffreAffairesTotalProduits),
                    icon: "eurosign.circle.fill",
                    color: .green,
                    trend: .neutral
                )
                
                StatCard(
                    title: "Produits Uniques",
                    value: "\(statistiquesService.topProduits.count)",
                    icon: "tag.fill",
                    color: .orange,
                    trend: .neutral
                )
            }
            
            // Graphiques
            HSplitView {
                TopProduitChart(stats: Array(statistiquesService.topProduits.prefix(5)))
                    .frame(minWidth: 300, idealWidth: 500, maxWidth: .infinity)

                ProduitsPieChart(stats: Array(statistiquesService.topProduits.prefix(5)))
                    .frame(minWidth: 300, idealWidth: 500, maxWidth: .infinity)
            }
        }
    }
}

