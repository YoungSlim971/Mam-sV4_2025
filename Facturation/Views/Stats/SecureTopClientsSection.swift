import SwiftUI
import Charts
import DataLayer

struct SecureTopClientsSection: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Binding var selectedClient: ClientDTO?
    @State private var hoveredClientID: UUID?
    
    @State private var clientStatistiques: [ClientStatistiqueResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let maxDisplayCount = 8
    
    private var topClients: [ClientStatistiqueResult] {
        Array(clientStatistiques.prefix(maxDisplayCount))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Clients")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(topClients.count) sur \(clientStatistiques.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let errorMessage = errorMessage {
                Text("Erreur: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if topClients.isEmpty && !isLoading {
                Text("Aucun client trouvé")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(topClients) { client in
                        clientInfo(for: client)
                            .background(rowBackground(for: client))
                            .overlay(rowBorder(for: client))
                            .onHover { isHovered in
                                hoveredClientID = isHovered ? client.id : nil
                            }
                            .onTapGesture {
                                selectedClient = client.client
                            }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadClientStatistiques()
            }
        }
    }
    
    // MARK: - Private Views
    
    private func clientInfo(for client: ClientStatistiqueResult) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(clientColor(for: client))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(client.client.nom)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(client.nombreFactures) facture\(client.nombreFactures > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(client.chiffreAffaires.euroFormatted)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func rowBackground(for client: ClientStatistiqueResult) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isClientSelected(client) ? Color.accentColor.opacity(0.1) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: isClientSelected(client))
    }
    
    private func rowBorder(for client: ClientStatistiqueResult) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                isClientSelected(client) ? Color.accentColor : Color.clear,
                lineWidth: isClientSelected(client) ? 1.5 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: isClientSelected(client))
    }
    
    private func clientColor(for client: ClientStatistiqueResult) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .teal, .indigo]
        let index = abs(client.client.nom.hashValue) % colors.count
        return colors[index]
    }
    
    private func isClientSelected(_ client: ClientStatistiqueResult) -> Bool {
        return selectedClient?.id == client.client.id
    }
    
    // MARK: - Private Methods
    
    private func loadClientStatistiques() async {
        isLoading = true
        errorMessage = nil
        
        // Utilise les use cases via DependencyContainer pour obtenir les statistiques
        let result = await dependencyContainer.getStatistiquesUseCase.execute()
        
        switch result {
        case .success(let stats):
            // Pour l'instant, créons des statistiques mock basées sur les données générales
            // Dans une vraie implémentation, nous aurions un use case spécifique pour les clients
            clientStatistiques = await createClientStatistiques()
            
        case .failure(let error):
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func createClientStatistiques() async -> [ClientStatistiqueResult] {
        // Utilise maintenant le vrai use case pour les statistiques de clients
        let result = await dependencyContainer.getStatistiquesClientsUseCase.execute()
        
        switch result {
        case .success(let statistiques):
            return statistiques
        case .failure(let error):
            print("Error loading client statistics: \(error)")
            return []
        }
    }
}

#Preview {
    SecureTopClientsSection(selectedClient: .constant(nil))
        .environmentObject(DependencyContainer.shared)
        .frame(width: 400, height: 500)
}