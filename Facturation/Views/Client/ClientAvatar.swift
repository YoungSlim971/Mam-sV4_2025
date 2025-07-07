// Views/Clients/ClientAvatar.swift
import SwiftUI

struct ClientAvatar: View {
    let client: ClientDTO

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)

            if client.entreprise.isEmpty {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
}

