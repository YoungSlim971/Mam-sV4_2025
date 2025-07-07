import Foundation

struct EditableLigneFacture: Identifiable {
    let id: UUID
    var designation: String
    var quantite: Double
    var prixUnitaire: Double
    var referenceCommande: String? // Nouveau champ
    var dateCommande: Date? // Nouveau champ
    var produitId: UUID? // Added for DTO compatibility

    init() {
        self.id = UUID()
        self.designation = ""
        self.quantite = 1.0
        self.prixUnitaire = 0.0
        self.referenceCommande = nil
        self.dateCommande = nil
        self.produitId = nil
    }

    init(from ligne: LigneFacture) {
        self.id = ligne.id
        self.designation = ligne.designation
        self.quantite = ligne.quantite
        self.prixUnitaire = ligne.prixUnitaire
        self.referenceCommande = ligne.referenceCommande
        self.dateCommande = ligne.dateCommande
        self.produitId = ligne.produit?.id
    }

    init(fromDTO ligneDTO: LigneFactureDTO) {
        self.id = ligneDTO.id
        self.designation = ligneDTO.designation
        self.quantite = ligneDTO.quantite
        self.prixUnitaire = ligneDTO.prixUnitaire
        self.referenceCommande = ligneDTO.referenceCommande
        self.dateCommande = ligneDTO.dateCommande
        self.produitId = ligneDTO.produitId
    }

    func applyTo(_ ligne: LigneFacture) {
        ligne.designation = designation
        ligne.quantite = quantite
        ligne.prixUnitaire = prixUnitaire
        ligne.referenceCommande = referenceCommande
        ligne.dateCommande = dateCommande
    }

    var total: Double {
        quantite * prixUnitaire
    }
}
