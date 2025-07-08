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
                        Text(produit.nom)
                        Spacer()
                        Text("\(String(format: "%.0f", produit.quantite)) unités")
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
            .background(Color.clear)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

