import SwiftUI
import AppKit
import DataLayer

struct RecentFacturesSection: View {
    let factures: [FactureDTO]
    @Binding var selectedInvoiceStatusFilter: StatutFacture?

    var filteredFactures: [FactureDTO] {
        if let filter = selectedInvoiceStatusFilter {
            return factures.filter { $0.statut == filter.rawValue }
        } else {
            return factures
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Factures Récentes")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                NavigationLink("Voir tout") {
                    // Navigation vers la liste complète des factures
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
            }

            if filteredFactures.isEmpty {
                EmptyStateView(
                    icon: "doc.text.fill",
                    title: "Aucune facture",
                    description: "Créez votre première facture pour commencer"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredFactures) { facture in
                        FactureRowCompact(facture: facture)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct FactureRowCompact: View {
    let facture: FactureDTO
    @EnvironmentObject private var dataService: DataService

    private var clientName: String {
        dataService.clients.first(where: { $0.id == facture.clientId })?.nomCompletClient ?? "Client inconnu"
    }

    private var totalTTC: Double {
        facture.calculateTotalTTC(with: dataService.lignes)
    }

    private var statut: StatutFacture {
        StatutFacture(rawValue: facture.statut) ?? .brouillon
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(facture.numero)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(clientName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(totalTTC.euroFormatted)
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Circle()
                        .fill(statut.color)
                        .frame(width: 6, height: 6)

                    Text(statut.rawValue)
                        .font(.caption)
                        .foregroundColor(statut.color)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    RecentFacturesSection(factures: [], selectedInvoiceStatusFilter: .constant(nil))
        .environmentObject(DataService.shared)
}