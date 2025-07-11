import SwiftUI
import Charts
import AppKit

struct MonthlyRevenueChartView: View {
    @ObservedObject var statsService: StatistiquesService_DTO
    @State private var selectedMonth: String? = nil

    var body: some View {
        VStack(alignment: .leading) {
            headerSection
            
            if statsService.caMensuel.isEmpty {
                emptyStateView
            } else {
                chartContentView
                evolutionSection
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private var headerSection: some View {
        Text("Chiffre d'Affaires Mensuel")
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.bottom, 5)
    }
    
    private var emptyStateView: some View {
        Text("Aucune donnée de chiffre d'affaires pour le moment.")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
    }
    
    private var chartContentView: some View {
        Chart(chartData, id: \.key) { month, total in
            BarMark(
                x: .value("Mois", month),
                y: .value("CA", total)
            )
            .foregroundStyle(Color.green)
            .annotation(position: .top) {
                if selectedMonth == month {
                    Text("\(total.euroFormatted)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel() {
                    if let doubleValue = value.as(Double.self) {
                        Text(doubleValue.euroFormatted)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            chartOverlayContent(proxy: proxy)
        }
        .frame(height: 120)
    }
    
    private var chartData: [(key: String, value: Double)] {
        statsService.caMensuel.sorted(by: { $0.key < $1.key })
    }
    
    private func chartOverlayContent(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let location = value.location
                            if let monthString: String = proxy.value(atX: location.x) {
                                selectedMonth = monthString
                            }
                        }
                        .onEnded { _ in
                            selectedMonth = nil
                        }
                )
        }
    }
    
    private var evolutionSection: some View {
        HStack {
            Text("Évolution:")
            Text(String(format: "%.2f%%", statsService.evolutionCAMensuel))
                .foregroundColor(evolutionColor)
            Image(systemName: evolutionIcon)
                .foregroundColor(evolutionColor)
        }
        .font(.caption)
        .padding(.top, 5)
    }
    
    private var evolutionColor: Color {
        statsService.evolutionCAMensuel >= 0 ? .green : .red
    }
    
    private var evolutionIcon: String {
        statsService.evolutionCAMensuel >= 0 ? "arrow.up" : "arrow.down"
    }
}

#Preview {
    MonthlyRevenueChartView(statsService: StatistiquesService_DTO())
}