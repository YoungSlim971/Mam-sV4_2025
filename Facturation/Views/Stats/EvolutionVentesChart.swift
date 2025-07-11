import SwiftUI
import Charts

struct EvolutionVentesChart: View {
    var stats: [StatistiquesService_DTO.PointStatistique]
    var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)

            if stats.isEmpty {
                Text("Aucune donnée pour cette période")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .padding()
            } else {
                Chart(stats) { pointStat in
                    LineMark(
                        x: .value("Mois", pointStat.date, unit: .month),
                        y: .value("Montant", pointStat.montant)
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Mois", pointStat.date, unit: .month),
                        y: .value("Montant", pointStat.montant)
                    )
                    .annotation(position: .top) {
                        Text(pointStat.montant, format: .currency(code: "EUR"))
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
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
