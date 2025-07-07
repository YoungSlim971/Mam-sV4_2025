import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var dataService: DataService
    @StateObject private var statsService: StatistiquesService
    @State private var facturesRecentes: [FactureDTO] = []
    @State private var selectedInvoiceStatusFilter: StatutFacture? = nil
    @State private var showingSettings = false

    init() {
        _statsService = StateObject(wrappedValue: StatistiquesService())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // En-tête
                DashboardHeaderSection()

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
                StatisticsSection(statistiques: (
                    totalCA: statsService.caMensuel.values.reduce(0, +),
                    facturesEnAttente: statsService.repartitionStatuts[.envoyee, default: []].count,
                    facturesEnRetard: statsService.repartitionStatuts[.enRetard, default: []].count,
                    totalFactures: statsService.repartitionStatuts.values.reduce(0) { $0 + $1.count }
                ))
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
            statsService.updateStatistiques(interval: DateInterval(start: .distantPast, end: .distantFuture), type: .clients)
            facturesRecentes = dataService.factures.sorted { $0.dateFacture > $1.dateFacture }
        }
        .refreshable {
            statsService.updateStatistiques(interval: DateInterval(start: .distantPast, end: .distantFuture), type: .clients)
            facturesRecentes = dataService.factures.sorted { $0.dateFacture > $1.dateFacture }
        }
    }
}

#Preview {
    DashboardView()
}
