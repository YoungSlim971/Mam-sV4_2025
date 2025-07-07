import SwiftUI
import Charts

struct ProduitsPieChart: View {
    let stats: [StatistiquesService.ProduitStatistique]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Répartition des ventes (Top 5 produits)")
                .font(.headline)
                .padding(.bottom, 8)
            Chart(stats) { produitStat in
                SectorMark(
                    angle: .value("Quantité", produitStat.quantite),
                    innerRadius: .ratio(0.6),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Produit", produitStat.nom))
            }
            .chartLegend(position: .bottom)
            .frame(height: 300)
        }
        .padding()
        .background(Material.ultraThin)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}
