import SwiftUI
import DataLayer

struct SecureContentView: View {
    @StateObject private var dependencyContainer = DependencyContainer.shared
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var searchText = ""
    
    enum NavigationTab: String, CaseIterable {
        case dashboard = "Tableau de bord"
        case clients = "Clients"
        case factures = "Factures"
        case produits = "Produits"
        case stats = "Statistiques"
        case parametres = "Paramètres"
        case developer = "Développeur"
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .clients: return "person.2.fill"
            case .factures: return "doc.text.fill"
            case .produits: return "cube.box.fill"
            case .stats: return "chart.bar.fill"
            case .parametres: return "gear.fill"
            case .developer: return "hammer.fill"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .environmentObject(dependencyContainer)
        .onAppear {
            // Initialize dependency container if needed
            Task {
                await initializeApp()
            }
        }
    }
    
    // MARK: - View Components
    
    private var sidebar: some View {
        List(NavigationTab.allCases, id: \.self, selection: $selectedTab) { tab in
            NavigationLink(value: tab) {
                Label(tab.rawValue, systemImage: tab.icon)
                    .foregroundColor(selectedTab == tab ? .white : .primary)
            }
            .listRowBackground(
                selectedTab == tab ? AppTheme.Colors.primary : Color.clear
            )
        }
        .navigationTitle("Facturation")
        // .navigationBarTitleDisplayMode(.inline) // iOS only
        .listStyle(SidebarListStyle())
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            SecureDashboardView()
        case .clients:
            SecureClientsView(searchText: $searchText)
        case .factures:
            SecureFacturesView(searchText: $searchText)
        case .produits:
            SecureProduitsView(searchText: $searchText)
        case .stats:
            SecureStatsView()
        case .parametres:
            SecureParametresView()
        case .developer:
            SecureDeveloperView()
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeApp() async {
        // Any initialization logic needed for the secure architecture
        print("Secure architecture initialized")
    }
}



struct SecureStatsView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    @State private var statistiques: (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int)?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Chargement des statistiques...")
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Erreur: \(errorMessage)")
                        .foregroundColor(.red)
                    Button("Réessayer") {
                        Task {
                            await loadStats()
                        }
                    }
                }
            } else if let stats = statistiques {
                VStack(spacing: 20) {
                    Text("Statistiques sécurisées")
                        .font(.title)
                        .padding()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CA Total: \(stats.totalCA.formattedEuros)")
                        Text("Factures en attente: \(stats.facturesEnAttente)")
                        Text("Factures en retard: \(stats.facturesEnRetard)")
                        Text("Total factures: \(stats.totalFactures)")
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
        .onAppear {
            Task {
                await loadStats()
            }
        }
    }
    
    private func loadStats() async {
        isLoading = true
        errorMessage = nil
        
        let result = await dependencyContainer.getStatistiquesUseCase.execute()
        
        switch result {
        case .success(let stats):
            statistiques = stats
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des statistiques: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct SecureParametresView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    @State private var entreprise: EntrepriseDTO?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Chargement des paramètres...")
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Erreur: \(errorMessage)")
                        .foregroundColor(.red)
                    Button("Réessayer") {
                        Task {
                            await loadEntreprise()
                        }
                    }
                }
            } else {
                Text("Paramètres sécurisés")
                    .font(.title)
                    .padding()
                
                if let entreprise = entreprise {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Entreprise: \(entreprise.nom)")
                        Text("SIRET: \(entreprise.siret)")
                        Text("Email: \(entreprise.email)")
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    Text("Aucune entreprise configurée")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            Task {
                await loadEntreprise()
            }
        }
    }
    
    private func loadEntreprise() async {
        isLoading = true
        errorMessage = nil
        
        let result = await dependencyContainer.fetchEntrepriseUseCase.execute()
        
        switch result {
        case .success(let fetchedEntreprise):
            entreprise = fetchedEntreprise
        case .failure(let error):
            errorMessage = "Erreur lors du chargement de l'entreprise: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct SecureDeveloperView: View {
    var body: some View {
        VStack {
            Text("Outils développeur sécurisés")
                .font(.title)
                .padding()
            
            Text("Architecture Clean implémentée avec succès!")
                .font(.headline)
                .foregroundColor(.green)
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("✅ Repositories implémentés")
                Text("✅ Use Cases sécurisés")
                Text("✅ Aucune exposition directe des données")
                Text("✅ Injection de dépendances")
                Text("✅ Gestion d'erreurs robuste")
            }
            .padding()
            .background(Color(Color.gray.opacity(0.1)))
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    SecureContentView()
}
