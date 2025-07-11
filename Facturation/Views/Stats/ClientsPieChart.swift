import SwiftUI
import Charts

struct ClientsPieChart: View {
    let stats: [StatistiquesService_DTO.ClientStatistique]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Répartition du chiffre d'affaires (Top 5 clients)")
                .font(.headline)
                .padding(.bottom, 8)
            Chart(stats) { clientStat in
                SectorMark(
                    angle: .value("CA", clientStat.chiffreAffaires),
                    innerRadius: .ratio(0.6),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Client", clientStat.client.nom))
            }
            .chartLegend(position: .bottom)
            .frame(height: 300)
        }
        .padding()
        .background(Material.ultraThin)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}
