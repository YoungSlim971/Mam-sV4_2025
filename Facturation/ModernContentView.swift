import SwiftUI
import Charts
import DataLayer


struct ModernContentView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            DetailView(selectedTab: selectedTab, searchText: $searchText)
                .navigationSplitViewColumnWidth(min: 800, ideal: 1000)
        }
        .searchable(text: $searchText, placement: .automatic)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                ToolbarActions(selectedTab: selectedTab)
            }
        }
        .task {
            // Charger les données persistées au démarrage de l'app
            await dataService.fetchData()
            print("🔄 Données chargées au démarrage: \(dataService.clients.count) clients, \(dataService.factures.count) factures, \(dataService.produits.count) produits")
        }
    }
}

// MARK: - Navigation Tab Enum
enum NavigationTab: String, CaseIterable {
    case dashboard = "Tableau de Bord"
    case factures = "Factures"
    case clients = "Clients"
    case produits = "Produits"
    case statistiques = "Statistiques"
    case parametres = "Paramètres"
    case developpeur = "Développeur"

    var systemImage: String {
        switch self {
            case .dashboard: return "house.fill"
            case .factures: return "doc.text.fill"
            case .clients: return "person.2.fill"
            case .produits: return "tag.fill"
            case .statistiques: return "chart.bar.doc.horizontal"
            case .parametres: return "gear"
            case .developpeur: return "hammer"
        }
    }

    var color: Color {
        switch self {
            case .dashboard: return .blue
            case .factures: return .green
            case .clients: return .orange
            case .produits: return .purple
            case .statistiques: return .pink
            case .parametres: return .gray
            case .developpeur: return .brown
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Binding var selectedTab: NavigationTab

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.blue.gradient)

                Text("Facturation Pro")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Gestion simplifiée")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)

            Divider()

            // Navigation List
            List(NavigationTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.systemImage)
                    .foregroundColor(selectedTab == tab ? tab.color : .primary)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
            }
            .listStyle(SidebarListStyle())

            Spacer()

            // Footer
            VStack(spacing: 8) {
                Divider()

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .frame(minWidth: 200)
    }
}

// MARK: - Detail View
struct DetailView: View {
    let selectedTab: NavigationTab
    @Binding var searchText: String
    @State private var isAuthenticatedForDeveloper: Bool = false

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .onChange(of: selectedTab) { oldTab, newTab in
                if oldTab == .developpeur && newTab != .developpeur {
                    isAuthenticatedForDeveloper = false // Reset authentication when leaving developer tab
                }
            }
    }

    // MARK: - Private Builder

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .factures:
            FacturesView(searchText: $searchText)
        case .clients:
            ClientsView(searchText: $searchText)
        case .produits:
            ProduitsView(searchText: $searchText)
        case .statistiques:
            StatsView()
        case .parametres:
            ParametresView(onClose: {})
        case .developpeur:
            if isAuthenticatedForDeveloper {
                DeveloperView()
            } else {
                SecureLoginView {
                    isAuthenticatedForDeveloper = true
                }
            }
        }
    }
}

// MARK: - Toolbar Actions
struct ToolbarActions: View {
    let selectedTab: NavigationTab
    @State private var showingNewFacture = false
    @State private var showingNewClient = false

    var body: some View {
        HStack {
            switch selectedTab {
                case .factures:
                    Button(action: { showingNewFacture = true }) {
                        Label("Nouvelle Facture", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                case .clients:
                    Button(action: { showingNewClient = true }) {
                        Label("Nouveau Client", systemImage: "person.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)

                default:
                    EmptyView()
            }
        }
        .sheet(isPresented: $showingNewFacture) {
            AddFactureView()
        }
        .sheet(isPresented: $showingNewClient) {
            AddClientView(onCreate: { _ in
                showingNewClient = false
            })
        }
    }
}

#Preview {
    ModernContentView()
        .environmentObject(DataService.shared)
}


struct StatistiquesDashboardView: View {
    @StateObject private var statistiquesService: StatistiquesService
    @State private var selectedType: StatistiquesService.StatistiqueType = .clients
    @State private var selectedPeriode: StatistiquesService.PeriodePredefinie = .troisMois
    @State private var selectedClient: UUID?
    @State private var selectedProduit: UUID?
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    
    // Pour les données de ton DataService
    @EnvironmentObject private var dataService: DataService
    
    init(dataService: DataService) {
        self._statistiquesService = StateObject(wrappedValue: StatistiquesService(dataService: dataService))
    }
    
    var currentInterval: DateInterval {
        if selectedPeriode == .personnalise {
            return DateInterval(start: customStartDate, end: customEndDate)
        }
        return selectedPeriode.dateInterval ?? DateInterval(start: Date(), end: Date())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header avec titre
                    headerSection
                    
                    // Contrôles de filtrage
                    controlsSection
                    
                    // Métriques principales
                    metricsSection
                    
                    // Graphiques principaux
                    chartsSection
                    
                    // Section détaillée selon le type sélectionné
                    detailSection
                }
                .padding()
            }
            .navigationTitle("Statistiques")
        }
        .onAppear {
            updateStatistiques()
        }
        .onChange(of: selectedType) { _, _ in updateStatistiques() }
        .onChange(of: selectedPeriode) { _, _ in updateStatistiques() }
        .onChange(of: selectedClient) { _, _ in updateStatistiques() }
        .onChange(of: selectedProduit) { _, _ in updateStatistiques() }
        .onChange(of: customStartDate) { _, _ in
            if selectedPeriode == .personnalise { updateStatistiques() }
        }
        .onChange(of: customEndDate) { _, _ in
            if selectedPeriode == .personnalise { updateStatistiques() }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tableau de Bord")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Analyse des performances de votre activité")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Type de statistiques
            VStack(alignment: .leading, spacing: 8) {
                Text("Type d'analyse")
                    .font(.headline)
                
                Picker("Type", selection: $selectedType) {
                    ForEach(statistiquesService.typesDispo) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Période
            VStack(alignment: .leading, spacing: 8) {
                Text("Période")
                    .font(.headline)
                
                Picker("Période", selection: $selectedPeriode) {
                    ForEach(statistiquesService.periodes) { periode in
                        Text(periode.rawValue).tag(periode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Dates personnalisées
            if selectedPeriode == .personnalise {
                HStack(spacing: 20) {
                    DatePicker("Du", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("Au", selection: $customEndDate, displayedComponents: .date)
                }
            }
            
            // Filtres spécifiques
            if selectedType == .clients && !dataService.clients.isEmpty {
                clientPicker
            } else if selectedType == .produits && !dataService.produits.isEmpty {
                produitPicker
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var clientPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client spécifique (optionnel)")
                .font(.headline)
            
            Picker("Client", selection: $selectedClient) {
                Text("Tous les clients").tag(UUID?.none)
                ForEach(dataService.clients, id: \.id) { client in
                    Text(client.nomCompletClient).tag(UUID?.some(client.id))
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var produitPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Produit spécifique (optionnel)")
                .font(.headline)
            
            Picker("Produit", selection: $selectedProduit) {
                Text("Tous les produits").tag(UUID?.none)
                ForEach(dataService.produits, id: \.id) { produit in
                    Text(produit.designation).tag(UUID?.some(produit.id))
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    // MARK: - Metrics Section
    private struct MetricTrend {
        let value: Double
        let text: String
        let icon: String
        let color: Color
    }

    private var metricsSection: some View {
        // Calcul du trend du chiffre d'affaires
        let evolutionCA = statistiquesService.evolutionCAMensuel
        let caTrend = MetricTrend(
            value: evolutionCA,
            text: String(format: "%.1f%%", abs(evolutionCA)),
            icon: evolutionCA >= 0 ? "arrow.up" : "arrow.down",
            color: evolutionCA >= 0 ? .green : .red
        )
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Chiffre d'Affaires",
                value: statistiquesService.chiffreAffaires(
                    interval: currentInterval,
                    for: selectedClient,
                    produitId: selectedProduit
                ).euroFormatted,
                icon: "eurosign.circle.fill",
                color: .blue,
                trend: caTrend
            )
            
            MetricCard(
                title: selectedType == .clients ? "Top Clients" : "Top Produits",
                value: selectedType == .clients ?
                    "\(statistiquesService.topClients.count)" :
                    "\(statistiquesService.topProduits.count)",
                icon: selectedType == .clients ? "person.2.fill" : "cube.box.fill",
                color: .green,
                trend: nil
            )
            
            MetricCard(
                title: "Délai Paiement",
                value: "\(statistiquesService.delaisPaiementMoyen) jours",
                icon: "calendar.badge.clock",
                color: .orange,
                trend: nil
            )
        }
    }
    
    // MARK: - Charts Section
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Évolution dans le temps")
                .font(.headline)
            
            if !statistiquesService.evolutionVentes.isEmpty {
                Chart(statistiquesService.evolutionVentes) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Montant", point.montant)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Montant", point.montant)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
            } else {
                ContentUnavailableView(
                    "Aucune donnée",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Pas de données pour la période sélectionnée")
                )
                .frame(height: 250)
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Detail Section
    @ViewBuilder
    private var detailSection: some View {
        if selectedType == .clients {
            clientsDetailSection
        } else {
            produitsDetailSection
        }
    }
    
    private var clientsDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Clients")
                .font(.headline)
            
            if statistiquesService.topClients.isEmpty {
                ContentUnavailableView(
                    "Aucun client",
                    systemImage: "person.2",
                    description: Text("Aucune donnée client pour cette période")
                )
            } else {
                ForEach(Array(statistiquesService.topClients.prefix(10).enumerated()), id: \.element.id) { index, client in
                    HStack {
                        // Position
                        Text("\(index + 1)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        // Nom du client
                        Text(client.nom)
                            .font(.body)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Total
                        Text(client.total.euroFormatted)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(index < 3 ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var produitsDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Produits")
                    .font(.headline)
                
                Spacer()
                
                // Toggle entre CA et quantité
                Text("Par quantité vendues")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if statistiquesService.topProduits.isEmpty {
                ContentUnavailableView(
                    "Aucun produit",
                    systemImage: "cube.box",
                    description: Text("Aucune donnée produit pour cette période")
                )
            } else {
                ForEach(Array(statistiquesService.topProduits.prefix(10).enumerated()), id: \.element.id) { index, produit in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // Position
                            Text("\(index + 1)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .frame(width: 30)
                            
                            // Nom du produit
                            Text(produit.nom)
                                .font(.body)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Quantité
                            Text("\(produit.quantite.formatted()) unités")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Spacer()
                            Text("CA: \(produit.chiffreAffaires.euroFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(produit.nombreVentes) ventes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(index < 3 ? Color.green.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
// MARK: - Helper Methods
private func updateStatistiques() {
    statistiquesService.updateStatistiques(
        interval: currentInterval,
        type: selectedType,
        clientId: selectedClient,
        produitId: selectedProduit
    )
}

// MARK: - MetricCard View (adaptation pour trend optionnel)
private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: MetricTrend?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .foregroundColor(trend.color)
                        .font(.caption)
                    Text(trend.text)
                        .foregroundColor(trend.color)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}
}



