import SwiftUI
import DataLayer
struct ModernClientsView: View {
    @EnvironmentObject private var dataService: DataService
    @Binding var searchText: String
    
    @State private var selectedClients = Set<UUID>()
    @State private var showingAddClient = false
    @State private var selectedSort: ClientSort = .nameAsc
    @State private var viewMode: ViewMode = .grid
    @State private var showingFilters = false
    
    enum ClientSort: String, CaseIterable {
        case nameAsc = "Nom (A-Z)"
        case nameDesc = "Nom (Z-A)"
        case revenueDesc = "CA (élevé)"
        case revenueAsc = "CA (faible)"
        case facturesDesc = "Factures (plus)"
        case facturesAsc = "Factures (moins)"
        case dateDesc = "Récent"
        case dateAsc = "Ancien"
        
        var icon: String {
            switch self {
            case .nameAsc, .nameDesc: return "textformat.abc"
            case .revenueDesc, .revenueAsc: return "eurosign"
            case .facturesDesc, .facturesAsc: return "doc.text"
            case .dateDesc, .dateAsc: return "calendar"
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grille"
        case list = "Liste"
        case table = "Tableau"
        
        var icon: String {
            switch self {
            case .grid: return "rectangle.grid.2x2"
            case .list: return "list.bullet"
            case .table: return "tablecells"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Controls
            modernHeaderView
            
            // Quick Stats
            modernStatsView
            
            // Content
            if filteredClients.isEmpty {
                modernEmptyState
            } else {
                modernContentView
            }
        }
        .background(AppTheme.Colors.background)
        .sheet(isPresented: $showingAddClient) {
            AddClientView(onCreate: { _ in
                showingAddClient = false
            })
        }
    }
    
    // MARK: - Header View
    private var modernHeaderView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack {
                // Search
                AppTextField(
                    "",
                    text: $searchText,
                    placeholder: "Rechercher un client...",
                    icon: "magnifyingglass"
                )
                .frame(maxWidth: 400)
                
                Spacer()
                
                // Controls
                HStack(spacing: AppTheme.Spacing.sm) {
                    // Sort Menu
                    Menu {
                        ForEach(ClientSort.allCases, id: \.self) { sort in
                            Button {
                                selectedSort = sort
                            } label: {
                                Label(sort.rawValue, systemImage: sort.icon)
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
                    
                    // View Mode
                    Picker("Mode d'affichage", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Image(systemName: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                    
                    // Actions
                    Menu {
                        Button("Exporter CSV") {
                            // Export action
                        }
                        Button("Importer CSV") {
                            // Import action
                        }
                        Divider()
                        Button("Analyser les clients") {
                            // Analytics action
                        }
                    } label: {
                        AppButton(
                            "",
                            icon: "ellipsis.circle",
                            style: .secondary,
                            size: .small
                        ) {}
                    }
                    .menuStyle(.borderlessButton)
                    
                    AppButton.primary(
                        "Nouveau Client",
                        icon: "person.badge.plus",
                        size: .small
                    ) {
                        showingAddClient = true
                    }
                }
            }
            
            // Bulk Actions (if any selected)
            if !selectedClients.isEmpty {
                modernBulkActionsView
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.surfacePrimary)
        .overlay(
            Rectangle()
                .fill(AppTheme.Colors.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Bulk Actions
    private var modernBulkActionsView: some View {
        HStack {
            Text("\(selectedClients.count) client\(selectedClients.count > 1 ? "s" : "") sélectionné\(selectedClients.count > 1 ? "s" : "")")
                .font(AppTheme.Typography.captionMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: AppTheme.Spacing.sm) {
                AppButton(
                    "Envoyer email",
                    icon: "envelope",
                    style: .secondary,
                    size: .small
                ) {
                    // Bulk email action
                }
                
                AppButton(
                    "Créer facture",
                    icon: "doc.text.badge.plus",
                    style: .secondary,
                    size: .small
                ) {
                    // Bulk invoice action
                }
                
                AppButton(
                    "Supprimer",
                    icon: "trash",
                    style: .danger,
                    size: .small
                ) {
                    // Bulk delete action
                }
                
                AppButton(
                    "Tout désélectionner",
                    style: .ghost,
                    size: .small
                ) {
                    selectedClients.removeAll()
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.primaryLight)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
    
    // MARK: - Stats View
    private var modernStatsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.lg) {
                StatusCard(
                    title: "Total Clients",
                    value: "\(dataService.clients.count)",
                    icon: "person.2.fill",
                    color: AppTheme.Colors.primary
                )
                .frame(width: 180)
                
                StatusCard(
                    title: "Revenus Total",
                    value: totalClientRevenue.euroFormatted,
                    icon: "eurosign.circle.fill",
                    color: AppTheme.Colors.success,
                    trend: "+15.2%",
                    trendDirection: .up
                )
                .frame(width: 200)
                
                StatusCard(
                    title: "Nouveaux ce mois",
                    value: "\(newClientsThisMonth)",
                    icon: "person.badge.plus.fill",
                    color: AppTheme.Colors.info,
                    trend: "+3",
                    trendDirection: .up
                )
                .frame(width: 200)
                
                StatusCard(
                    title: "Clients VIP",
                    value: "\(vipClientsCount)",
                    icon: "star.fill",
                    color: AppTheme.Colors.warning
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
                switch viewMode {
                case .grid:
                    modernGridView
                case .list:
                    modernListView
                case .table:
                    modernTableView
                }
            }
            .padding(AppTheme.Spacing.xl)
        }
    }
    
    // MARK: - Grid View
    private var modernGridView: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.lg), count: 3)
        
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
            ForEach(sortedClients) { client in
                ModernClientCard(
                    client: client,
                    isSelected: selectedClients.contains(client.id)
                ) {
                    // Card tapped - navigate to detail
                } onSelectionToggle: {
                    toggleSelection(for: client.id)
                }
            }
        }
    }
    
    // MARK: - List View
    private var modernListView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(sortedClients) { client in
                ModernClientListRow(
                    client: client,
                    isSelected: selectedClients.contains(client.id)
                ) {
                    // Row tapped - navigate to detail
                } onSelectionToggle: {
                    toggleSelection(for: client.id)
                }
            }
        }
    }
    
    // MARK: - Table View
    private var modernTableView: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                HStack {
                    Button(action: {
                        if selectedClients.count == sortedClients.count {
                            selectedClients.removeAll()
                        } else {
                            selectedClients = Set(sortedClients.map { $0.id })
                        }
                    }) {
                        Image(systemName: selectedClients.isEmpty ? "square" : 
                              selectedClients.count == sortedClients.count ? "checkmark.square.fill" : "minus.square.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Client")
                        .font(AppTheme.Typography.captionMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Contact")
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Factures")
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 100, alignment: .center)
                
                Text("CA Total")
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 120, alignment: .trailing)
                
                Text("Actions")
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 100, alignment: .center)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surfaceSecondary)
            
            Divider()
            
            // Table Rows
            ForEach(sortedClients) { client in
                ModernClientTableRow(
                    client: client,
                    isSelected: selectedClients.contains(client.id)
                ) {
                    // Row tapped
                } onSelectionToggle: {
                    toggleSelection(for: client.id)
                }
            }
        }
        .appCard(padding: 0)
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
                    
                    if searchText.isEmpty {
                        VStack(spacing: AppTheme.Spacing.md) {
                            AppButton.primary(
                                "Ajouter votre premier client",
                                icon: "person.badge.plus",
                                size: .large
                            ) {
                                showingAddClient = true
                            }
                            
                            AppButton.secondary(
                                "Importer des clients",
                                icon: "square.and.arrow.down"
                            ) {
                                // Import action
                            }
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
    private var filteredClients: [ClientDTO] {
        var clients = dataService.clients
        
        if !searchText.isEmpty {
            clients = clients.filter { client in
                client.nomCompletClient.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText) ||
                client.entreprise.localizedCaseInsensitiveContains(searchText) ||
                client.telephone.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return clients
    }
    
    private var sortedClients: [ClientDTO] {
        filteredClients.sorted { lhs, rhs in
            switch selectedSort {
            case .nameAsc:
                return lhs.nomCompletClient < rhs.nomCompletClient
            case .nameDesc:
                return lhs.nomCompletClient > rhs.nomCompletClient
            case .revenueDesc:
                return lhs.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes) > rhs.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes)
            case .revenueAsc:
                return lhs.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes) < rhs.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes)
            case .facturesDesc:
                return lhs.facturesCount(from: dataService.factures) > rhs.facturesCount(from: dataService.factures)
            case .facturesAsc:
                return lhs.facturesCount(from: dataService.factures) < rhs.facturesCount(from: dataService.factures)
            case .dateDesc:
                return lhs.nom > rhs.nom // Placeholder for creation date
            case .dateAsc:
                return lhs.nom < rhs.nom // Placeholder for creation date
            }
        }
    }
    
    private var totalClientRevenue: Double {
        dataService.clients.reduce(0) { $0 + $1.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes) }
    }
    
    private var newClientsThisMonth: Int {
        // Placeholder - would need creation date in model
        3
    }
    
    private var vipClientsCount: Int {
        dataService.clients.filter { $0.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes) > 10000 }.count
    }
    
    private var emptyStateIcon: String {
        searchText.isEmpty ? "person.2.badge.plus" : "magnifyingglass"
    }
    
    private var emptyStateTitle: String {
        searchText.isEmpty ? "Aucun client" : "Aucun résultat"
    }
    
    private var emptyStateSubtitle: String {
        if searchText.isEmpty {
            return "Commencez par ajouter vos premiers clients pour gérer vos factures et suivre vos revenus."
        } else {
            return "Aucun client ne correspond à votre recherche '\(searchText)'"
        }
    }
    
    // MARK: - Helper Methods
    private func toggleSelection(for id: UUID) {
        if selectedClients.contains(id) {
            selectedClients.remove(id)
        } else {
            selectedClients.insert(id)
        }
    }
}

// MARK: - Modern Client Card
struct ModernClientCard: View {
    let client: ClientDTO
    let isSelected: Bool
    let onTap: () -> Void
    let onSelectionToggle: () -> Void
    
    @EnvironmentObject private var dataService: DataService
    
    var body: some View {
        AppCard {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                HStack {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.primaryGradient)
                            .frame(width: 50, height: 50)
                        
                        Text(client.nom.prefix(1).uppercased())
                            .font(AppTheme.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: onSelectionToggle) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(client.nomCompletClient)
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    if !client.entreprise.isEmpty {
                        Text(client.entreprise)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    if !client.email.isEmpty {
                        Text(client.email)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Stats
                HStack {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("\(client.facturesCount(from: dataService.factures))")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("Factures")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                        Text(client.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes).euroFormatted)
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.success)
                        
                        Text("CA Total")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
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

// MARK: - Modern Client List Row
struct ModernClientListRow: View {
    let client: ClientDTO
    let isSelected: Bool
    let onTap: () -> Void
    let onSelectionToggle: () -> Void
    
    @EnvironmentObject private var dataService: DataService
    
    var body: some View {
        AppCard(padding: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.lg) {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.primaryGradient)
                        .frame(width: 40, height: 40)
                    
                    Text(client.nom.prefix(1).uppercased())
                        .font(AppTheme.Typography.body)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(client.nomComplet)
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack(spacing: AppTheme.Spacing.md) {
                        if !client.entreprise.isEmpty {
                            Text(client.entreprise)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        if !client.email.isEmpty {
                            Text(client.email)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Stats
                HStack(spacing: AppTheme.Spacing.xl) {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("\(client.facturesCount(from: dataService.factures))")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("Factures")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                        Text(client.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes).euroFormatted)
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.success)
                        
                        Text("CA Total")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
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

// MARK: - Modern Client Table Row
struct ModernClientTableRow: View {
    let client: ClientDTO
    let isSelected: Bool
    let onTap: () -> Void
    let onSelectionToggle: () -> Void
    
    @EnvironmentObject private var dataService: DataService
    
    var body: some View {
        HStack {
            // Selection + Name
            HStack {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                
                HStack(spacing: AppTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.primaryGradient)
                            .frame(width: 30, height: 30)
                        
                        Text(client.nom.prefix(1).uppercased())
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(client.nomComplet)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if !client.entreprise.isEmpty {
                            Text(client.entreprise)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Contact
            VStack(alignment: .leading, spacing: 2) {
                if !client.email.isEmpty {
                    Text(client.email)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                if !client.telephone.isEmpty {
                    Text(client.telephone)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Factures
            Text("\(client.facturesCount(from: dataService.factures))")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 100, alignment: .center)
            
            // CA Total
            Text(client.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes).euroFormatted)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.success)
                .frame(width: 120, alignment: .trailing)
            
            // Actions
            HStack(spacing: AppTheme.Spacing.xs) {
                Button(action: {}) {
                    Image(systemName: "envelope")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "doc.text.badge.plus")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.success)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 100, alignment: .center)
        }
        .padding(AppTheme.Spacing.md)
        .background(isSelected ? AppTheme.Colors.primaryLight : Color.clear)
        .onTapGesture(perform: onTap)
        .animation(AppTheme.Animation.fast, value: isSelected)
    }
}

#Preview {
    ModernClientsView(searchText: .constant(""))
        .environmentObject(DataService.shared)
}