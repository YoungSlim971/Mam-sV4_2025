// Views/Clients/ClientRowView.swift
import SwiftUI
import DataLayer

struct ClientRowView: View {
    let client: ClientDTO
    let factures: [FactureDTO]
    let lignes: [LigneFactureDTO]
    var onEdit: () -> Void
    @State private var isHovered = false
    @State private var showingDeleteAlert = false
    @EnvironmentObject private var dataService: DataService

    var body: some View {
        HStack(spacing: 15) {
            ClientAvatar(client: client)

            VStack(alignment: .leading, spacing: 4) {
                Text(client.nomCompletClient)
                    .font(.headline)
                    .fontWeight(.semibold)

                if !client.email.isEmpty {
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if !client.adresseVille.isEmpty {
                    HStack {
                        Image(systemName: "location.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(client.adresseCodePostal) \(client.adresseVille)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(client.facturesCount(from: factures))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("facture\(client.facturesCount(from: factures) > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                let chiffreAffaires = client.chiffreAffaires(from: factures, lignes: lignes)
                if chiffreAffaires > 0 {
                    Text("\(chiffreAffaires) EUR")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 5)

            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemBackground)
                .shadow(
                    color: .black.opacity(isHovered ? 0.1 : 0.05),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .alert("Supprimer le client ?", isPresented: $showingDeleteAlert) {
            Button("Supprimer", role: .destructive) {
                Task { await dataService.deleteClientDTO(id: client.id) }
            }
            Button("Annuler", role: .cancel) { }
        }
    }
}

