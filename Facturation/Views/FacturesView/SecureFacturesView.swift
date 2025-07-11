import SwiftUI
import DataLayer

struct SecureFacturesView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Binding var searchText: String
    
    @State private var selectedFactures = Set<UUID>()
    @State private var showingAddFacture = false
    @State private var showingBulkActions = false
    @State private var selectedFilter: FactureFilter = .all
    @State private var sortOrder: SortOrder = .dateDesc
    @State private var viewMode: ViewMode = .grid
    
    @State private var factures: [FactureDTO] = []
    @State private var clients: [ClientDTO] = []
    @State private var lignes: [LigneFactureDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
        case clientAsc = "Client (A-Z)"
        case clientDesc = "Client (Z-A)"
    }
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grille"
        case list = "Liste"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var filteredFactures: [FactureDTO] {
        let searchFiltered = searchText.isEmpty ? factures : factures.filter { facture in
            facture.numero.localizedCaseInsensitiveContains(searchText) ||
            facture.notes.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case .all: return searchFiltered
        case .draft: return searchFiltered.filter { $0.statut == "brouillon" }
        case .sent: return searchFiltered.filter { $0.statut == "envoyee" }
        case .paid: return searchFiltered.filter { $0.statut == "payee" }
        case .overdue: return searchFiltered.filter { $0.statut == StatutFacture.enRetard.rawValue }
        case .cancelled: return searchFiltered.filter { $0.statut == "annulee" }
        }
    }
    
    var sortedFactures: [FactureDTO] {
        switch sortOrder {
        case .dateDesc:
            return filteredFactures.sorted { $0.dateFacture > $1.dateFacture }
        case .dateAsc:
            return filteredFactures.sorted { $0.dateFacture < $1.dateFacture }
        case .numberDesc:
            return filteredFactures.sorted { $0.numero > $1.numero }
        case .numberAsc:
            return filteredFactures.sorted { $0.numero < $1.numero }
        case .amountDesc:
            return filteredFactures.sorted { $0.calculateTotalTTC(with: lignes) > $1.calculateTotalTTC(with: lignes) }
        case .amountAsc:
            return filteredFactures.sorted { $0.calculateTotalTTC(with: lignes) < $1.calculateTotalTTC(with: lignes) }
        case .clientAsc:
            return filteredFactures.sorted { clientName(for: $0.clientId) < clientName(for: $1.clientId) }
        case .clientDesc:
            return filteredFactures.sorted { clientName(for: $0.clientId) > clientName(for: $1.clientId) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with actions
            HStack {
                Text("Factures (\(sortedFactures.count))")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Nouvelle facture") {
                    showingAddFacture = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Filter bar
            HStack {
                Picker("Filtre", selection: $selectedFilter) {
                    ForEach(FactureFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
                
                Picker("Tri", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .frame(width: 150)
            }
            .padding(.horizontal)
            
            if isLoading {
                ProgressView("Chargement des factures...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Erreur: \(errorMessage)")
                        .foregroundColor(.red)
                    Button("Réessayer") {
                        Task {
                            await loadData()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Simple list view for all factures
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedFactures, id: \.id) { facture in
                            FactureRowView(
                                facture: facture,
                                clientName: clientName(for: facture.clientId),
                                isSelected: selectedFactures.contains(facture.id),
                                onToggleSelection: {
                                    if selectedFactures.contains(facture.id) {
                                        selectedFactures.remove(facture.id)
                                    } else {
                                        selectedFactures.insert(facture.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
        .sheet(isPresented: $showingAddFacture) {
            SecureAddFactureView(
                clients: clients,
                onFactureAdded: { facture in
                    await addFacture(facture)
                }
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let facturesResult = dependencyContainer.fetchFacturesUseCase.execute()
        async let clientsResult = dependencyContainer.fetchClientsUseCase.execute()
        async let lignesResult = dependencyContainer.fetchLignesUseCase.execute()
        
        let (facturesRes, clientsRes, lignesRes) = await (facturesResult, clientsResult, lignesResult)
        
        switch facturesRes {
        case .success(let fetchedFactures):
            factures = fetchedFactures
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des factures: \(error.localizedDescription)"
        }
        
        switch clientsRes {
        case .success(let fetchedClients):
            clients = fetchedClients
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des clients: \(error.localizedDescription)"
        }
        
        switch lignesRes {
        case .success(let fetchedLignes):
            lignes = fetchedLignes
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des lignes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func addFacture(_ facture: FactureDTO) async {
        let result = await dependencyContainer.createFactureUseCase.execute(
            clientId: facture.clientId,
            tva: facture.tva
        )
        
        switch result {
        case .success(_):
            await loadData()
        case .failure(let error):
            errorMessage = "Erreur lors de la création de la facture: \(error.localizedDescription)"
        }
    }
    
    private func updateFacture(_ facture: FactureDTO) async {
        let result = await dependencyContainer.updateFactureUseCase.execute(facture: facture)
        
        switch result {
        case .success(_):
            await loadData()
        case .failure(let error):
            errorMessage = "Erreur lors de la mise à jour de la facture: \(error.localizedDescription)"
        }
    }
    
    private func deleteFacture(_ factureId: UUID) async {
        let result = await dependencyContainer.deleteFactureUseCase.execute(factureId: factureId)
        
        switch result {
        case .success(_):
            await loadData()
        case .failure(let error):
            errorMessage = "Erreur lors de la suppression de la facture: \(error.localizedDescription)"
        }
    }
    
    private func clientName(for clientId: UUID) -> String {
        if let client = clients.first(where: { $0.id == clientId }) {
            return "\(client.nom) - \(client.entreprise)"
        }
        return "Client inconnu"
    }
}

// Simple row view for factures
struct FactureRowView: View {
    let facture: FactureDTO
    let clientName: String
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    var body: some View {
        AppCard {
            HStack {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(facture.numero)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(clientName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(facture.dateFacture.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total à calculer") // Will be fixed when lignes are available
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(facture.statut)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(4)
                }
            }
            .padding()
        }
    }
}

#Preview {
    SecureFacturesView(searchText: .constant(""))
        .environmentObject(DependencyContainer.shared)
}