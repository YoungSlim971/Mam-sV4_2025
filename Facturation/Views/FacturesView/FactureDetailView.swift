import SwiftUI
import DataLayer

struct FactureDetailView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    let facture: FactureDTO
    
    @State private var client: ClientDTO?
    @State private var lignes: [LigneFactureDTO] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    basicInfoSection
                    linesSection
                    totalsSection
                    notesSection
                }
                .padding()
            }
        }
        .navigationTitle("Facture \(facture.numero)")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer") { dismiss() }
            }
        }
        .onAppear {
            Task {
                await loadFactureDetails()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Facture n°\(facture.numero)")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Client: \(client?.nomCompletClient ?? "Inconnu")")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }

    private var basicInfoSection: some View {
        Group {
            Text("Informations")
                .font(.title2)
                .fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 8) {
                Text("Date facture: \(facture.dateFacture.frenchFormatted)")
                if let echeance = facture.dateEcheance {
                    Text("Échéance: \(echeance.frenchFormatted)")
                }
                if let paiement = facture.datePaiement {
                    Text("Payée le: \(paiement.frenchFormatted)")
                }
                Text("Statut: \(facture.statut)")
            }
        }
    }

    private var linesSection: some View {
        Group {
            Text("Détail de la facture")
                .font(.title2)
                .fontWeight(.semibold)
            VStack(spacing: 8) {
                ForEach(Array(lignes.enumerated()), id: \.element.id) { index, ligne in
                    InvoiceLineRowImproved(ligne: ligne, isEven: index % 2 == 0)
                }
            }
        }
    }

    private var totalsSection: some View {
        Group {
            Text("Totaux")
                .font(.title2)
                .fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Sous-total HT")
                    Spacer()
                    Text(facture.calculateSousTotal(with: lignes).euroFormatted)
                }
                HStack {
                    Text("TVA")
                    Spacer()
                    Text(facture.calculateMontantTVA(with: lignes).euroFormatted)
                }
                HStack {
                    Text("Total TTC")
                        .fontWeight(.bold)
                    Spacer()
                    Text(facture.calculateTotalTTC(with: lignes).euroFormatted)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
    }

    private var notesSection: some View {
        Group {
            if !facture.notes.isEmpty {
                Text("Notes")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(facture.notes)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if let comment = facture.notesCommentaireFacture, !comment.isEmpty {
                Text("Commentaire")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(comment)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func loadFactureDetails() async {
        isLoading = true
        
        // Charger le client
        let clientResult = await dependencyContainer.getClientUseCase.execute(clientId: facture.clientId)
        if case .success(let clientData) = clientResult {
            client = clientData
        }
        
        // Charger les lignes
        let lignesResult = await dependencyContainer.fetchLignesUseCase.execute()
        if case .success(let lignesData) = lignesResult {
            lignes = lignesData
        }
        
        isLoading = false
    }
}

#Preview {
    FactureDetailView(facture: FactureDTO(id: UUID(), numero: "TEST", dateFacture: Date(), dateEcheance: nil, datePaiement: nil, tva: 20, conditionsPaiement: "virement", remisePourcentage: 0, statut: "Brouillon", notes: "", notesCommentaireFacture: nil, clientId: UUID(), ligneIds: []))
        .environmentObject(DependencyContainer.shared)
}
