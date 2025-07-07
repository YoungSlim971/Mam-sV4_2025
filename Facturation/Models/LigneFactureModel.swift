import Foundation
import SwiftData

@Model
final class LigneFacture {
    @Attribute(.unique) var id: UUID = UUID()
    var designation: String = ""
    var quantite: Double = 1.0
    var prixUnitaire: Double = 0.0
    var referenceCommande: String?
    var dateCommande: Date?
    @Relationship var produit: ProduitModel?
    @Relationship var facture: FactureModel?

    init() {}
    
    init(designation: String = "",
         quantite: Double = 1.0,
         prixUnitaire: Double = 0.0,
         referenceCommande: String? = nil,
         dateCommande: Date? = nil) {
        self.designation = designation
        self.quantite = quantite
        self.prixUnitaire = prixUnitaire
        self.referenceCommande = referenceCommande
        self.dateCommande = dateCommande
    }

    var total: Double {
        quantite * prixUnitaire
    }
    var isValidModel: Bool {
        !designation.isEmpty && quantite > 0 && prixUnitaire >= 0
    }
}


