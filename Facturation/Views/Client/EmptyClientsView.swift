// Views/Clients/EmptyClientsView.swift
import SwiftUI

struct EmptyClientsView: View {
    @State private var showingAddClient = false
    
    // Callback pour la création d'un client
    let onAddClient: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))

            VStack(spacing: 8) {
                Text("Aucun client")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Créez votre premier client pour commencer à gérer vos relations commerciales")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: onAddClient) {
                Label("Créer un client", systemImage: "person.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

