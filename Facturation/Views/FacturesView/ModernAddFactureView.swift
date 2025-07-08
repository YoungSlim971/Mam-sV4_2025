import SwiftUI
import Foundation

// Note fixe appliquée à toutes les factures
private let defaultFactureNote = """
TVA NON APPLICABLE — ARTICLE 293 B du CGI.
Les règlements se font par VIREMENT sur le compte EXOTROPIC.
"""

struct ModernAddFactureView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedClient: ClientDTO?
    @State private var showingClientCreation = false
    @State private var searchText = ""
    @State private var currentStep = 1
    
    private let totalSteps = 3
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                ModernProgressHeader(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    title: stepTitle
                )
                
                // Content
                TabView(selection: $currentStep) {
                    // Step 1: Client Selection
                    clientSelectionStep
                        .tag(1)
                    
                    // Step 2: Invoice Details
                    if let client = selectedClient {
                        invoiceDetailsStep(client: client)
                            .tag(2)
                    }
                    
                    // Step 3: Review
                    if let client = selectedClient {
                        reviewStep(client: client)
                            .tag(3)
                    }
                }
                .tabViewStyle(.automatic)
                .animation(AppTheme.Animation.spring, value: currentStep)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Nouvelle Facture")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    AppButton(
                        "Annuler",
                        style: .ghost,
                        size: .small
                    ) {
                        dismiss()
                    }
                    HStack(spacing: AppTheme.Spacing.sm) {
                        if currentStep > 1 {
                            AppButton(
                                "Précédent",
                                style: .secondary,
                                size: .small
                            ) {
                                withAnimation(AppTheme.Animation.spring) {
                                    currentStep -= 1
                                }
                            }
                        }
                        if currentStep < totalSteps {
                            AppButton(
                                "Suivant",
                                icon: "arrow.right",
                                size: .small,
                                isDisabled: !canProceedToNextStep
                            ) {
                                withAnimation(AppTheme.Animation.spring) {
                                    currentStep += 1
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingClientCreation) {
            AddClientView(onCreate: { _ in
                showingClientCreation = false
            })
        }
        .frame(minWidth: 900, minHeight: 700)
    }
    
    private var stepTitle: String {
        switch currentStep {
        case 1: return "Sélectionner un client"
        case 2: return "Détails de la facture"
        case 3: return "Vérification"
        default: return ""
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 1: return selectedClient != nil
        case 2: return true // Will be validated in the details step
        default: return false
        }
    }
    
    // MARK: - Step 1: Client Selection
    @ViewBuilder
    private var clientSelectionStep: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            if dataService.clients.isEmpty {
                ModernEmptyClientsState(showingClientCreation: $showingClientCreation)
            } else {
                ModernClientSelectionView(
                    clients: filteredClients,
                    selectedClient: $selectedClient,
                    searchText: $searchText,
                    showingClientCreation: $showingClientCreation
                )
            }
        }
        .padding(AppTheme.Spacing.xl)
    }
    
    // MARK: - Step 2: Invoice Details
    @ViewBuilder
    private func invoiceDetailsStep(client: ClientDTO) -> some View {
        ModernFactureFormView(
            client: client,
            onNext: {
                withAnimation(AppTheme.Animation.spring) {
                    currentStep = 3
                }
            }
        )
        .padding(AppTheme.Spacing.xl)
    }
    
    // MARK: - Step 3: Review
    @ViewBuilder
    private func reviewStep(client: ClientDTO) -> some View {
        ModernFactureReviewView(
            client: client,
            onCreate: { editableFacture in
                createFacture(editableFacture, for: client)
            }
        )
        .padding(AppTheme.Spacing.xl)
    }
    
    private var filteredClients: [ClientDTO] {
        if searchText.isEmpty {
            return dataService.clients
        }
        return dataService.clients.filter { client in
            client.nomCompletClient.localizedCaseInsensitiveContains(searchText) ||
            client.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func createFacture(_ editableFacture: EditableFacture, for client: ClientDTO) {
        Task {
            let numero: String
            if editableFacture.numerotationAutomatique {
                // Get client model for numbering
                guard let clientModel = await dataService.fetchClientModel(id: client.id) else {
                    print("Erreur: Client non trouvé pour la génération du numéro")
                    return
                }
                numero = await dataService.genererNumeroFacture(client: clientModel)
            } else {
                numero = editableFacture.numeroPersonnalise ?? ""
            }
            
            // Create ligne DTOs first
            var ligneDTOs: [LigneFactureDTO] = []
            for editableLigne in editableFacture.lignes {
                let ligneDTO = LigneFactureDTO(
                    id: editableLigne.id,
                    designation: editableLigne.designation,
                    quantite: editableLigne.quantite,
                    prixUnitaire: editableLigne.prixUnitaire,
                    referenceCommande: editableLigne.referenceCommande,
                    dateCommande: editableLigne.dateCommande,
                    produitId: editableLigne.produitId,
                    factureId: nil // Will be set when facture is created
                )
                ligneDTOs.append(ligneDTO)
            }
            
            // Add lignes to service first
            for ligneDTO in ligneDTOs {
                await dataService.addLigneDTO(ligneDTO)
            }
            
            // Create facture DTO
            let factureDTO = FactureDTO(
                id: UUID(),
                numero: numero,
                dateFacture: editableFacture.dateFacture,
                dateEcheance: editableFacture.dateEcheance,
                datePaiement: editableFacture.datePaiement,
                tva: editableFacture.tva,
                conditionsPaiement: editableFacture.conditionsPaiement.rawValue,
                remisePourcentage: editableFacture.remisePourcentage,
                statut: editableFacture.statut.rawValue,
                notes: defaultFactureNote,
                notesCommentaireFacture: editableFacture.notesCommentaireFacture,
                clientId: client.id,
                ligneIds: ligneDTOs.map { $0.id }
            )
            
            await dataService.addFactureDTO(factureDTO)
            dismiss()
        }
    }
}

// MARK: - Modern Progress Header
struct ModernProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let title: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Progress Bar
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? AppTheme.Colors.primary : AppTheme.Colors.border)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.Colors.primary, lineWidth: step == currentStep ? 2 : 0)
                                .frame(width: 16, height: 16)
                        )
                    
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? AppTheme.Colors.primary : AppTheme.Colors.border)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            
            // Title
            Text(title)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
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
}

// MARK: - Modern Empty Clients State
struct ModernEmptyClientsState: View {
    @Binding var showingClientCreation: Bool
    
    var body: some View {
        AppCard {
            VStack(spacing: AppTheme.Spacing.xl) {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.Colors.primaryGradient)
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Aucun client trouvé")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Vous devez d'abord créer un client avant de pouvoir créer une facture.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                AppButton.primary(
                    "Créer un client",
                    icon: "person.badge.plus",
                    size: .large
                ) {
                    showingClientCreation = true
                }
            }
        }
        .frame(maxWidth: 500)
    }
}

// MARK: - Modern Client Selection View
struct ModernClientSelectionView: View {
    let clients: [ClientDTO]
    @Binding var selectedClient: ClientDTO?
    @Binding var searchText: String
    @Binding var showingClientCreation: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Choisissez un client")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("\(clients.count) client\(clients.count > 1 ? "s" : "") disponible\(clients.count > 1 ? "s" : "")")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                AppButton.secondary(
                    "Nouveau client",
                    icon: "person.badge.plus"
                ) {
                    showingClientCreation = true
                }
            }
            
            // Search
            AppTextField(
                "",
                text: $searchText,
                placeholder: "Rechercher un client...",
                icon: "magnifyingglass"
            )
            
            // Clients List
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    ForEach(clients) { client in
                        ModernClientSelectionRow(
                            client: client,
                            isSelected: selectedClient?.id == client.id
                        ) {
                            selectedClient = client
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
        }
    }
}

// MARK: - Modern Client Selection Row
struct ModernClientSelectionRow: View {
    let client: ClientDTO
    let isSelected: Bool
    let onSelect: () -> Void
    
    @EnvironmentObject private var dataService: DataService
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.border)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
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
                
                // Client Info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(client.nomCompletClient)
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if !client.entreprise.isEmpty {
                        Text(client.entreprise)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if !client.email.isEmpty {
                        Text(client.email)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                    let facturesCount = client.facturesCount(from: dataService.factures)
                    Text("\(facturesCount)")
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text("facture\(facturesCount > 1 ? "s" : "")")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(isSelected ? AppTheme.Colors.primaryLight : AppTheme.Colors.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(AppTheme.Animation.spring, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Facture Form View (Placeholder)
struct ModernFactureFormView: View {
    let client: ClientDTO
    let onNext: () -> Void
    
    @State private var editableFacture = EditableFacture()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                Text("Détails de la facture pour \(client.nomCompletClient)")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                // Form content will be implemented here
                AppCard {
                    Text("Form content coming soon...")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(AppTheme.Spacing.xxl)
                }
                
                AppButton.primary("Continuer vers la révision", icon: "arrow.right") {
                    onNext()
                }
            }
        }
    }
}

// MARK: - Modern Facture Review View (Placeholder)
struct ModernFactureReviewView: View {
    let client: ClientDTO
    let onCreate: (EditableFacture) -> Void
    
    @State private var editableFacture = EditableFacture()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                Text("Vérification de la facture")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                // Review content will be implemented here
                AppCard {
                    Text("Review content coming soon...")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(AppTheme.Spacing.xxl)
                }
                
                HStack(spacing: AppTheme.Spacing.md) {
                    AppButton.secondary("Aperçu", icon: "eye") {
                        // Preview action
                    }
                    
                    AppButton.success("Créer la facture", icon: "checkmark.circle") {
                        onCreate(editableFacture)
                    }
                }
            }
        }
    }
}

#Preview {
    ModernAddFactureView()
        .environmentObject(DataService.shared)
}
