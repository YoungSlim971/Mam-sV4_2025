import SwiftUI
import Charts
import DataLayer

struct EvolutionCASection: View {
    let stats: [MonthStat]
    let type: StatistiqueType
    @State private var hoveredMonth: Date?
    
    private var sortedStats: [MonthStat] {
        stats.sorted { $0.date < $1.date }
    }
    
    private var evolutionColor: Color {
        calculateEvolutionColor()
    }
    
    private var evolutionPercentage: Double {
        calculateEvolutionPercentage()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            
            if sortedStats.isEmpty {
                emptyStateView
            } else {
                chartView
                summaryView
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Évolution du CA")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(type == .clients ? "Par clients" : "Par produits")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            evolutionIndicator
        }
    }
    
    private var evolutionIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: evolutionIcon)
                .font(.caption)
                .foregroundColor(evolutionColor)
            
            Text(evolutionText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(evolutionColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(evolutionColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart(sortedStats, id: \.id) { stat in
            LineMark(
                x: .value("Mois", stat.date),
                y: .value("Montant", stat.valeur)
            )
            .foregroundStyle(evolutionColor)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Mois", stat.date),
                y: .value("Montant", stat.valeur)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [evolutionColor.opacity(0.3), evolutionColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            
            if let hoveredMonth = hoveredMonth, stat.date == hoveredMonth {
                PointMark(
                    x: .value("Mois", stat.date),
                    y: .value("Montant", stat.valeur)
                )
                .foregroundStyle(evolutionColor)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: .month)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let dateValue = value.as(Date.self) {
                        Text(formatMonthLabel(dateValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String.compactFormatted(doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .frame(height: 200)
        .onHover { isHovering in
            if !isHovering {
                hoveredMonth = nil
            }
        }
        .accessibilityLabel("Graphique d'évolution du chiffre d'affaires")
        .accessibilityLabel("Graphique linéaire montrant l'évolution mensuelle")
    }
    
    // MARK: - Summary View
    
    private var summaryView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total période")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String.euroFormatted(totalAmount))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(StatsColorProvider.chartPrimary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Moyenne mensuelle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String.euroFormatted(averageAmount))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Aucune donnée d'évolution")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Les données d'évolution apparaîtront ici une fois que vous aurez des factures sur plusieurs mois.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Helper Methods
    
    private func calculateEvolutionColor() -> Color {
        guard sortedStats.count >= 2 else { return .gray }
        
        let lastAmount = sortedStats.last?.valeur ?? 0
        let previousAmount = sortedStats.dropLast().last?.valeur ?? 0
        
        if lastAmount > previousAmount {
            return .green // Croissance
        } else if lastAmount < previousAmount {
            return .red // Baisse
        } else {
            return .gray // Stable
        }
    }
    
    private func calculateEvolutionPercentage() -> Double {
        guard sortedStats.count >= 2 else { return 0 }
        
        let lastAmount = sortedStats.last?.valeur ?? 0
        let previousAmount = sortedStats.dropLast().last?.valeur ?? 0
        
        if previousAmount == 0 {
            return lastAmount > 0 ? 100 : 0
        }
        
        return ((lastAmount - previousAmount) / previousAmount) * 100
    }
    
    private var evolutionIcon: String {
        if evolutionPercentage > 0 {
            return "arrow.up.right"
        } else if evolutionPercentage < 0 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
    
    private var evolutionText: String {
        let percentage = abs(evolutionPercentage)
        if percentage == 0 {
            return "Stable"
        } else {
            let sign = evolutionPercentage > 0 ? "+" : "-"
            return "\(sign)\(String.percentageFormatted(percentage / 100))"
        }
    }
    
    private var totalAmount: Double {
        sortedStats.reduce(0) { $0 + $1.valeur }
    }
    
    private var averageAmount: Double {
        guard !sortedStats.isEmpty else { return 0 }
        return totalAmount / Double(sortedStats.count)
    }
    
    private func formatMonthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        
        // Si on a beaucoup de mois, on affiche juste le mois
        if sortedStats.count > 6 {
            formatter.dateFormat = "MMM"
        } else {
            formatter.dateFormat = "MMM yy"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct EvolutionCASection_Previews: PreviewProvider {
    static let sampleStats: [MonthStat] = [
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, valeur: 15000),
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, valeur: 18500),
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, valeur: 22000),
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, valeur: 19500),
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, valeur: 25000),
        MonthStat(date: Date(), valeur: 28500),
        
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, valeur: 850),
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, valeur: 920),
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, valeur: 1100),
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, valeur: 980),
        MonthStat(date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, valeur: 1250),
        MonthStat(date: Date(), valeur: 1380),
    ]
    
    static var previews: some View {
        VStack(spacing: 20) {
            EvolutionCASection(stats: sampleStats, type: .clients)
            EvolutionCASection(stats: sampleStats, type: .produits)
        }
        .frame(width: 500)
        .padding()
    }
}
#endif