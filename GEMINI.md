# GEMINI.md     



exemple de graphique a intégré ( a decouper en plusieurs partie si possible ) 


import SwiftUI
import Charts

// MARK: - Data Models
struct OrderData {
    let date: Date
    let clients: [String: Double]
    let products: [String: [String: Double]]
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let period: String
    let value: Double
    let category: String
}

// MARK: - Dashboard View
struct DashboardView: View {
    @State private var viewMode: ViewMode = .clients
    @State private var selectedClient = "Restaurant Le Gourmand"
    @State private var timePeriod: TimePeriod = .twelveMonths
    @State private var ordersData: [OrderData] = []
    
    enum ViewMode: String, CaseIterable {
        case clients = "Totaux par client"
        case products = "Produits par client"
    }
    
    enum TimePeriod: Int, CaseIterable {
        case oneMonth = 1
        case threeMonths = 3
        case sixMonths = 6
        case twelveMonths = 12
        
        var title: String {
            switch self {
            case .oneMonth: return "Dernier mois"
            case .threeMonths: return "3 derniers mois"
            case .sixMonths: return "6 derniers mois"
            case .twelveMonths: return "12 derniers mois"
            }
        }
    }
    
    let clients = [
        "Restaurant Le Gourmand", "Épicerie Bio Nature", "Café des Amis",
        "Boulangerie Martin", "Hôtel Grand Parc", "Cantine Scolaire"
    ]
    
    let products = [
        "Pommes", "Tomates", "Carottes", "Bananes", "Courgettes",
        "Poivrons", "Oranges", "Salade", "Concombres", "Fraises"
    ]
    
    let colors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink,
        .yellow, .cyan, .indigo, .mint
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Controls
                    controlsView
                    
                    // Chart
                    chartView
                    
                    // Statistics
                    statisticsView
                }
                .padding()
            }
            .navigationTitle("Tableau de Bord")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            generateMockData()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Commandes Fruits & Légumes")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Analyse des ventes et commandes")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Controls View
    private var controlsView: some View {
        VStack(spacing: 16) {
            // View Mode Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Mode de visualisation")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Client Picker (only in products mode)
            if viewMode == .products {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Client sélectionné")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Client", selection: $selectedClient) {
                        ForEach(clients, id: \.self) { client in
                            Text(client).tag(client)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Time Period Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Période")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Période", selection: $timePeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Chart View
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartTitle)
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(chartData) { dataPoint in
                LineMark(
                    x: .value("Période", dataPoint.period),
                    y: .value("Valeur", dataPoint.value)
                )
                .foregroundStyle(by: .value("Catégorie", dataPoint.category))
                .symbol(by: .value("Catégorie", dataPoint.category))
            }
            .frame(height: 300)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(angle: .degrees(-45))
                }
            }
            .chartLegend(position: .bottom, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Statistics View
    private var statisticsView: some View {
        HStack(spacing: 16) {
            StatisticCard(
                title: "Total période",
                value: totalPeriodValue,
                unit: viewMode == .clients ? "€" : "kg",
                color: .blue
            )
            
            StatisticCard(
                title: "Moyenne",
                value: averageValue,
                unit: viewMode == .clients ? "€" : "kg",
                color: .green
            )
            
            StatisticCard(
                title: "Points",
                value: String(chartData.count / (viewMode == .clients ? clients.count : products.count)),
                unit: "",
                color: .purple
            )
        }
    }
    
    // MARK: - Computed Properties
    private var filteredData: [OrderData] {
        let cutoffDate = Calendar.current.date(byAdding: .month, value: -timePeriod.rawValue, to: Date()) ?? Date()
        return ordersData.filter { $0.date >= cutoffDate }
    }
    
    private var chartData: [ChartDataPoint] {
        let aggregatedData = aggregateData()
        var dataPoints: [ChartDataPoint] = []
        
        if viewMode == .clients {
            for data in aggregatedData {
                for client in clients {
                    if let value = data.clients[client] {
                        dataPoints.append(ChartDataPoint(
                            period: data.period,
                            value: value,
                            category: client
                        ))
                    }
                }
            }
        } else {
            for data in aggregatedData {
                for product in products {
                    if let clientProducts = data.products[selectedClient],
                       let value = clientProducts[product] {
                        dataPoints.append(ChartDataPoint(
                            period: data.period,
                            value: value,
                            category: product
                        ))
                    }
                }
            }
        }
        
        return dataPoints
    }
    
    private var chartTitle: String {
        if viewMode == .clients {
            return "Évolution du chiffre d'affaires par client (\(timePeriod.title.lowercased()))"
        } else {
            return "Évolution des quantités - \(selectedClient) (\(timePeriod.title.lowercased()))"
        }
    }
    
    private var totalPeriodValue: String {
        let total = chartData.reduce(0) { $0 + $1.value }
        return String(format: "%.0f", total)
    }
    
    private var averageValue: String {
        let uniquePeriods = Set(chartData.map { $0.period }).count
        let total = chartData.reduce(0) { $0 + $1.value }
        let average = uniquePeriods > 0 ? total / Double(uniquePeriods) : 0
        return String(format: "%.0f", average)
    }
    
    // MARK: - Helper Methods
    private func aggregateData() -> [(period: String, clients: [String: Double], products: [String: [String: Double]])] {
        var grouped: [String: (clients: [String: Double], products: [String: [String: Double]])] = [:]
        
        for item in filteredData {
            let key: String
            if timePeriod.rawValue <= 3 {
                // Par semaine pour 1-3 mois
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: item.date)?.start ?? item.date
                key = formatter.string(from: weekStart)
            } else {
                // Par mois pour 6-12 mois
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                key = formatter.string(from: item.date)
            }
            
            if grouped[key] == nil {
                grouped[key] = (clients: [:], products: [:])
            }
            
            // Agrégation des totaux clients
            for (client, amount) in item.clients {
                grouped[key]?.clients[client] = (grouped[key]?.clients[client] ?? 0) + amount
            }
            
            // Agrégation des quantités produits
            for (client, products) in item.products {
                if grouped[key]?.products[client] == nil {
                    grouped[key]?.products[client] = [:]
                }
                for (product, qty) in products {
                    grouped[key]?.products[client]?[product] = (grouped[key]?.products[client]?[product] ?? 0) + qty
                }
            }
        }
        
        return grouped.map { (period: formatPeriod($0.key), clients: $0.value.clients, products: $0.value.products) }
            .sorted { $0.period < $1.period }
    }
    
    private func formatPeriod(_ period: String) -> String {
        let formatter = DateFormatter()
        
        if period.contains("-") && period.count == 10 {
            // Format semaine
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: period) {
                formatter.dateFormat = "dd MMM"
                formatter.locale = Locale(identifier: "fr_FR")
                return formatter.string(from: date)
            }
        } else if period.count == 7 {
            // Format mois
            formatter.dateFormat = "yyyy-MM"
            if let date = formatter.date(from: period + "-01") {
                formatter.dateFormat = "MMM yyyy"
                formatter.locale = Locale(identifier: "fr_FR")
                return formatter.string(from: date)
            }
        }
        
        return period
    }
    
    private func generateMockData() {
        var data: [OrderData] = []
        let calendar = Calendar.current
        
        for i in 0..<365 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            var clients: [String: Double] = [:]
            var products: [String: [String: Double]] = [:]
            
            for client in self.clients {
                // Variation saisonnière et tendance pour chaque client
                let baseAmount = Double.random(in: 200...1000)
                let seasonalFactor = 1 + 0.3 * sin(Double(i) / 365 * 2 * .pi)
                let weeklyVariation = 1 + 0.2 * sin(Double(i) / 7 * 2 * .pi)
                let randomFactor = Double.random(in: 0.8...1.2)
                
                clients[client] = baseAmount * seasonalFactor * weeklyVariation * randomFactor
                
                // Données par produit pour chaque client
                var clientProducts: [String: Double] = [:]
                for product in self.products {
                    let baseQty = Double.random(in: 10...60)
                    let productVariation = Double.random(in: 0.7...1.3)
                    clientProducts[product] = baseQty * productVariation
                }
                products[client] = clientProducts
            }
            
            data.append(OrderData(date: date, clients: clients, products: products))
        }
        
        self.ordersData = data.reversed()
    }
}

// MARK: - Statistic Card View
struct StatisticCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
