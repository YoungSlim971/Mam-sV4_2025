import SwiftUI
import Charts
import DataLayer

struct StatsView: View {
    @ObservedObject private var dataService = DataService.shared
    @StateObject private var statistiquesService: StatistiquesService_DTO

    @State private var statistiqueType: StatistiqueType = .clients
    @State private var periode: PeriodePredefinie
    @State private var dateDebut: Date
    @State private var dateFin: Date
    @State private var selectedClient: ClientDTO? = nil
    @State private var selectedProduit: ProduitDTO? = nil
    @Environment(\.self) private var environment

    init() {
        let now = Date()
        _periode = State(initialValue: .sixMois)
        _dateFin = State(initialValue: now)
        _dateDebut = State(initialValue: Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now)
        _statistiquesService = StateObject(wrappedValue: StatistiquesService_DTO())
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Section Header
                    headerSection
                        .id("top")
                    
                    // MARK: - Evolution CA Section
                    evolutionSection
                    
                    // MARK: - Dynamic Sections (Clients/Produits)
                    dynamicSections
                    
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.windowBackgroundColor))
            .navigationTitle("Statistiques")
            .onAppear(perform: updateStatistiques)
            .onChange(of: statistiqueType) { _, _ in 
                updateStatistiques()
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
            .onChange(of: periode) { _, newValue in
                if let interval = newValue.dateInterval {
                    dateDebut = interval.start
                    dateFin = interval.end
                }
                updateStatistiques()
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
            .onChange(of: selectedClient) { _, _ in updateStatistiques() }
            .onChange(of: selectedProduit) { _, _ in updateStatistiques() }
            .onChange(of: dateDebut) { _, _ in
                if periode == .personnalise { updateStatistiques() }
            }
            .onChange(of: dateFin) { _, _ in
                if periode == .personnalise { updateStatistiques() }
            }
            .onReceive(dataService.objectWillChange) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    updateStatistiques()
                }
            }
            .onKeyPress(.space) {
                resetFilters()
                return .handled
            }
            .onKeyPress(.escape) {
                clearSelections()
                return .handled
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatsFiltersView(
                    type: $statistiqueType,
                    periode: $periode,
                    dateDebut: $dateDebut,
                    dateFin: $dateFin,
                    selectedClient: $selectedClient,
                    selectedProduit: $selectedProduit,
                    clients: dataService.clients,
                    produits: dataService.produits,
                    resetAction: resetFilters
                )
                
                Spacer()
                
                // Client indicator (survol client)
                if let selectedClient = selectedClient {
                    clientIndicator(selectedClient)
                }
            }
            
            Divider()
        }
        .padding(.top)
    }
    
    // MARK: - Evolution Section
    
    private var evolutionSection: some View {
        EvolutionCASection(
            stats: evolutionStats,
            type: statistiqueType
        )
    }
    
    // MARK: - Dynamic Sections
    
    private var dynamicSections: some View {
        Group {
            switch statistiqueType {
            case .clients:
                TopClientsSection(
                    clients: statistiquesService.topClients,
                    selectedClient: $selectedClient
                )
                
            case .produits:
                TopProduitsSection(
                    produits: statistiquesService.topProduits,
                    selectedProduit: $selectedProduit
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func clientIndicator(_ client: ClientDTO) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(StatsColorProvider.accessibleColorForClient(id: client.id, environment: environment))
                .frame(width: 12, height: 12)
            
            Text(client.raisonSociale)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: selectedClient?.id)
    }
    
    // MARK: - Computed Properties
    
    private var evolutionStats: [MonthStat] {
        // Convertir les données de StatistiquesService_DTO en MonthStat
        return statistiquesService.evolutionVentes.map { point in
            MonthStat(
                date: point.date,
                valeur: point.montant
            )
        }
    }
    
    // MARK: - Functions
    
    private func updateStatistiques() {
        let interval: DateInterval
        if periode == .personnalise {
            interval = DateInterval(start: dateDebut, end: dateFin)
        } else if let predefinedInterval = periode.dateInterval {
            interval = predefinedInterval
        } else {
            // Fallback
            interval = DateInterval(start: dateDebut, end: dateFin)
        }

        switch statistiqueType {
        case .clients:
            statistiquesService.updateStatistiques(
                interval: interval,
                type: .clients,
                clientId: selectedClient?.id
            )
        case .produits:
            statistiquesService.updateStatistiques(
                interval: interval,
                type: .produits,
                produitId: selectedProduit?.id
            )
        }
    }
    
    private func resetFilters() {
        statistiqueType = .clients
        selectedClient = nil
        selectedProduit = nil
        periode = .sixMois
        if let interval = periode.dateInterval {
            dateDebut = interval.start
            dateFin = interval.end
        }
        updateStatistiques()
    }
    
    private func clearSelections() {
        selectedClient = nil
        selectedProduit = nil
        updateStatistiques()
    }
}


// MARK: - Preview

#if DEBUG
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatsView()
                .environmentObject(DataService.shared)
        }
        .frame(width: 1000, height: 700)
    }
}
#endif
