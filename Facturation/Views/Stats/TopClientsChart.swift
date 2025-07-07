import SwiftUI
import Charts

struct TopClientsChart: View {
    var stats: [StatistiquesService.ClientStatistique]
    @Binding var selectedClient: ClientDTO?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Clients par Chiffre d'Affaires")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)

            if stats.isEmpty {
                Text("Aucune donnée pour cette période")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .padding()
            } else {
                Chart(stats) { stat in
                    BarMark(
                        x: .value("Client", stat.nom),
                        y: .value("Montant", stat.total)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .annotation(position: .top) {
                        Text(stat.total, format: .currency(code: "EUR"))
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel() {
                            Text(value.as(String.self) ?? "")
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
                .padding()
                .frame(minHeight: 200)
            }
        }
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}
