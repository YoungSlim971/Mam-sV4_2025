// Views/Clients/ClientsView.swift
import SwiftUI
struct ClientsView: View {
    @EnvironmentObject private var dataService: DataService
    @Binding var searchText: String

    @State private var showingAddClient = false
    @State private var clientToEdit: ClientDTO?
    @State private var clientToDetail: ClientDTO?
    @State private var sortOrder = SortOrder.nom

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
        let allClients: [ClientDTO] = dataService.clients
        guard !searchText.isEmpty else {
            return allClients
        }
        return allClients.filter { client in
            client.nom.localizedCaseInsensitiveContains(searchText) ||
            client.entreprise.localizedCaseInsensitiveContains(searchText) ||
            client.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var sortedClients: [ClientDTO] {
        sortOrder.sort(filteredClients, factures: dataService.factures, lignes: dataService.lignes)
    }

    var body: some View {
        VStack(spacing: 0) {
            ClientsHeaderView(showingAddClient: $showingAddClient)
            ClientFilterBar(sortOrder: $sortOrder, clientsCount: sortedClients.count)
            ClientsList(
                clients: sortedClients,
                factures: dataService.factures,
                lignes: dataService.lignes,
                onSelectClient: { client in clientToDetail = client },
                onEditClient: { client in clientToEdit = client },
                onAddClient: { showingAddClient = true }
            )
        }
        .sheet(isPresented: $showingAddClient) { 
            AddClientView { client in
                await dataService.addClientDTO(client)
            }
        }
        .sheet(item: $clientToEdit) { client in 
            EditClientView(
                client: client,
                factures: dataService.factures,
                lignes: dataService.lignes,
                onUpdate: { updatedClient in
                    await dataService.updateClientDTO(updatedClient)
                },
                onDelete: { clientId in
                    await dataService.deleteClientDTO(id: clientId)
                }
            )
        }
        .sheet(item: $clientToDetail) { client in ClientDetailView(client: client) }
    }
}



#Preview {
    ClientsView(searchText: .constant(""))
        .environmentObject(DataService.shared)
}
