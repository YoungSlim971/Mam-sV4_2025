import Foundation
import SwiftData
import DataLayer

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

// MARK: - Extension de conversion LigneFacture <-> LigneFactureDTO
extension LigneFacture {
    func toDTO() -> LigneFactureDTO {
        return LigneFactureDTO(
            id: self.id,
            designation: self.designation,
            quantite: self.quantite,
            prixUnitaire: self.prixUnitaire,
            referenceCommande: self.referenceCommande,
            dateCommande: self.dateCommande,
            produitId: self.produit?.id,
            factureId: self.facture?.id
        )
    }

    static func fromDTO(_ dto: LigneFactureDTO) -> LigneFacture {
        let ligne = LigneFacture()
        ligne.id = dto.id
        ligne.designation = dto.designation
        ligne.quantite = dto.quantite
        ligne.prixUnitaire = dto.prixUnitaire
        ligne.referenceCommande = dto.referenceCommande
        ligne.dateCommande = dto.dateCommande
        return ligne
    }

    func updateFromDTO(_ dto: LigneFactureDTO) {
        designation = dto.designation
        quantite = dto.quantite
        prixUnitaire = dto.prixUnitaire
        referenceCommande = dto.referenceCommande
        dateCommande = dto.dateCommande
    }
}


