import Foundation
import SwiftData

struct FactureRepositorySwiftData: FactureRepository {
    let context: ModelContext

    func genererNumeroFacture() throws -> String {
        let count = try context.fetch(FetchDescriptor<FactureModel>()).count
        return String(format: "FAC-%04d", count + 1)
    }

    func createFacture(client: ClientModel, numero: String) throws -> FactureModel {
        let facture = FactureModel(client: client, numero: numero)
        context.insert(facture)
        try context.save()
        return facture
    }

    func addLigne(facture: FactureModel, designation: String, quantite: Double, prixUnitaire: Double) throws -> LigneFacture {
        let ligne = LigneFacture(designation: designation, quantite: quantite, prixUnitaire: prixUnitaire)
        context.insert(ligne)
        ligne.facture = facture
        facture.lignes.append(ligne)
        try context.save()
        return ligne
    }
}
