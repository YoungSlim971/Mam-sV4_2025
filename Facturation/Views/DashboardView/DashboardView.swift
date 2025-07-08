import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var dataService: DataService
    @StateObject private var statsService: StatistiquesService
    @State private var facturesRecentes: [FactureDTO] = []
    @State private var selectedInvoiceStatusFilter: StatutFacture? = nil
    @State private var showingSettings = false
    @State private var selectedPeriode: StatistiquesService.PeriodePredefinie = .trentejours

    init() {
        _statsService = StateObject(wrappedValue: StatistiquesService())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 9) {
                // En-tête
                DashboardHeaderSection()

                // Sélecteur de période
                Picker("Période", selection: $selectedPeriode) {
                    ForEach(statsService.periodes) { periode in
                        Text(periode.rawValue).tag(periode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Widgets
                VStack(spacing: 12) {
                    Text(" Inspiration aléatoire")
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    HStack(spacing: 20) {
                        QuoteWidgetView()
                            .frame(width: 350, height: 160)
                            .background(Color(.purple))
                            .cornerRadius(12)
                            .shadow(radius: 2)

                        SunsetImageWidgetView()
                            .frame(width: 350, height: 160)
                            .background(Color(.purple))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 12)

                // Cartes statistiques
                StatisticsSection(statsService: statsService)
                    .animation(.easeOut(duration: 0.5), value: statsService.caMensuel)

                // Graphiques et tendances
                ChartsSection(statsService: statsService)
                    .animation(.easeOut(duration: 0.5), value: statsService.caMensuel)
                    .animation(.easeOut(duration: 0.5), value: statsService.repartitionStatuts)
                   

                // Factures récentes
                RecentFacturesSection(factures: facturesRecentes, selectedInvoiceStatusFilter: $selectedInvoiceStatusFilter)

                // Actions rapides
                QuickActionsSection(showingSettings: $showingSettings)

                Spacer(minLength: 20)
            }
            .padding()
        }
        .task {
            if let interval = selectedPeriode.dateInterval {
                statsService.updateStatistiques(interval: interval, type: .clients)
            }
            facturesRecentes = dataService.factures.sorted { $0.dateFacture > $1.dateFacture }
        }
        .refreshable {
            if let interval = selectedPeriode.dateInterval {
                statsService.updateStatistiques(interval: interval, type: .clients)
            }
            facturesRecentes = dataService.factures.sorted { $0.dateFacture > $1.dateFacture }
        }
        .onChange(of: selectedPeriode) {
            if let interval = selectedPeriode.dateInterval {
                statsService.updateStatistiques(interval: interval, type: .clients)
            }
        }
    }
}

#Preview {
    DashboardView()
}
