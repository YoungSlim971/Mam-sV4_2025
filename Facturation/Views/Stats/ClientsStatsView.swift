import SwiftUI
import Charts
import DataLayer

struct ClientsStatsView: View {
    @ObservedObject var statistiquesService: StatistiquesService
    @Binding var selectedClient: ClientDTO?

    var body: some View {
        HSplitView {
            TopClientsChart(
                stats: Array(statistiquesService.topClients.prefix(5)),
                selectedClient: $selectedClient
            )
            .frame(minWidth: 300, idealWidth: 500, maxWidth: .infinity)

            ClientsPieChart(stats: Array(statistiquesService.topClients.prefix(5)))
                .frame(minWidth: 300, idealWidth: 500, maxWidth: .infinity)
        }
    }
}
