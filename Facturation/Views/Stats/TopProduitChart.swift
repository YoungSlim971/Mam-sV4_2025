//
//  TopProduitChart.swift
//  Facturation
//
//  Created by Young Slim on 05/07/2025.
//



import SwiftUI
import Charts

struct TopProduitChart: View {
    let stats: [StatistiquesService_DTO.ProduitStatistique]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Produits par Chiffre d'Affaires")
                .font(.headline)
                .padding(.bottom, 8)
            
            chartContent
        }
        .padding()
        .background(Material.ultraThin)
        .cornerRadius(12)
    }
    
    private var chartContent: some View {
        Group {
            if stats.isEmpty {
                emptyStateView
            } else {
                produitChart
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "cart")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Aucune donnée produit")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var produitChart: some View {
        Chart(Array(stats.prefix(10))) { stat in
            BarMark(
                x: .value("Chiffre d'Affaires", stat.chiffreAffaires),
                y: .value("Produit", stat.produit.designation)
            )
            .foregroundStyle(Color.orange)
            .cornerRadius(4)
            .annotation(position: .trailing) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stat.chiffreAffaires, specifier: "%.0f") €")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                    Text("\(stat.quantiteVendue, specifier: "%.0f") unités")
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
