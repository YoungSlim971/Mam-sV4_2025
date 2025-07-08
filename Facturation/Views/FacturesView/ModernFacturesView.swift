import SwiftUI
import DataLayer
struct ModernFacturesView: View {
    @EnvironmentObject private var dataService: DataService
    @Binding var searchText: String
    
    @State private var selectedFactures = Set<UUID>()
    @State private var showingAddFacture = false
    @State private var showingBulkActions = false
    @State private var selectedFilter: FactureFilter = .all
    @State private var sortOrder: SortOrder = .dateDesc
    @State private var viewMode: ViewMode = .grid
    
    enum FactureFilter: String, CaseIterable {
        case all = "Toutes"
        case draft = "Brouillons"
        case sent = "Envoyées"
        case paid = "Payées"
        case overdue = "En retard"
        case cancelled = "Annulées"
        
        var icon: String {
            switch self {
            case .all: return "doc.text"
            case .draft: return "doc.text.fill"
            case .sent: return "paperplane"
            case .paid: return "checkmark.circle"
            case .overdue: return "exclamationmark.triangle"
            case .cancelled: return "xmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return AppTheme.Colors.primary
            case .draft: return AppTheme.Colors.statusDraft
            case .sent: return AppTheme.Colors.statusSent
            case .paid: return AppTheme.Colors.statusPaid
            case .overdue: return AppTheme.Colors.statusOverdue
            case .cancelled: return AppTheme.Colors.statusCancelled
            }
        }
    }
    
    enum SortOrder: String, CaseIterable {
        case dateDesc = "Date (récent)"
        case dateAsc = "Date (ancien)"
        case numberDesc = "Numéro (Z-A)"
        case numberAsc = "Numéro (A-Z)"
        case amountDesc = "Montant (élevé)"
        case amountAsc = "Montant (faible)"
        
        var icon: String {
            switch self {
            case .dateDesc, .dateAsc: return "calendar"
            case .numberDesc, .numberAsc: return "number"
            case .amountDesc, .amountAsc: return "eurosign"
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grille"
        case list = "Liste"
        
        var icon: String {
            switch self {
            case .grid: return "rectangle.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filters and Controls
            modernFiltersView
            
            // Quick Stats
            modernStatsView
            
            // Content
            if filteredFactures.isEmpty {
                modernEmptyState
            } else {
                modernContentView
            }
        }
        .background(AppTheme.Colors.background)
        .sheet(isPresented: $showingAddFacture) {
            ModernAddFactureView()
        }
    }
    
    // MARK: - Filters View
    private var modernFiltersView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(FactureFilter.allCases, id: \.self) { filter in
                        ModernFilterPill(
                            title: filter.rawValue,
                            icon: filter.icon,
                            count: factureCount(for: filter),
                            isSelected: selectedFilter == filter,
                            color: filter.color
                        ) {
                            withAnimation(AppTheme.Animation.fast) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
            }
            
            // Controls
            HStack {
                // Search
                AppTextField(
                    "",
                    text: $searchText,
                    placeholder: "Rechercher une facture...",
                    icon: "magnifyingglass"
                )
                .frame(maxWidth: 300)
                
                Spacer()
                
                // Sort & View Controls
                HStack(spacing: AppTheme.Spacing.sm) {
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                Label(order.rawValue, systemImage: order.icon)
                            }
                        }
                    } label: {
                        AppButton(
                            "Trier",
                            icon: "arrow.up.arrow.down",
                            style: .secondary,
                            size: .small
                        ) {}
                    }
                    .menuStyle(.borderlessButton)
                    
                    // View Mode Toggle
                    Picker("Mode d'affichage", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Image(systemName: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    
                    AppButton.primary(
                        "Nouvelle Facture",
                        icon: "plus",
                        size: .small
                    ) {
                        showingAddFacture = true
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfacePrimary)
        .overlay(
            Rectangle()
                .fill(AppTheme.Colors.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Stats View
    private var modernStatsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.lg) {
                StatusCard(
                    title: "Total Factures",
                    value: "\(dataService.factures.count)",
                    icon: "doc.text.fill",
                    color: AppTheme.Colors.primary
                )
                .frame(width: 180)
                
                StatusCard(
                    title: "Revenus Total",
                    value: totalRevenue.euroFormatted,
                    icon: "eurosign.circle.fill",
                    color: AppTheme.Colors.success,
                    trend: "+12.5%",
                    trendDirection: .up
                )
                .frame(width: 200)
                
                StatusCard(
                    title: "En Attente",
                    value: "\(pendingInvoicesCount)",
                    icon: "clock.fill",
                    color: AppTheme.Colors.warning
                )
                .frame(width: 180)
                
                StatusCard(
                    title: "En Retard",
                    value: "\(overdueInvoicesCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: AppTheme.Colors.error,
                    trend: "-2",
                    trendDirection: .down
                )
                .frame(width: 180)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .padding(.vertical, AppTheme.Spacing.lg)
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var modernContentView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                if viewMode == .grid {
                    modernGridView
                } else {
                    modernListView
                }
            }
            .padding(AppTheme.Spacing.xl)
        }
    }
    
    // MARK: - Grid View
    private var modernGridView: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.lg), count: 3)

        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
            ForEach(sortedFactures) { facture in
                ModernFactureCard(
                    facture: facture,
                    dataService: dataService,
                    isSelected: selectedFactures.contains(facture.id)
                ) {
                    // Card tapped
                } onSelectionToggle: {
                    toggleSelection(for: facture.id)
                }
            }
        }
    }
    
    // MARK: - List View
    private var modernListView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(sortedFactures) { facture in
                ModernFactureListRow(
                    facture: facture,
                    dataService: dataService,
                    isSelected: selectedFactures.contains(facture.id)
                ) {
                    // Row tapped
                } onSelectionToggle: {
                    toggleSelection(for: facture.id)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var modernEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            AppCard {
                VStack(spacing: AppTheme.Spacing.xl) {
                    Image(systemName: emptyStateIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.Colors.primaryGradient)
                    
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text(emptyStateTitle)
                            .font(AppTheme.Typography.title2)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(emptyStateSubtitle)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if selectedFilter == .all && searchText.isEmpty {
                        AppButton.primary(
                            "Créer votre première facture",
                            icon: "plus.circle",
                            size: .large
                        ) {
                            showingAddFacture = true
                        }
                    }
                }
            }
            .frame(maxWidth: 500)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }
    
    // MARK: - Computed Properties
    private var filteredFactures: [FactureDTO] {
        var factures = dataService.factures
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .draft:
            factures = factures.filter { $0.statut == StatutFacture.brouillon.rawValue }
        case .sent:
            factures = factures.filter { $0.statut == StatutFacture.envoyee.rawValue }
        case .paid:
            factures = factures.filter { $0.statut == StatutFacture.payee.rawValue }
        case .overdue:
            factures = factures.filter { $0.statut == StatutFacture.enRetard.rawValue }
        case .cancelled:
            factures = factures.filter { $0.statut == StatutFacture.annulee.rawValue }
        }
        
        // Apply search
        if !searchText.isEmpty {
            factures = factures.filter { facture in
                facture.numero.localizedCaseInsensitiveContains(searchText) ||
                (dataService.clients.first { $0.id == facture.clientId }?.nomCompletClient
                    .localizedCaseInsensitiveContains(searchText) == true) ||
                facture.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return factures
    }
    
    private var sortedFactures: [FactureDTO] {
        filteredFactures.sorted { lhs, rhs in
            switch sortOrder {
            case .dateDesc:
                return lhs.dateFacture > rhs.dateFacture
            case .dateAsc:
                return lhs.dateFacture < rhs.dateFacture
            case .numberDesc:
                return lhs.numero > rhs.numero
            case .numberAsc:
                return lhs.numero < rhs.numero
            case .amountDesc:
                return lhs.calculateTotalTTC(with: dataService.lignes) > rhs.calculateTotalTTC(with: dataService.lignes)
            case .amountAsc:
                return lhs.calculateTotalTTC(with: dataService.lignes) < rhs.calculateTotalTTC(with: dataService.lignes)
            }
        }
    }
    
    private var totalRevenue: Double {
        dataService.factures.filter { $0.statut == StatutFacture.payee.rawValue }.reduce(0) { $0 + $1.calculateTotalTTC(with: dataService.lignes) }
    }
    
    private var pendingInvoicesCount: Int {
        dataService.factures.filter { $0.statut == StatutFacture.envoyee.rawValue }.count
    }
    
    private var overdueInvoicesCount: Int {
        dataService.factures.filter { facture in
            if let dateEcheance = facture.dateEcheance {
                return dateEcheance < Date() && facture.statut != StatutFacture.payee.rawValue
            }
            return false
        }.count
    }
    
    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        } else if selectedFilter != .all {
            return selectedFilter.icon
        } else {
            return "doc.text.badge.plus"
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "Aucun résultat"
        } else if selectedFilter != .all {
            return "Aucune facture \(selectedFilter.rawValue.lowercased())"
        } else {
            return "Aucune facture"
        }
    }
    
    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return "Aucune facture ne correspond à votre recherche '\(searchText)'"
        } else if selectedFilter != .all {
            return "Vous n'avez pas encore de factures avec ce statut."
        } else {
            return "Commencez par créer votre première facture pour gérer vos transactions."
        }
    }
    
    // MARK: - Helper Methods
    private func factureCount(for filter: FactureFilter) -> Int {
        switch filter {
        case .all:
            return dataService.factures.count
        case .draft:
            return dataService.factures.filter { $0.statut == StatutFacture.brouillon.rawValue }.count
        case .sent:
            return dataService.factures.filter { $0.statut == StatutFacture.envoyee.rawValue }.count
        case .paid:
            return dataService.factures.filter { $0.statut == StatutFacture.payee.rawValue }.count
        case .overdue:
            return overdueInvoicesCount
        case .cancelled:
            return dataService.factures.filter { $0.statut == StatutFacture.annulee.rawValue }.count
        }
    }
    
    private func toggleSelection(for id: UUID) {
        if selectedFactures.contains(id) {
            selectedFactures.remove(id)
        } else {
            selectedFactures.insert(id)
        }
    }
}

// MARK: - Modern Filter Pill
struct ModernFilterPill: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : AppTheme.Colors.surfaceSecondary)
                        )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? color : AppTheme.Colors.surfaceSecondary)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(AppTheme.Animation.spring, value: isSelected)
    }
}

// MARK: - Modern Facture Card (Placeholder)
struct ModernFactureCard: View {
    let facture: FactureDTO
    let dataService: DataService
    let isSelected: Bool
    let onTap: () -> Void
    let onSelectionToggle: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text(facture.numero)
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Spacer()

                    Button(action: onSelectionToggle) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text(dataService.clients.first(where: { $0.id == facture.clientId })?.nomCompletClient ?? "Client inconnu")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                HStack {
                    Text(facture.calculateTotalTTC(with: dataService.lignes).euroFormatted)
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.success)

                    Spacer()

                    Text(facture.statutDisplay)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(facture.statutColor)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(facture.statutColor.opacity(0.1))
                        )
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppTheme.Animation.spring, value: isSelected)
    }
}

// MARK: - Modern Facture List Row (Placeholder)
struct ModernFactureListRow: View {
    let facture: FactureDTO
    let dataService: DataService
    let isSelected: Bool
    let onTap: () -> Void
    let onSelectionToggle: () -> Void

    var body: some View {
        AppCard(padding: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.lg) {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(facture.numero)
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(dataService.clients.first(where: { $0.id == facture.clientId })?.nomCompletClient ?? "Client inconnu")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Text(facture.calculateTotalTTC(with: dataService.lignes).euroFormatted)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.success)

                Text(facture.statutDisplay)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(facture.statutColor)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(facture.statutColor.opacity(0.1))
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(AppTheme.Animation.spring, value: isSelected)
    }
}

#Preview {
    ModernFacturesView(searchText: .constant(""))
        .environmentObject(DataService.shared)
}
