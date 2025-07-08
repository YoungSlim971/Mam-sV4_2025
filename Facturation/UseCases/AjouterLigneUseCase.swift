import Foundation
import DataLayer

enum LigneFactureError: Error {
    case invalidQuantite
    case invalidPrix
}

struct AjouterLigneUseCase {
    let repository: FactureRepository

    func execute(facture: FactureModel, designation: String, quantite: Double, prixUnitaire: Double) throws -> LigneFacture {
        guard quantite > 0 else { throw LigneFactureError.invalidQuantite }
        guard prixUnitaire >= 0 else { throw LigneFactureError.invalidPrix }
        return try repository.addLigne(facture: facture, designation: designation, quantite: quantite, prixUnitaire: prixUnitaire)
    }
}
