import SwiftUI
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
                    Text("Liste complète des factures")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
            }

            if filteredFactures.isEmpty {
                VStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Aucune facture")
                        .font(.headline)
                    Text("Créez votre première facture pour commencer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(filteredFactures.prefix(5).enumerated()), id: \.element.id) { index, facture in
                        RecentFactureRow(facture: facture)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct RecentFactureRow: View {
    let facture: FactureDTO
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(facture.numero)
                    .font(.headline)
                
                Text("Client: \(facture.clientId.uuidString.prefix(8))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(facture.dateFacture.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Montant") // TODO: Calculer le montant réel
                    .font(.headline)
                
                Text(facture.statut.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    RecentFacturesSection(
        factures: [
            FactureDTO(
                id: UUID(),
                numero: "FAC001",
                dateFacture: Date(),
                dateEcheance: nil,
                datePaiement: nil,
                tva: 20.0,
                conditionsPaiement: ConditionsPaiement.virement.rawValue,
                remisePourcentage: 0.0,
                statut: StatutFacture.brouillon.rawValue,
                notes: "",
                notesCommentaireFacture: nil,
                clientId: UUID(),
                ligneIds: []
            )
        ],
        selectedInvoiceStatusFilter: .constant(nil)
    )
}