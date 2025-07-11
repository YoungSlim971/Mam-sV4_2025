// Views/Clients/SecureClientsView.swift
import SwiftUI
import DataLayer

struct SecureClientsView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Binding var searchText: String
    
    @State private var showingAddClient = false
    @State private var clientToEdit: ClientDTO?
    @State private var clientToDetail: ClientDTO?
    @State private var sortOrder = ClientsView.SortOrder.nom
    
    @State private var clients: [ClientDTO] = []
    @State private var factures: [FactureDTO] = []
    @State private var lignes: [LigneFactureDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    
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
                ClientsList(
                    clients: sortedClients,
                    factures: factures,
                    lignes: [],
                    onSelectClient: { client in clientToDetail = client },
                    onEditClient: { client in clientToEdit = client },
                    onAddClient: { showingAddClient = true },
                    onDeleteClient: { client in
                        Task {
                            await deleteClient(client.id)
                        }
                    }
                )
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
        .sheet(isPresented: $showingAddClient) { 
            SecureAddClientView(onClientAdded: { client in
                await addClient(client)
            })
        }
        .sheet(item: $clientToEdit) { client in 
            SecureEditClientView(
                client: client,
                factures: factures,
                lignes: lignes,
                onUpdate: { updatedClient in
                    await updateClient(updatedClient)
                },
                onDelete: { clientId in
                    await deleteClient(clientId)
                }
            )
        }
        .sheet(item: $clientToDetail) { client in 
            SecureClientDetailView(client: client)
                .environmentObject(dependencyContainer)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let clientsResult = dependencyContainer.fetchClientsUseCase.execute()
        async let facturesResult = dependencyContainer.fetchFacturesUseCase.execute()
        async let lignesResult = dependencyContainer.fetchLignesUseCase.execute()
        
        let (clientsRes, facturesRes, lignesRes) = await (clientsResult, facturesResult, lignesResult)
        
        switch clientsRes {
        case .success(let fetchedClients):
            clients = fetchedClients
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des clients: \(error.localizedDescription)"
        }
        
        switch facturesRes {
        case .success(let fetchedFactures):
            factures = fetchedFactures
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des factures: \(error.localizedDescription)"
        }
        
        switch lignesRes {
        case .success(let fetchedLignes):
            lignes = fetchedLignes
        case .failure(let error):
            errorMessage = "Erreur lors du chargement des lignes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func addClient(_ client: ClientDTO) async {
        let result = await dependencyContainer.addClientUseCase.execute(
            nom: client.nom,
            prenom: client.entreprise, // Using entreprise as prenom fallback
            email: client.email,
            telephone: client.telephone,
            adresse: client.adresseRue,
            ville: client.adresseVille,
            codePostal: client.adresseCodePostal,
            pays: client.adressePays,
            siret: client.siret,
            tva: client.numeroTVA
        )
        
        switch result {
        case .success(_):
            await loadData()
        case .failure(let error):
            errorMessage = "Erreur lors de l'ajout du client: \(error.localizedDescription)"
        }
    }
    
    private func updateClient(_ client: ClientDTO) async {
        let result = await dependencyContainer.updateClientUseCase.execute(client: client)
        
        switch result {
        case .success(_):
            await loadData()
        case .failure(let error):
            errorMessage = "Erreur lors de la mise à jour du client: \(error.localizedDescription)"
        }
    }
    
    private func deleteClient(_ clientId: UUID) async {
        let result = await dependencyContainer.deleteClientUseCase.execute(clientId: clientId)
        
        switch result {
        case .success(_):
            await loadData()
        case .failure(let error):
            errorMessage = "Erreur lors de la suppression du client: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SecureClientsView(searchText: .constant(""))
        .environmentObject(DependencyContainer.shared)
}