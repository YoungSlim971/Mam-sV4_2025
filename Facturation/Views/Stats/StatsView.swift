import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject private var dataService = DataService.shared
    @StateObject private var statistiquesService: StatistiquesService

    @State private var statistiqueType: StatistiqueType = .clients
    @State private var periode: PeriodePredefinie
    @State private var dateDebut: Date
    @State private var dateFin: Date
    @State private var selectedClient: ClientDTO? = nil
    @State private var selectedProduit: ProduitDTO? = nil

    init() {
        let now = Date()
        _periode = State(initialValue: .sixMois)
        _dateFin = State(initialValue: now)
        _dateDebut = State(initialValue: Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now)
        _statistiquesService = StateObject(wrappedValue: StatistiquesService())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - Barre de filtres
            StatsFiltersView(type: $statistiqueType,
                             periode: $periode,
                             dateDebut: $dateDebut,
                             dateFin: $dateFin,
                             selectedClient: $selectedClient,
                             selectedProduit: $selectedProduit,
                             clients: dataService.clients,
                             produits: dataService.produits,
                             resetAction: resetFilters)

            EvolutionVentesChart(
                stats: statistiquesService.evolutionVentes,
                title: evolutionTitle
            )

            Group {
                switch statistiqueType {
                case .clients:
                    ClientsStatsView(
                        statistiquesService: statistiquesService,
                        selectedClient: $selectedClient
                    )
                case .produits:
                    ProduitsStatsView(
                        statistiquesService: statistiquesService,
                        selectedProduit: $selectedProduit
                    )
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Statistiques")
        .onAppear(perform: updateStatistiques)
        .onChange(of: statistiqueType) { _, _ in updateStatistiques() }
        .onChange(of: selectedClient) { _, _ in updateStatistiques() }
        .onChange(of: selectedProduit) { _, _ in updateStatistiques() }
        .onReceive(dataService.objectWillChange) { _ in
            // Rafraîchir les statistiques quand les données changent
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                updateStatistiques()
            }
        }
        .onChange(of: periode) { _, newValue in
            if let interval = newValue.dateInterval {
                dateDebut = interval.start
                dateFin = interval.end
            }
            updateStatistiques()
        }
        .onChange(of: dateDebut) { _, _ in
            if periode == .personnalise { updateStatistiques() }
        }
        .onChange(of: dateFin) { _, _ in
            if periode == .personnalise { updateStatistiques() }
        }
    }


    // MARK: - Fonctions

    private func updateStatistiques() {
        let interval = DateInterval(start: dateDebut, end: dateFin)

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

    private var evolutionTitle: String {
        let periodText: String
        if periode == .personnalise {
            periodText = "du \(dateDebut.frenchFormatted) au \(dateFin.frenchFormatted)"
        } else {
            periodText = "sur \(periode.rawValue)"
        }

        switch statistiqueType {
        case .clients:
            if let client = selectedClient {
                return "Évolution du CA pour \(client.nomCompletClient) \(periodText)"
            } else {
                return "Évolution du chiffre d'affaires \(periodText)"
            }
        case .produits:
            if let produit = selectedProduit {
                return "Évolution des ventes pour \(produit.designation) \(periodText)"
            } else {
                return "Évolution des quantités vendues \(periodText)"
            }
        }
    }
}


// MARK: - Preview

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
