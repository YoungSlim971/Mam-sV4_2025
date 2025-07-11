import SwiftUI
import DataLayer

struct SecureDashboardView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    @State private var statistiques: (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int)?
    @State private var recentFactures: [FactureDTO] = []
    @State private var clients: [ClientDTO] = []
    @State private var caParMois: [Double] = []
    @State private var facturesParStatut: [StatutFacture: Int] = [:]
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                
                if isLoading {
                    ProgressView("Chargement des statistiques...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack {
                        Text("Erreur: \(errorMessage)")
                            .foregroundColor(.red)
                        Button("Réessayer") {
                            Task {
                                await loadData()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        if let stats = statistiques {
                            StatCard(
                                title: "Chiffre d'affaires",
                                value: stats.totalCA.formattedEuros,
                                icon: "eurosign.circle.fill",
                                color: AppTheme.Colors.primary
                            )
                            
                            StatCard(
                                title: "Factures en attente",
                                value: "\(stats.facturesEnAttente)",
                                icon: "clock.fill",
                                color: AppTheme.Colors.statusSent
                            )
                            
                            StatCard(
                                title: "Factures en retard",
                                value: "\(stats.facturesEnRetard)",
                                icon: "exclamationmark.triangle.fill",
                                color: AppTheme.Colors.statusOverdue
                            )
                            
                            StatCard(
                                title: "Total factures",
                                value: "\(stats.totalFactures)",
                                icon: "doc.text.fill",
                                color: AppTheme.Colors.secondary
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    if !caParMois.isEmpty {
                        chartSection
                    }
                    
                    if !recentFactures.isEmpty {
                        recentFacturesSection
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
        .refreshable {
            await loadData()
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Tableau de bord")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Vue d'ensemble de votre activité")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Évolution du chiffre d'affaires")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CA par mois (année courante)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Simple bar chart representation
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(Array(caParMois.enumerated()), id: \.offset) { index, value in
                            VStack {
                                Rectangle()
                                    .fill(AppTheme.Colors.primary)
                                    .frame(width: 20, height: max(value / (caParMois.max() ?? 1) * 100, 2))
                                    .cornerRadius(2)
                                
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 120)
                }
                .padding()
            }
            .padding(.horizontal)
        }
    }
    
    private var recentFacturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Factures récentes")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(recentFactures.prefix(5), id: \.id) { facture in
                    RecentFactureCard(facture: facture)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let statistiquesResult = dependencyContainer.getStatistiquesUseCase.execute()
        async let facturesResult = dependencyContainer.fetchFacturesUseCase.execute()
        async let clientsResult = dependencyContainer.fetchClientsUseCase.execute()
        async let caParMoisResult = dependencyContainer.getCAParMoisUseCase.execute(annee: Calendar.current.component(.year, from: Date()))
        async let facturesParStatutResult = dependencyContainer.getFacturesParStatutUseCase.execute()
        
        let (statsRes, facturesRes, clientsRes, caRes, statutRes) = await (statistiquesResult, facturesResult, clientsResult, caParMoisResult, facturesParStatutResult)
        
        switch statsRes {
        case .success(let stats):
            statistiques = stats
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des statistiques: \(error.localizedDescription)"
        }
        
        switch facturesRes {
        case .success(let factures):
            recentFactures = Array(factures.sorted { $0.dateFacture > $1.dateFacture }.prefix(10))
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des factures: \(error.localizedDescription)"
        }
        
        switch clientsRes {
        case .success(let fetchedClients):
            clients = fetchedClients
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des clients: \(error.localizedDescription)"
        }
        
        switch caRes {
        case .success(let ca):
            caParMois = ca
        case .failure(let error):
            errorMessage = "Erreur lors du chargement du CA: \(error.localizedDescription)"
        }
        
        switch statutRes {
        case .success(let statuts):
            facturesParStatut = statuts
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des statuts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func clientName(for clientId: UUID) -> String {
        if let client = clients.first(where: { $0.id == clientId }) {
            return "\(client.nom) - \(client.entreprise)"
        }
        return "Client inconnu"
    }
}

struct StatCard: View {
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

struct RecentFactureCard: View {
    let facture: FactureDTO
    
    var body: some View {
        AppCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(facture.numero)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Client \(facture.clientId.uuidString.prefix(8))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(facture.dateFacture.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("0,00 €") // TODO: fix when lignes are available
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(facture.statutDisplay)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(facture.statutColor.opacity(0.2))
                        .foregroundColor(facture.statutColor)
                        .cornerRadius(4)
                }
            }
            .padding()
        }
    }
}

#Preview {
    SecureDashboardView()
        .environmentObject(DependencyContainer.shared)
}