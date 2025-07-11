import SwiftUI
import DataLayer

struct EditFactureView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Environment(\.dismiss) private var dismiss
    
    let factureDTO: FactureDTO
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(factureDTO: FactureDTO, lignes: [LigneFactureDTO] = [], isReadOnly: Bool = false) {
        self.factureDTO = factureDTO
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Édition de facture")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Facture: \(factureDTO.numero)")
                    .font(.headline)
                
                Text("Cette vue sera migrée vers l'architecture sécurisée")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let errorMessage = errorMessage {
                    Text("Erreur: \(errorMessage)")
                        .foregroundColor(.red)
                }
                
                Button("Fermer") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Édition Facture")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
        }
    }
}

#Preview {
    EditFactureView(factureDTO: FactureDTO(
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
    ))
    .environmentObject(DependencyContainer.shared)
}