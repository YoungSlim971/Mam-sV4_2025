import SwiftUI
import Charts

struct TopClientsSection: View {
    let clients: [StatistiquesService.ClientStatistique]
    @Binding var selectedClient: ClientDTO?
    @State private var hoveredClientID: UUID?
    
    private let maxDisplayCount = 8
    
    private var topClients: [StatistiquesService.ClientStatistique] {
        Array(clients.prefix(maxDisplayCount))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Clients")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(topClients.count) sur \(clients.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if topClients.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart(topClients, id: \.id) { client in
            BarMark(
                x: .value("Chiffre d'affaires", client.total),
                y: .value("Client", client.nom),
                height: 24
            )
            .foregroundStyle(clientColor(for: client))
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String.euroFormatted(doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
        }
        .frame(height: CGFloat(topClients.count * 40 + 60))
        .onTapGesture { location in
            handleChartTap(at: location)
        }
        .overlay(
            hoverOverlay
        )
    }
    
    // MARK: - ViewBuilder Helpers
    
    @ViewBuilder
    private func rankingBadge(for index: Int) -> some View {
        Text("\(index + 1)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(rankingColor(for: index))
            .clipShape(Circle())
    }
    
    @ViewBuilder
    private func clientInfo(for client: StatistiquesService.ClientStatistique) -> some View {
        HStack {
            Text(client.nom)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
            
            Text(String.euroFormatted(client.total))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(StatsColorProvider.chartPrimary)
        }
    }
    
    @ViewBuilder
    private func rowBackground(for client: StatistiquesService.ClientStatistique) -> some View {
        Rectangle()
            .fill(isClientHovered(client) ? Color.accentColor.opacity(0.1) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: hoveredClientID)
    }
    
    @ViewBuilder
    private func rowBorder(for client: StatistiquesService.ClientStatistique) -> some View {
        Rectangle()
            .stroke(
                isClientSelected(client) ? Color.accentColor : Color.clear,
                lineWidth: 2
            )
            .animation(.easeInOut(duration: 0.2), value: selectedClient?.id)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Aucun client trouvé")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Les statistiques apparaîtront ici une fois que vous aurez des factures payées.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    @ViewBuilder
    private var hoverOverlay: some View {
        if let hoveredID = hoveredClientID,
           let hoveredClient = topClients.first(where: { $0.id == hoveredID }) {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hoveredClient.nom)
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text("CA: \(String.euroFormatted(hoveredClient.total))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(.regularMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                }
            }
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Helper Methods
    
    private func clientColor(for client: StatistiquesService.ClientStatistique) -> Color {
        // Utilise un UUID basé sur le hash du nom pour la cohérence des couleurs
        let clientUUID = UUID(uuidString: client.nom.simpleHash) ?? UUID()
        let baseColor = StatsColorProvider.accessibleColorForClient(id: clientUUID)
        
        if isClientSelected(client) {
            return baseColor
        } else if isClientHovered(client) {
            return baseColor.opacity(0.8)
        } else {
            return baseColor.opacity(0.6)
        }
    }
    
    private func rankingColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.yellow // Or
        case 1: return Color.gray // Argent
        case 2: return Color.orange // Bronze
        default: return Color.blue
        }
    }
    
    private func isClientSelected(_ client: StatistiquesService.ClientStatistique) -> Bool {
        // Compare par nom car ClientStatistique n'a pas d'UUID direct
        return selectedClient?.raisonSociale == client.nom
    }
    
    private func isClientHovered(_ client: StatistiquesService.ClientStatistique) -> Bool {
        let clientUUID = UUID(uuidString: client.nom.simpleHash) ?? UUID()
        return hoveredClientID == clientUUID
    }
    
    private func handleChartTap(at location: CGPoint) {
        // Logique simplifiée pour la sélection via tap
        // Dans une implémentation réelle, on calculerait quelle barre a été touchée
        if !topClients.isEmpty {
            // Pour l'instant, on ne peut pas facilement mapper selectedClient depuis ClientStatistique
            // Cette fonctionnalité nécessiterait une refonte de l'architecture des données
        }
    }
    
    private func clientAccessibilityLabel(_ client: StatistiquesService.ClientStatistique) -> String {
        let position = (topClients.firstIndex(where: { $0.id == client.id }) ?? 0) + 1
        return "Client \(position): \(client.nom), chiffre d'affaires: \(String.accessibilityEuroDescription(client.total))"
    }
}

// MARK: - String Hash Extension (pour UUID cohérent)

extension String {
    var simpleHash: String {
        // Implémentation simplifiée pour générer un hash cohérent
        let hash = abs(self.hashValue)
        return String(format: "%08X-%04X-%04X-%04X-%012X", 
                     hash & 0xFFFFFFFF,
                     (hash >> 32) & 0xFFFF,
                     ((hash >> 48) & 0x0FFF) | 0x4000,
                     ((hash >> 60) & 0x3FFF) | 0x8000,
                     hash & 0xFFFFFFFFFFFF)
    }
}

// MARK: - Preview

#if DEBUG
struct TopClientsSection_Previews: PreviewProvider {
    @State static var selectedClient: ClientDTO? = nil
    
    static var previews: some View {
        TopClientsSection(
            clients: [
                StatistiquesService.ClientStatistique(nom: "Carrefour Marseille", total: 25000.0),
                StatistiquesService.ClientStatistique(nom: "Leclerc Lyon", total: 18500.0),
                StatistiquesService.ClientStatistique(nom: "Super U Nantes", total: 15750.0),
                StatistiquesService.ClientStatistique(nom: "Intermarché Bordeaux", total: 12300.0),
                StatistiquesService.ClientStatistique(nom: "Casino Toulouse", total: 9800.0)
            ],
            selectedClient: $selectedClient
        )
        .frame(width: 400, height: 300)
        .padding()
    }
}
#endif