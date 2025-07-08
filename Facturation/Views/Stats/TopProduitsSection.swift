import SwiftUI
import Charts
import DataLayer

struct TopProduitsSection: View {
    let produits: [StatistiquesService.ProduitStatistique]
    @Binding var selectedProduit: ProduitDTO?
    @State private var hoveredProduitID: UUID?
    @Environment(\.self) private var environment
    
    private let maxDisplayCount = 8
    
    private var topProduits: [StatistiquesService.ProduitStatistique] {
        Array(produits.prefix(maxDisplayCount))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Produits")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(topProduits.count) sur \(produits.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if topProduits.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart(topProduits, id: \.id) { produit in
            BarMark(
                x: .value("Chiffre d'affaires", produit.chiffreAffaires),
                y: .value("Produit", produit.nom),
                height: 24
            )
            .foregroundStyle(produitColor(for: produit))
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String.euroFormatted(doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
        }
        .frame(height: CGFloat(topProduits.count * 40 + 60))
        .onTapGesture { location in
            handleChartTap(at: location)
        }
        .overlay(
            hoverOverlay
        )
    }
    
    // MARK: - ViewBuilder Helpers
    
    @ViewBuilder
    private func rankingBadge(for index: Int) -> some View {
        Text("\(index + 1)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(rankingColor(for: index))
            .clipShape(Circle())
    }
    
    @ViewBuilder
    private func produitInfo(for produit: StatistiquesService.ProduitStatistique) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(produit.nom)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                Text(String.euroFormatted(produit.chiffreAffaires))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(StatsColorProvider.chartPrimary)
            }
            
            HStack {
                Text("Quantité: \(String.quantityFormatted(produit.quantite))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(produit.nombreVentes) vente\(produit.nombreVentes > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func rowBackground(for produit: StatistiquesService.ProduitStatistique) -> some View {
        Rectangle()
            .fill(isProduitHovered(produit) ? Color.accentColor.opacity(0.1) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: hoveredProduitID)
    }
    
    @ViewBuilder
    private func rowBorder(for produit: StatistiquesService.ProduitStatistique) -> some View {
        Rectangle()
            .stroke(
                isProduitSelected(produit) ? Color.accentColor : Color.clear,
                lineWidth: 2
            )
            .animation(.easeInOut(duration: 0.2), value: selectedProduit?.id)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube.box")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Aucun produit trouvé")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Les statistiques des produits apparaîtront ici une fois que vous aurez des factures avec des lignes de produits.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    @ViewBuilder
    private var hoverOverlay: some View {
        if let hoveredID = hoveredProduitID,
           let hoveredProduit = topProduits.first(where: { $0.id == hoveredID }) {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hoveredProduit.nom)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                        
                        Text("CA: \(String.euroFormatted(hoveredProduit.chiffreAffaires))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("Qté: \(String.quantityFormatted(hoveredProduit.quantite))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(hoveredProduit.nombreVentes) vente\(hoveredProduit.nombreVentes > 1 ? "s" : "")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(.regularMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                }
            }
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Helper Methods
    
    private func produitColor(for produit: StatistiquesService.ProduitStatistique) -> Color {
        // Utilise un UUID basé sur le nom pour la cohérence des couleurs
        let produitUUID = UUID(uuidString: produit.nom.simpleHash) ?? UUID()
        let baseColor = StatsColorProvider.accessibleColorForProduct(id: produitUUID, environment: environment)
        
        if isProduitSelected(produit) {
            return baseColor
        } else if isProduitHovered(produit) {
            return baseColor.opacity(0.8)
        } else {
            return baseColor.opacity(0.6)
        }
    }
    
    private func rankingColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.yellow // Or
        case 1: return Color.gray // Argent
        case 2: return Color.orange // Bronze
        default: return Color.green
        }
    }
    
    private func isProduitSelected(_ produit: StatistiquesService.ProduitStatistique) -> Bool {
        // Compare par nom car ProduitStatistique n'a pas d'UUID direct
        return selectedProduit?.designation == produit.nom
    }
    
    private func isProduitHovered(_ produit: StatistiquesService.ProduitStatistique) -> Bool {
        let produitUUID = UUID(uuidString: produit.nom.simpleHash) ?? UUID()
        return hoveredProduitID == produitUUID
    }
    
    private func handleChartTap(at location: CGPoint) {
        // Logique simplifiée pour la sélection via tap
        // Dans une implémentation réelle, on calculerait quelle barre a été touchée
        if !topProduits.isEmpty {
            // Pour l'instant, on ne peut pas facilement mapper selectedProduit depuis ProduitStatistique
            // Cette fonctionnalité nécessiterait une refonte de l'architecture des données
        }
    }
    
    private func produitAccessibilityLabel(_ produit: StatistiquesService.ProduitStatistique) -> String {
        let position = (topProduits.firstIndex(where: { $0.id == produit.id }) ?? 0) + 1
        return """
        Produit \(position): \(produit.nom), \
        chiffre d'affaires: \(String.accessibilityEuroDescription(produit.chiffreAffaires)), \
        quantité: \(String.accessibilityQuantityDescription(produit.quantite)), \
        \(produit.nombreVentes) vente\(produit.nombreVentes > 1 ? "s" : "")
        """
    }
}

// MARK: - Preview

#if DEBUG
struct TopProduitsSection_Previews: PreviewProvider {
    @State static var selectedProduit: ProduitDTO? = nil
    
    static var previews: some View {
        TopProduitsSection(
            produits: [
                StatistiquesService.ProduitStatistique(
                    nom: "Tomates grappe",
                    quantite: 1250.0,
                    chiffreAffaires: 3125.0,
                    nombreVentes: 45
                ),
                StatistiquesService.ProduitStatistique(
                    nom: "Pommes Golden",
                    quantite: 980.0,
                    chiffreAffaires: 1911.0,
                    nombreVentes: 38
                ),
                StatistiquesService.ProduitStatistique(
                    nom: "Bananes",
                    quantite: 875.0,
                    chiffreAffaires: 1925.0,
                    nombreVentes: 42
                ),
                StatistiquesService.ProduitStatistique(
                    nom: "Courgettes",
                    quantite: 654.0,
                    chiffreAffaires: 1177.2,
                    nombreVentes: 31
                ),
                StatistiquesService.ProduitStatistique(
                    nom: "Poivrons rouges",
                    quantite: 432.0,
                    chiffreAffaires: 1512.0,
                    nombreVentes: 28
                )
            ],
            selectedProduit: $selectedProduit
        )
        .frame(width: 500, height: 400)
        .padding()
    }
}
#endif