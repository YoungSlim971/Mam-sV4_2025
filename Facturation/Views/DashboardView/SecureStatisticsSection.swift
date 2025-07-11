import SwiftUI
import DataLayer

struct SecureStatisticsSection: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    @State private var statistiques: (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int)?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Vue d'ensemble")
                .font(.title2)
                .fontWeight(.semibold)

            if isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity)
            } else if let errorMessage = errorMessage {
                Text("Erreur: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                    if let stats = statistiques {
                        SecureStatCard(
                            title: "Chiffre d'Affaires",
                            value: stats.totalCA.formattedEuros,
                            icon: "eurosign.circle.fill",
                            color: AppTheme.Colors.primary
                        )
                        
                        SecureStatCard(
                            title: "Factures en attente",
                            value: "\(stats.facturesEnAttente)",
                            icon: "clock.fill",
                            color: AppTheme.Colors.statusSent
                        )
                        
                        SecureStatCard(
                            title: "Factures en retard",
                            value: "\(stats.facturesEnRetard)",
                            icon: "exclamationmark.triangle.fill",
                            color: AppTheme.Colors.statusOverdue
                        )
                        
                        SecureStatCard(
                            title: "Total factures",
                            value: "\(stats.totalFactures)",
                            icon: "doc.text.fill",
                            color: AppTheme.Colors.secondary
                        )
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadStatistics()
            }
        }
    }
    
    private func loadStatistics() async {
        isLoading = true
        errorMessage = nil
        
        let result = await dependencyContainer.getStatistiquesUseCase.execute()
        
        switch result {
        case .success(let stats):
            statistiques = stats
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// Simplified StatCard for compatibility
struct SecureStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    SecureStatisticsSection()
        .environmentObject(DependencyContainer.shared)
}