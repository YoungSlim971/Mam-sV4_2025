import SwiftUI
import Utilities
import DataLayer

struct ModernParametresView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSection: SettingsSection = .company
    @State private var showingResetAlert = false
    @State private var showingExportOptions = false

    // State for editable entreprise data
    @State private var editedEntreprise: EntrepriseDTO = .mock() // Initialize with a mock or default
    
    // Validation states and messages
    @State private var siretErrorMessage: String?
    @State private var tvaErrorMessage: String?
    @State private var ibanErrorMessage: String?
    @State private var isSiretValid: Bool = true
    @State private var isTvaValid: Bool = true
    @State private var isIbanValid: Bool = true
    
    enum SettingsSection: String, CaseIterable {
        case company = "Entreprise"
        case invoicing = "Facturation"
        case appearance = "Apparence"
        case notifications = "Notifications"
        case data = "Données"
        case about = "À propos"
        
        var icon: String {
            switch self {
            case .company: return "building.2"
            case .invoicing: return "doc.text"
            case .appearance: return "paintbrush"
            case .notifications: return "bell"
            case .data: return "externaldrive"
            case .about: return "info.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .company: return AppTheme.Colors.primary
            case .invoicing: return AppTheme.Colors.success
            case .appearance: return AppTheme.Colors.info
            case .notifications: return AppTheme.Colors.warning
            case .data: return AppTheme.Colors.error
            case .about: return AppTheme.Colors.textSecondary
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            modernSidebarView
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
        } detail: {
            // Detail View
            modernDetailView
                .navigationSplitViewColumnWidth(min: 600, ideal: 800)
        }
        .navigationTitle("Paramètres")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                AppButton(
                    "Fermer",
                    style: .ghost,
                    size: .small
                ) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                AppButton(
                    "Sauvegarder",
                    icon: "checkmark",
                    size: .small
                ) {
                    Task {
                        await dataService.updateEntrepriseDTO(editedEntreprise)
                    }
                }
                .disabled(!isSiretValid || !isTvaValid || !isIbanValid)
            }
        }
        .alert("Réinitialiser les données", isPresented: $showingResetAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Réinitialiser", role: .destructive) {
                // Reset data action
            }
        } message: {
            Text("Cette action supprimera définitivement toutes vos données. Cette action ne peut pas être annulée.")
        }
        .onAppear {
            if let entreprise = dataService.entreprise {
                editedEntreprise = entreprise
                // Perform initial validation on appear
                isSiretValid = Validator.isValidSIRET(editedEntreprise.siret)
                siretErrorMessage = isSiretValid ? nil : "Numéro SIRET invalide (14 chiffres)"
                isTvaValid = Validator.isValidTVA(editedEntreprise.numeroTVA)
                tvaErrorMessage = isTvaValid ? nil : "Numéro TVA invalide (FR + 11 caractères)"
                isIbanValid = Validator.isValidIBAN(editedEntreprise.iban)
                ibanErrorMessage = isIbanValid ? nil : "Numéro IBAN invalide"
            }
        }
    }
    
    // MARK: - Sidebar View
    private var modernSidebarView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "gear")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.Colors.primaryGradient)
                
                Text("Paramètres")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(.vertical, AppTheme.Spacing.xl)
            
            // Sections List
            List(SettingsSection.allCases, id: \.self, selection: $selectedSection) { section in
                ModernSettingsRow(
                    title: section.rawValue,
                    icon: section.icon,
                    color: section.color,
                    isSelected: selectedSection == section
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .listStyle(SidebarListStyle())
            
            Spacer()
            
            // Footer
            VStack(spacing: AppTheme.Spacing.sm) {
                Divider()
                
                HStack {
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
        .background(AppTheme.Colors.surfacePrimary)
    }
    
    // MARK: - Detail View
    @ViewBuilder
    private var modernDetailView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.xl) {
                switch selectedSection {
                case .company:
                    companySettingsView
                case .invoicing:
                    invoicingSettingsView
                case .appearance:
                    appearanceSettingsView
                case .notifications:
                    notificationsSettingsView
                case .data:
                    dataSettingsView
                case .about:
                    aboutSettingsView
                }
            }
            .padding(AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - Company Settings
    private var companySettingsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ModernSectionHeader(
                title: "Informations de l'entreprise",
                subtitle: "Configurez les informations de votre entreprise qui apparaîtront sur vos factures"
            )
            
            // Use editedEntreprise for binding
            VStack(spacing: AppTheme.Spacing.lg) {
                AppCard {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("Informations générales")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            AppTextField(
                                "Nom de l'entreprise",
                                text: $editedEntreprise.nom,
                                icon: "building.2"
                            )
                            
                            AppTextField(
                                "Dirigeant",
                                text: $editedEntreprise.nomDirigeant,
                                icon: "person"
                            )
                            
                            AppTextField(
                                "Domaine d'activité",
                                text: $editedEntreprise.domaine,
                                icon: "briefcase"
                            )
                            
                            AppTextField(
                                "SIRET",
                                text: $editedEntreprise.siret,
                                icon: "number"
                            )
                            .onChange(of: editedEntreprise.siret) { newValue in
                                isSiretValid = Validator.isValidSIRET(newValue)
                                siretErrorMessage = isSiretValid ? nil : "Numéro SIRET invalide (14 chiffres)"
                            }
                            if let errorMessage = siretErrorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                
                AppCard {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("Coordonnées")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            AppTextField(
                                "Email",
                                text: $editedEntreprise.email,
                                icon: "envelope",
                                keyboardType: .emailAddress
                            )
                            
                            AppTextField(
                                "Téléphone",
                                text: $editedEntreprise.telephone,
                                icon: "phone",
                                keyboardType: .phonePad
                            )
                            
                            AppTextField(
                                "Adresse",
                                text: $editedEntreprise.adresseRue,
                                icon: "location"
                            )
                            
                            HStack(spacing: AppTheme.Spacing.md) {
                                AppTextField(
                                    "Code postal",
                                    text: $editedEntreprise.adresseCodePostal,
                                    icon: "number"
                                )
                                
                                AppTextField(
                                    "Ville",
                                    text: $editedEntreprise.adresseVille,
                                    icon: "building"
                                )
                            }
                            
                            AppTextField(
                                "Numéro TVA",
                                text: $editedEntreprise.numeroTVA,
                                icon: "building.columns"
                            )
                            .onChange(of: editedEntreprise.numeroTVA) { newValue in
                                isTvaValid = Validator.isValidTVA(newValue)
                                tvaErrorMessage = isTvaValid ? nil : "Numéro TVA invalide (FR + 11 caractères)"
                            }
                            if let errorMessage = tvaErrorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                
                AppCard {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("Informations bancaires")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            AppTextField(
                                "IBAN",
                                text: $editedEntreprise.iban,
                                placeholder: "FR76 XXXX XXXX XXXX XXXX XXXX XXX",
                                icon: "creditcard"
                            )
                            .onChange(of: editedEntreprise.iban) { newValue in
                                isIbanValid = Validator.isValidIBAN(newValue)
                                ibanErrorMessage = isIbanValid ? nil : "Numéro IBAN invalide"
                            }
                            if let errorMessage = ibanErrorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            AppTextField(
                                "BIC",
                                text: $editedEntreprise.bic,
                                placeholder: "BNPAFRPP",
                                icon: "building.columns"
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Invoicing Settings
    private var invoicingSettingsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ModernSectionHeader(
                title: "Paramètres de facturation",
                subtitle: "Configurez le comportement par défaut de vos factures"
            )
            
            VStack(spacing: AppTheme.Spacing.lg) {
                AppCard {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("Numérotation")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text("Prochain numéro")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                AppTextField(
                                    "",
                                    text: .constant("001"),
                                    placeholder: "001"
                                )
                                .frame(width: 100)
                            }
                            
                            HStack {
                                Text("Format")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("FAC-2024-{NUM}")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .padding(.vertical, AppTheme.Spacing.sm)
                                    .background(AppTheme.Colors.surfaceSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                            }
                        }
                    }
                }
                
                AppCard {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("Valeurs par défaut")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text("TVA (%)")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                AppTextField(
                                    "",
                                    text: .constant("20"),
                                    placeholder: "20"
                                )
                                .frame(width: 80)
                            }
                            
                            HStack {
                                Text("Échéance par défaut (jours)")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                AppTextField(
                                    "",
                                    text: .constant("30"),
                                    placeholder: "30"
                                )
                                .frame(width: 80)
                            }
                            
                            HStack {
                                Text("Conditions de paiement")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                Picker("", selection: .constant(ConditionsPaiement.virement)) {
                                    ForEach(ConditionsPaiement.allCases, id: \.self) { condition in
                                        Text(condition.rawValue).tag(condition)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 150)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Appearance Settings
    private var appearanceSettingsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ModernSectionHeader(
                title: "Apparence",
                subtitle: "Personnalisez l'apparence de l'application"
            )
            
            AppCard {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Text("Thème")
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: AppTheme.Spacing.lg) {
                        ModernThemeOption(
                            title: "Clair",
                            icon: "sun.max",
                            isSelected: true
                        ) {
                            // Set light theme
                        }
                        
                        ModernThemeOption(
                            title: "Sombre",
                            icon: "moon",
                            isSelected: false
                        ) {
                            // Set dark theme
                        }
                        
                        ModernThemeOption(
                            title: "Auto",
                            icon: "circle.lefthalf.filled",
                            isSelected: false
                        ) {
                            // Set auto theme
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Notifications Settings
    private var notificationsSettingsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ModernSectionHeader(
                title: "Notifications",
                subtitle: "Gérez vos notifications et alertes"
            )
            
            VStack(spacing: AppTheme.Spacing.lg) {
                AppCard {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ModernToggleRow(
                            title: "Factures en retard",
                            subtitle: "Recevoir une alerte quand une facture est en retard",
                            icon: "exclamationmark.triangle",
                            isOn: .constant(true)
                        )
                        
                        Divider()
                        
                        ModernToggleRow(
                            title: "Nouveaux paiements",
                            subtitle: "Notification lors de la réception d'un paiement",
                            icon: "checkmark.circle",
                            isOn: .constant(true)
                        )
                        
                        Divider()
                        
                        ModernToggleRow(
                            title: "Rappels d'échéance",
                            subtitle: "Rappel 3 jours avant l'échéance",
                            icon: "calendar.badge.exclamationmark",
                            isOn: .constant(false)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Data Settings
    private var dataSettingsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ModernSectionHeader(
                title: "Gestion des données",
                subtitle: "Sauvegarde, restauration et gestion de vos données"
            )
            
            VStack(spacing: AppTheme.Spacing.lg) {
                AppCard {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("Sauvegarde et exportation")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            InfoCard(
                                title: "Exporter toutes les données",
                                subtitle: "Télécharger un fichier JSON avec toutes vos données",
                                icon: "square.and.arrow.up",
                                color: AppTheme.Colors.primary
                            ) {
                                showingExportOptions = true
                            }
                            
                            InfoCard(
                                title: "Sauvegarder automatiquement",
                                subtitle: "Sauvegardes quotidiennes sur iCloud",
                                icon: "icloud.and.arrow.up",
                                color: AppTheme.Colors.info
                            ) {
                                // Toggle auto backup
                            }
                        }
                    }
                }
                
                AppCard {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("Zone de danger")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        InfoCard(
                            title: "Réinitialiser toutes les données",
                            subtitle: "Supprimer définitivement toutes les données",
                            icon: "trash",
                            color: AppTheme.Colors.error
                        ) {
                            showingResetAlert = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - About Settings
    private var aboutSettingsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ModernSectionHeader(
                title: "À propos",
                subtitle: "Informations sur l'application"
            )
            
            VStack(spacing: AppTheme.Spacing.lg) {
                AppCard {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        Image(systemName: "doc.text.below.ecg")
                            .font(.system(size: 60))
                            .foregroundStyle(AppTheme.Colors.primaryGradient)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            Text("Facturation Pro")
                                .font(AppTheme.Typography.title2)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("Version 1.0.0")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text("Application de gestion de facturation professionnelle pour macOS")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        
                        HStack(spacing: AppTheme.Spacing.md) {
                            AppButton.secondary(
                                "Aide",
                                icon: "questionmark.circle"
                            ) {
                                // Open help
                            }
                            
                            AppButton.secondary(
                                "Notes de version",
                                icon: "doc.text"
                            ) {
                                // Show release notes
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct ModernSettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

struct ModernSectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(subtitle)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ModernThemeOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.primary)
                
                Text(title)
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(isSelected ? Color.clear : AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

#Preview {
    ModernParametresView()
        .environmentObject(DataService.shared)
}