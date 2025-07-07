import Foundation

struct LigneFactureDTO: Codable, Identifiable {
    let id: UUID
    var designation: String
    var quantite: Double
    var prixUnitaire: Double
    var referenceCommande: String?
    var dateCommande: Date?
    var produitId: UUID?
    var factureId: UUID?
    
    init(
        id: UUID,
               designation: String,
               quantite: Double,
               prixUnitaire: Double,
               referenceCommande: String? = nil,
               dateCommande: Date? = nil,
               produitId: UUID? = nil,
               factureId: UUID? = nil
           ) {
               self.id = id
                       self.designation = designation
                       self.quantite = quantite
                       self.prixUnitaire = prixUnitaire
                       self.referenceCommande = referenceCommande
                       self.dateCommande = dateCommande
                       self.produitId = produitId
                       self.factureId = factureId
                   }
    
    var total: Double {
        quantite * prixUnitaire
    }

    init(from model: LigneFacture) {
        self.id = model.id
        self.designation = model.designation
        self.quantite = model.quantite
        self.prixUnitaire = model.prixUnitaire
        self.referenceCommande = model.referenceCommande
        self.dateCommande = model.dateCommande
        self.produitId = model.produit?.id
        self.factureId = model.facture?.id
    }
}

extension LigneFacture {
    func toDTO() -> LigneFactureDTO {
        LigneFactureDTO(
            id: id,
            designation: designation,
            quantite: quantite,
            prixUnitaire: prixUnitaire,
            referenceCommande: referenceCommande,
            dateCommande: dateCommande,
            produitId: produit?.id,
            factureId: facture?.id
        )
    }

    static func fromDTO(_ dto: LigneFactureDTO) -> LigneFacture {
        let ligne = LigneFacture(
            designation: dto.designation,
            quantite: dto.quantite,
            prixUnitaire: dto.prixUnitaire,
            referenceCommande: dto.referenceCommande,
            dateCommande: dto.dateCommande
        )
        ligne.id = dto.id
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
