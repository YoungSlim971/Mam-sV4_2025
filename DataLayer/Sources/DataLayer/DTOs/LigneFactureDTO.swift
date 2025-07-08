import Foundation

public struct LigneFactureDTO: Codable, Identifiable {
    public let id: UUID
    public var designation: String
    public var quantite: Double
    public var prixUnitaire: Double
    public var referenceCommande: String?
    public var dateCommande: Date?
    public var produitId: UUID?
    public var factureId: UUID?
    
    public init(
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
    
    public var total: Double {
        quantite * prixUnitaire
    }
}