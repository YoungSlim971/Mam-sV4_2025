import SwiftUI
import Charts
import DataLayer

struct ModernStatsView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var selectedMetric: MetricType = .revenue
    @State private var showingFilters = false
    
    enum TimePeriod: String, CaseIterable {
        case thisWeek = "Cette semaine"
        case thisMonth = "Ce mois"
        case thisQuarter = "Ce trimestre"
        case thisYear = "Cette année"
        case lastMonth = "Mois dernier"
        case lastYear = "Année dernière"
        case custom = "Personnalisé"
        
        var icon: String {
            switch self {
            case .thisWeek: return "calendar.badge.clock"
            case .thisMonth, .lastMonth: return "calendar"
            case .thisQuarter: return "calendar.badge.plus"
            case .thisYear, .lastYear: return "calendar.circle"
            case .custom: return "calendar.badge.exclamationmark"
            }
        }
    }
    
    enum MetricType: String, CaseIterable {
        case revenue = "Revenus"
        case invoices = "Factures"
        case clients = "Clients"
        case products = "Produits"
        
        var icon: String {
            switch self {
            case .revenue: return "eurosign.circle"
            case .invoices: return "doc.text"
            case .clients: return "person.2"
            case .products: return "tag"
            }
        }
        
        var color: Color {
            switch self {
            case .revenue: return AppTheme.Colors.success
            case .invoices: return AppTheme.Colors.primary
            case .clients: return AppTheme.Colors.info
            case .products: return AppTheme.Colors.warning
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.xl) {
                // Header Controls
                modernHeaderView
                
                // Key Metrics Cards
                modernMetricsView
                
                // Charts Section
                modernChartsView
                
                // Detailed Analytics
                modernAnalyticsView
            }
            .padding(AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - Header View
    private var modernHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Tableau de Bord")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Analysez vos performances et tendances")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Period Selector
                Menu {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button {
                            selectedPeriod = period
                        } label: {
                            Label(period.rawValue, systemImage: period.icon)
                        }
                    }
                } label: {
                    AppButton(
                        selectedPeriod.rawValue,
                        icon: "calendar",
                        style: .secondary
                    ) {}
                }
                .menuStyle(.borderlessButton)
                
                // Export
                AppButton(
                    "Exporter",
                    icon: "square.and.arrow.up",
                    style: .secondary
                ) {
                    // Export action
                }
                
                // Refresh
                AppButton(
                    "",
                    icon: "arrow.clockwise",
                    style: .secondary,
                    size: .small
                ) {
                    // Refresh data
                }
            }
        }
    }
    
    // MARK: - Metrics View
    private var modernMetricsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.lg), count: 4), spacing: AppTheme.Spacing.lg) {
            MetricCard(
                title: "Revenus Total",
                value: totalRevenue.euroFormatted,
                icon: "eurosign.circle.fill",
                color: AppTheme.Colors.success,
                trend: "+12.5%"
            )
            
            MetricCard(
                title: "Factures Créées",
                value: "\(dataService.factures.count)",
                icon: "doc.text.fill",
                color: AppTheme.Colors.primary,
                trend: "+8"
            )
            
            MetricCard(
                title: "Nouveaux Clients",
                value: "\(newClientsCount)",
                icon: "person.badge.plus.fill",
                color: AppTheme.Colors.info,
                trend: "+3"
            )
            
            MetricCard(
                title: "Taux de Paiement",
                value: "\(Int(paymentRate))%",
                icon: "percent",
                color: paymentRate > 80 ? AppTheme.Colors.success : AppTheme.Colors.warning,
                trend: paymentRate > 80 ? "+5%" : "-2%"
            )
        }
    }
    
    // MARK: - Charts View
    private var modernChartsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Revenue Evolution Chart
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Évolution des Revenus")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Tendance des 6 derniers mois")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Picker("Métrique", selection: $selectedMetric) {
                        ForEach(MetricType.allCases, id: \.self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
                
                // Chart placeholder
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.surfaceSecondary)
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                            
                            Text("Graphique d'évolution")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text("Les données seront affichées ici")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    )
            }
            .appCard()
            
            // Charts Grid
            HStack(spacing: AppTheme.Spacing.lg) {
                // Client Distribution
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Répartition Clients")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Par chiffre d'affaires")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.surfaceSecondary)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "chart.pie")
                                    .font(.system(size: 30))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                
                                Text("Graphique en secteurs")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        )
                }
                .appCard()
                
                // Top Products
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Top Produits")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Les plus vendus")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.surfaceSecondary)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "chart.bar.horizontal")
                                    .font(.system(size: 30))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                
                                Text("Graphique horizontal")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        )
                }
                .appCard()
            }
        }
    }
    
    // MARK: - Analytics View
    private var modernAnalyticsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            analyticsHeader
            analyticsContent
        }
    }
    
    private var analyticsHeader: some View {
        HStack {
            Text("Analyses Détaillées")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            AppButton(
                "Voir tout",
                icon: "arrow.right",
                style: .ghost,
                size: .small
            ) {
                // View all analytics
            }
        }
    }
    
    private var analyticsContent: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            topClientsCard
            recentActivityCard
        }
    }
    
    private var topClientsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Top Clients")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(Array(topClients.prefix(5)), id: \.id) { client in
                    clientRow(client: client)
                }
            }
        }
        .appCard()
    }
    
    private func clientRow(client: ClientDTO) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primaryGradient)
                    .frame(width: 30, height: 30)
                
                Text(String(client.nom.prefix(1)).uppercased())
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(client.nomCompletClient)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("\(client.facturesCount(from: dataService.factures)) factures")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(client.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes).euroFormatted)
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.success)
        }
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Activité Récente")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(recentActivities, id: \.id) { activity in
                    activityRow(activity: activity)
                }
            }
        }
        .appCard()
    }
    
    private func activityRow(activity: ActivityItem) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: activity.icon)
                .font(.caption)
                .foregroundColor(activity.color)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(activity.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(activity.subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(activity.time)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
    }
    
    // MARK: - Computed Properties
    private var totalRevenue: Double {
        dataService.factures.filter { $0.statut == "Payée" }.reduce(0) { result, facture in
            result + facture.calculateTotalTTC(with: dataService.lignes)
        }
    }
    
    private var newClientsCount: Int {
        // Placeholder - would need creation date
        5
    }
    
    private var paymentRate: Double {
        let totalInvoices = dataService.factures.count
        let paidInvoices = dataService.factures.filter { $0.statut == "Payée" }.count
        
        guard totalInvoices > 0 else { return 0 }
        return (Double(paidInvoices) / Double(totalInvoices)) * 100
    }
    
    private var topClients: [ClientDTO] {
        dataService.clients.sorted { $0.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes) > $1.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes) }
    }
    
    private var recentActivities: [ActivityItem] {
        [
            ActivityItem(
                id: UUID(),
                title: "Facture FAC-2024-001 payée",
                subtitle: "Client: SARL Dupont",
                time: "Il y a 2h",
                icon: "checkmark.circle.fill",
                color: AppTheme.Colors.success
            ),
            ActivityItem(
                id: UUID(),
                title: "Nouveau client créé",
                subtitle: "Martin Industries",
                time: "Il y a 5h",
                icon: "person.badge.plus",
                color: AppTheme.Colors.primary
            ),
            ActivityItem(
                id: UUID(),
                title: "Facture en retard",
                subtitle: "FAC-2024-003 - €1,250",
                time: "Il y a 1j",
                icon: "exclamationmark.triangle.fill",
                color: AppTheme.Colors.warning
            ),
            ActivityItem(
                id: UUID(),
                title: "Produit ajouté",
                subtitle: "Consultation IT",
                time: "Il y a 2j",
                icon: "tag.circle",
                color: AppTheme.Colors.info
            )
        ]
    }
}

// MARK: - Activity Item Model
struct ActivityItem {
    let id: UUID
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let color: Color
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(trend)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(trend.hasPrefix("+") ? AppTheme.Colors.success : AppTheme.Colors.error)
                    .padding(.horizontal, AppTheme.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((trend.hasPrefix("+") ? AppTheme.Colors.success : AppTheme.Colors.error).opacity(0.1))
                    )
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(value)
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .appCard()
    }
}

#Preview {
    ModernStatsView()
        .environmentObject(DataService.shared)
}
