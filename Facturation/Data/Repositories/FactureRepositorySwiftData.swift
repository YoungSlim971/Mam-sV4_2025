import Foundation
import SwiftData

struct FactureRepositorySwiftData: FactureRepository {
    let context: ModelContext

    func genererNumeroFacture(client: ClientModel) throws -> String {
        // Get the entreprise to use its numbering system
        let entreprises = try context.fetch(FetchDescriptor<EntrepriseModel>())
        guard let entreprise = entreprises.first else {
            let currentDate = Date()
            let currentMonth = Calendar.current.component(.month, from: currentDate)
            let currentYear = Calendar.current.component(.year, from: currentDate) % 100
            let monthStr = String(format: "%02d", currentMonth)
            let yearStr = String(format: "%02d", currentYear)
            let clientInitials = client.initialesFacturation
            return "\(monthStr)/\(yearStr)-0001-\(clientInitials)"
        }
        
        return entreprise.genererNumeroFacture(client: client)
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
