import Foundation

protocol FactureRepository {
    func genererNumeroFacture(client: ClientModel) throws -> String
    func createFacture(client: ClientModel, numero: String) throws -> FactureModel
    func addLigne(facture: FactureModel, designation: String, quantite: Double, prixUnitaire: Double) throws -> LigneFacture
}
