import SwiftUI
import Charts
import DataLayer

struct ProduitsStatsView: View {
    @ObservedObject var statistiquesService: StatistiquesService_DTO
    @Binding var selectedProduit: ProduitDTO?

    var body: some View {
        VStack(spacing: 20) {
            // Résumé des statistiques produits
            HStack(spacing: 20) {
                StatCard(
                    title: "Total Produits Vendus",
                    value: String(format: "%.0f", statistiquesService.totalProduitsVendus),
                    icon: "cart.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "CA Total Produits",
                    value: statistiquesService.chiffreAffairesTotalProduits.euroFormatted,
                    icon: "eurosign.circle.fill",
                    color: .green,
                )
                
                StatCard(
                    title: "Produits Uniques",
                    value: "\(statistiquesService.topProduits.count)",
                    icon: "tag.fill",
                    color: .orange,
                )
            }
            
            // Graphiques produits
            HSplitView {
                TopProduitChart(stats: Array(statistiquesService.topProduitsParCA.prefix(5)))
                    .frame(minWidth: 300, idealWidth: 500, maxWidth: .infinity)

                ProduitsPieChart(stats: Array(statistiquesService.topProduitsParCA.prefix(5)))
                    .frame(minWidth: 300, idealWidth: 500, maxWidth: .infinity)
            }

            // Top 5 produits par quantité vendue
            VStack(alignment: .leading) {
                Text("Top 5 Produits par Quantité Vendue")
                    .font(.headline)
                    .padding(.bottom, 5)

                ForEach(statistiquesService.topProduitsParVentes.prefix(5)) { produit in
                    HStack {
                        Text(produit.produit.designation)
                        Spacer()
                        Text("\(String(format: "%.0f", produit.quantiteVendue)) unités")
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

