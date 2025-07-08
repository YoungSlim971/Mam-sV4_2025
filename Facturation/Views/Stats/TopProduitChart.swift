//
//  TopProduitChart.swift
//  Facturation
//
//  Created by Young Slim on 05/07/2025.
//



import SwiftUI
import Charts

struct TopProduitChart: View {
    let stats: [StatistiquesService.ProduitStatistique]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Produits par Chiffre d'Affaires")
                .font(.headline)
                .padding(.bottom, 8)
            
            if stats.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "cart")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Aucune donnée produit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                let top10Produits = Array(stats.prefix(10))
                Chart(top10Produits) { stat in
                    BarMark(
                        x: .value("Chiffre d'Affaires", stat.chiffreAffaires),
                        y: .value("Produit", stat.nom)
                    )
                    .foregroundStyle(Color.orange)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(stat.chiffreAffaires, specifier: "%.0f") €")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                            Text("\(stat.quantite, specifier: "%.0f") unités")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisValueLabel()
                    }
                }
                .frame(height: 300)
            }
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
