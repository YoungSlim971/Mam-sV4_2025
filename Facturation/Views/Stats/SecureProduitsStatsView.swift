import SwiftUI
import Charts
import DataLayer

struct SecureProduitsStatsView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Binding var selectedProduit: ProduitDTO?
    
    @State private var produitStatistiques: [ProduitStatistiqueResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Chargement des statistiques produits...")
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Erreur: \(errorMessage)")
                        .foregroundColor(.red)
                    Button("Réessayer") {
                        Task {
                            await loadStatistiques()
                        }
                    }
                }
            } else {
                // Résumé des statistiques produits
                HStack(spacing: 20) {
                    StatCard(
                        title: "Total Produits Vendus",
                        value: String(format: "%.0f", totalProduitsVendus),
                        icon: "cart.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "CA Total Produits",
                        value: chiffreAffairesTotalProduits.euroFormatted,
                        icon: "eurosign.circle.fill",
                        color: .green,
                    )
                    
                    StatCard(
                        title: "Produits Uniques",
                        value: "\(produitStatistiques.count)",
                        icon: "tag.fill",
                        color: .orange,
                    )
                }
                
                // Graphiques produits
                if !produitStatistiques.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Top 5 Produits par CA")
                            .font(.headline)
                            .padding(.bottom, 5)

                        ForEach(produitStatistiques.prefix(5)) { produit in
                            HStack {
                                Text(produit.produit.designation)
                                Spacer()
                                Text("\(String(format: "%.0f", produit.quantiteVendue)) unités")
                                Text(produit.chiffreAffaires.euroFormatted)
                                    .fontWeight(.semibold)
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
        .onAppear {
            Task {
                await loadStatistiques()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalProduitsVendus: Double {
        return produitStatistiques.reduce(0) { $0 + $1.quantiteVendue }
    }
    
    private var chiffreAffairesTotalProduits: Double {
        return produitStatistiques.reduce(0) { $0 + $1.chiffreAffaires }
    }
    
    // MARK: - Private Methods
    
    private func loadStatistiques() async {
        isLoading = true
        errorMessage = nil
        
        // Utilisation du use case spécifique aux produits
        let result = await dependencyContainer.getStatistiquesProduitsUseCase.execute()
        
        switch result {
        case .success(let stats):
            produitStatistiques = stats
            
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des statistiques: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    SecureProduitsStatsView(selectedProduit: .constant(nil))
        .environmentObject(DependencyContainer.shared)
}