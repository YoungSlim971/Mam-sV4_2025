// Views/Clients/ClientsList.swift
import SwiftUI
import DataLayer

struct ClientsList: View {
    let clients: [ClientDTO]
    let factures: [FactureDTO]
    let lignes: [LigneFactureDTO]
    var onSelectClient: (ClientDTO) -> Void
    var onEditClient: (ClientDTO) -> Void
    var onAddClient: () -> Void

    var body: some View {
        ScrollView {
            if clients.isEmpty {
                EmptyClientsView(onAddClient: onAddClient)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(clients) { client in
                        ClientRowView(
                            client: client, 
                            factures: factures, 
                            lignes: lignes,
                            onEdit: { onEditClient(client) }
                        )
                        .onTapGesture { onSelectClient(client) }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

