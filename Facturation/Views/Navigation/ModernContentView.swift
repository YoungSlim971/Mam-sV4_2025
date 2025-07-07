import SwiftUI
struct ModernContentView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var searchText = ""
    @State private var sidebarExpanded = true
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            ModernSidebarView(
                selectedTab: $selectedTab,
                isExpanded: $sidebarExpanded
            )
            .navigationSplitViewColumnWidth(
                min: sidebarExpanded ? 260 : 80,
                ideal: sidebarExpanded ? 280 : 80,
                max: sidebarExpanded ? 320 : 80
            )
        } detail: {
            ModernDetailView(
                selectedTab: selectedTab,
                searchText: $searchText
            )
            .navigationSplitViewColumnWidth(min: 900, ideal: 1200)
        }
        .searchable(text: $searchText, placement: .sidebar)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                ModernToolbarActions(selectedTab: selectedTab)
            }
        }
        .background(AppTheme.Colors.background)
    }
}

// MARK: - Modern Sidebar View
struct ModernSidebarView: View {
    @EnvironmentObject private var dataService: DataService
    @Binding var selectedTab: NavigationTab
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    if isExpanded {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "doc.text.below.ecg")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.Colors.primaryGradient)
                                
                                Text("Facturation")
                                    .font(AppTheme.Typography.title3)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                            
                            Text("Gestion professionnelle")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    } else {
                        Image(systemName: "doc.text.below.ecg")
                            .font(.title)
                            .foregroundStyle(AppTheme.Colors.primaryGradient)
                    }
                    
                    Spacer()
                    
                    AppButton(
                        "",
                        icon: isExpanded ? "sidebar.left" : "sidebar.right",
                        style: .ghost,
                        size: .small
                    ) {
                        withAnimation(AppTheme.Animation.spring) {
                            isExpanded.toggle()
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.xl)
                
                if isExpanded {
                    // Quick Stats
                    VStack(spacing: AppTheme.Spacing.sm) {
                        quickStatRow(
                            title: "Factures",
                            value: "\(dataService.factures.count)",
                            icon: "doc.text",
                            color: AppTheme.Colors.primary
                        )
                        
                        quickStatRow(
                            title: "Clients",
                            value: "\(dataService.clients.count)",
                            icon: "person.2",
                            color: AppTheme.Colors.success
                        )
                        
                        quickStatRow(
                            title: "En retard",
                            value: "\(overdueInvoicesCount)",
                            icon: "exclamationmark.triangle",
                            color: AppTheme.Colors.warning
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .appCard(padding: AppTheme.Spacing.md)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
            }
            
            // Navigation
            VStack(spacing: AppTheme.Spacing.xs) {
                ForEach(NavigationTab.allCases, id: \.self) { tab in
                    ModernSidebarItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        isExpanded: isExpanded
                    ) {
                        withAnimation(AppTheme.Animation.fast) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.xl)
            
            Spacer()
            
            // Footer
            if isExpanded {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Divider()
                    
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("Version 1.0.0")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        AppButton(
                            "",
                            icon: "questionmark.circle",
                            style: .ghost,
                            size: .small
                        ) {
                            // Help action
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
        }
        .background(AppTheme.Colors.surfacePrimary)
        .animation(AppTheme.Animation.spring, value: isExpanded)
    }
    
    @ViewBuilder
    private func quickStatRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.captionMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    private var overdueInvoicesCount: Int {
        dataService.factures.filter { facture in
            if let dateEcheance = facture.dateEcheance {
                return dateEcheance < Date() && facture.statut != .payee
            }
            return false
        }.count
    }
}

// MARK: - Modern Sidebar Item
struct ModernSidebarItem: View {
    let tab: NavigationTab
    let isSelected: Bool
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: tab.systemImage)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : tab.color)
                    .frame(width: 20, height: 20)
                
                if isExpanded {
                    Text(tab.rawValue)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(isSelected ? tab.color : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(isSelected ? Color.clear : tab.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppTheme.Animation.spring, value: isSelected)
    }
}

// MARK: - Modern Detail View
struct ModernDetailView: View {
    let selectedTab: NavigationTab
    @Binding var searchText: String
    @EnvironmentObject private var dataService: DataService
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ModernHeaderView(selectedTab: selectedTab, searchText: $searchText)
            
            // Content
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.Colors.background)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .dashboard:
            ModernDashboardView()
        case .factures:
            FacturesView(searchText: $searchText)
        case .clients:
            ClientsView(searchText: $searchText)
        case .produits:
            ProduitsView(searchText: $searchText)
        case .statistiques:
            StatsView()
        case .parametres:
            ParametresView(onClose: {})
        case .developpeur:
            DeveloperView()
        }
    }
}

// MARK: - Modern Header View
struct ModernHeaderView: View {
    let selectedTab: NavigationTab
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(selectedTab.rawValue)
                        .font(AppTheme.Typography.title1)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(headerSubtitle)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Quick actions based on selected tab
                headerActions
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.lg)
            
            Divider()
        }
        .background(AppTheme.Colors.surfacePrimary)
    }
    
    private var headerSubtitle: String {
        switch selectedTab {
        case .dashboard:
            return "Vue d'ensemble de votre activité"
        case .factures:
            return "Gérez vos factures et paiements"
        case .clients:
            return "Gérez votre base de clients"
        case .produits:
            return "Catalogue de produits et services"
        case .statistiques:
            return "Analyses et rapports détaillés"
        case .parametres:
            return "Configuration de l'application"
        case .developpeur:
            return "Outils de développement"
        }
    }
    
    @ViewBuilder
    private var headerActions: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            switch selectedTab {
            case .dashboard:
                AppButton.primary("Nouvelle Facture", icon: "plus.circle") {}
                AppButton.secondary("Nouveau Client", icon: "person.badge.plus") {}
                
            case .factures:
                AppButton.secondary("Exporter", icon: "square.and.arrow.up") {}
                AppButton.primary("Nouvelle Facture", icon: "plus.circle") {}
                
            case .clients:
                AppButton.secondary("Importer", icon: "square.and.arrow.down") {}
                AppButton.primary("Nouveau Client", icon: "person.badge.plus") {}
                
            case .produits:
                AppButton.primary("Nouveau Produit", icon: "tag.circle") {}
                
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Modern Toolbar Actions
struct ModernToolbarActions: View {
    let selectedTab: NavigationTab
    @State private var showingNewFacture = false
    @State private var showingNewClient = false
    @State private var showingNewProduit = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Global actions
            AppButton(
                "",
                icon: "bell",
                style: .ghost,
                size: .small
            ) {
                // Notifications
            }
            
            AppButton(
                "",
                icon: "gear",
                style: .ghost,
                size: .small
            ) {
                // Quick settings
            }
        }
        .sheet(isPresented: $showingNewFacture) {
            AddFactureView()
        }
        .sheet(isPresented: $showingNewClient) {
            AddClientView(onCreate: { _ in
                showingNewClient = false
            })
        }
    }
}

// MARK: - Modern Dashboard Placeholder
struct ModernDashboardView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.xl) {
                // Dashboard content will be implemented later
                Text("Modern Dashboard")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(AppTheme.Spacing.xl)
        }
    }
}

#Preview {
    ModernContentView()
        .environmentObject(DataService.shared)
}