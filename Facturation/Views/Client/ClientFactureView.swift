import SwiftUI
import DataLayer

@MainActor
class ClientFactureViewModel: ObservableObject {
    @Published var facture: FactureDTO?
    @Published var localDateEcheance: Date
    @Published var localStatut: StatutFacture

    private let dataService: DataService

    init(factureID: UUID, dataService: DataService = .shared) {
        self.dataService = dataService
        self.facture = nil
        self.localDateEcheance = Date()
        self.localStatut = .brouillon

        Task {
            if let dto = dataService.factures.first(where: { $0.id == factureID }) {
                await MainActor.run {
                    self.facture = dto
                    self.localDateEcheance = dto.dateEcheance ?? Date()
                    self.localStatut = StatutFacture(rawValue: dto.statut) ?? .brouillon
                }
            }
        }
    }

    func validateFacture() {
        // Implémentation de la validation
    }

    func saveChanges() {
        // Implémentation de la sauvegarde des modifications
    }
}
