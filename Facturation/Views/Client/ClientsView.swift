// Views/Clients/ClientsView.swift
import SwiftUI
import DataLayer
struct ClientsView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Binding var searchText: String

    @State private var showingAddClient = false
    @State private var clientToEdit: ClientDTO?
    @State private var clientToDetail: ClientDTO?
    @State private var sortOrder = SortOrder.nom
    @State private var clients: [ClientDTO] = []
    @State private var factures: [FactureDTO] = []
    @State private var lignes: [LigneFactureDTO] = []
    @State private var isLoading = true

    enum SortOrder: String, CaseIterable {
        case nom = "Nom (A-Z)"
        case nomDesc = "Nom (Z-A)"
        case entreprise = "Entreprise (A-Z)"
        case facturesDesc = "Factures (plus)"
        case caDesc = "CA (élevé)"

        func sort(_ clients: [ClientDTO], factures: [FactureDTO], lignes: [LigneFactureDTO]) -> [ClientDTO] {
            switch self {
            case .nom:
                return clients.sorted { $0.nom.localizedCaseInsensitiveCompare($1.nom) == .orderedAscending }
            case .nomDesc:
                return clients.sorted { $0.nom.localizedCaseInsensitiveCompare($1.nom) == .orderedDescending }
            case .entreprise:
                return clients.sorted { $0.entreprise.localizedCaseInsensitiveCompare($1.entreprise) == .orderedAscending }
            case .facturesDesc:
                return clients.sorted { $0.facturesCount(from: factures) > $1.facturesCount(from: factures) }
            case .caDesc:
                return clients.sorted { $0.chiffreAffaires(from: factures, lignes: lignes) > $1.chiffreAffaires(from: factures, lignes: lignes) }
            }
        }
    }

    var filteredClients: [ClientDTO] {
        guard !searchText.isEmpty else {
            return clients
        }
        return clients.filter { client in
            client.nom.localizedCaseInsensitiveContains(searchText) ||
            client.entreprise.localizedCaseInsensitiveContains(searchText) ||
            client.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var sortedClients: [ClientDTO] {
        sortOrder.sort(filteredClients, factures: factures, lignes: lignes)
    }

    var body: some View {
        VStack(spacing: 0) {
            ClientsHeaderView(showingAddClient: $showingAddClient)
            ClientFilterBar(sortOrder: $sortOrder, clientsCount: sortedClients.count)
            if isLoading {
                ProgressView("Chargement des clients...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ClientsList(
                    clients: sortedClients,
                    factures: factures,
                    lignes: lignes,
                    onSelectClient: { client in clientToDetail = client },
                    onEditClient: { client in clientToEdit = client },
                    onAddClient: { showingAddClient = true },
                    onDeleteClient: { client in
                        Task {
                            let result = await dependencyContainer.deleteClientUseCase.execute(clientId: client.id)
                            if case .success = result {
                                await loadData()
                            }
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingAddClient) { 
            AddClientView(onCreate: { client in
                let result = await dependencyContainer.addClientUseCase.execute(
                    nom: client.nom,
                    prenom: client.entreprise,
                    email: client.email,
                    telephone: client.telephone,
                    adresse: client.adresse,
                    ville: client.adresseVille,
                    codePostal: client.adresseCodePostal,
                    pays: client.adressePays,
                    siret: client.siret,
                    tva: client.numeroTVA
                )
                if case .success = result {
                    await loadData()
                }
            })
        }
        .sheet(item: $clientToEdit) { client in 
            EditClientView(
                client: client,
                factures: factures,
                lignes: lignes,
                onUpdate: { updatedClient in
                    let result = await dependencyContainer.updateClientUseCase.execute(client: updatedClient)
                    if case .success = result {
                        await loadData()
                    }
                },
                onDelete: { clientId in
                    let result = await dependencyContainer.deleteClientUseCase.execute(clientId: clientId)
                    if case .success = result {
                        await loadData()
                    }
                }
            )
        }
        .sheet(item: $clientToDetail) { client in SecureClientDetailView(client: client) }
        .onAppear {
            Task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        async let clientsResult = dependencyContainer.fetchClientsUseCase.execute()
        async let facturesResult = dependencyContainer.fetchFacturesUseCase.execute()
        async let lignesResult = dependencyContainer.fetchLignesUseCase.execute()
        
        let (clientsRes, facturesRes, lignesRes) = await (clientsResult, facturesResult, lignesResult)
        
        if case .success(let clientsData) = clientsRes {
            clients = clientsData
        }
        
        if case .success(let facturesData) = facturesRes {
            factures = facturesData
        }
        
        if case .success(let lignesData) = lignesRes {
            lignes = lignesData
        }
        
        isLoading = false
    }
}



#Preview {
    ClientsView(searchText: .constant(""))
        .environmentObject(DependencyContainer.shared)
}
