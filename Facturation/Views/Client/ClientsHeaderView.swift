// Views/Clients/ClientsHeaderView.swift
import SwiftUI

struct ClientsHeaderView: View {
    @Binding var showingAddClient: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Clients")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Gérez vos clients")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showingAddClient = true }) {
                Label("Nouveau Client", systemImage: "person.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

