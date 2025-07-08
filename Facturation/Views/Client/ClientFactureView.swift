import SwiftUI
import SwiftData
import DataLayer

@MainActor
class ClientFactureViewModel: ObservableObject {
    @Published var facture: FactureModel?
    @Published var localDateEcheance: Date
    @Published var localStatut: StatutFacture

    init(factureID: UUID, modelContext: ModelContext) {
        if let facture = try? modelContext.fetch(FetchDescriptor<FactureModel>(predicate: #Predicate { $0.id == factureID })).first {
            self.facture = facture
            self.localDateEcheance = facture.dateEcheance ?? Date()
            self.localStatut = facture.statut
        } else {
            self.facture = nil
            self.localDateEcheance = Date()
            self.localStatut = .brouillon
        }
    }

    func validateFacture() {
        // Implémentation de la validation
    }

    func saveChanges() {
        // Implémentation de la sauvegarde des modifications
    }
}
