import Foundation
import SwiftData

@Model
public final class LigneFacture {
    @Attribute(.unique) public var id: UUID = UUID()
    public var designation: String = ""
    public var quantite: Double = 1.0
    public var prixUnitaire: Double = 0.0
    public var referenceCommande: String?
    public var dateCommande: Date?
    @Relationship public var produit: ProduitModel?
    @Relationship public var facture: FactureModel?

    public init() {}
    
    public init(designation: String = "",
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

    public var total: Double {
        quantite * prixUnitaire
    }
    public var isValidModel: Bool {
        !designation.isEmpty && quantite > 0 && prixUnitaire >= 0
    }
}


