import Foundation

public struct StatistiquesDTO: Codable, Sendable {
    public let chiffreAffairesMensuel: [StatistiqueMensuelle]
    public let delaiPaiementMoyen: Double
    public let repartitionParStatut: [String: Int]
    
    public init(chiffreAffairesMensuel: [StatistiqueMensuelle], delaiPaiementMoyen: Double, repartitionParStatut: [String: Int]) {
        self.chiffreAffairesMensuel = chiffreAffairesMensuel
        self.delaiPaiementMoyen = delaiPaiementMoyen
        self.repartitionParStatut = repartitionParStatut
    }
}

public struct StatistiqueMensuelle: Codable, Sendable, Identifiable {
    public let id: UUID
    public let mois: String // Exemple: "2025-07"
    public let total: Double
    
    public init(id: UUID, mois: String, total: Double) {
        self.id = id
        self.mois = mois
        self.total = total
    }
}

public struct StatistiqueStatut: Codable, Sendable, Identifiable {
    public let id: UUID
    public let statut: String // Ex: "Payée", "Envoyée", "En retard"
    public let nombre: Int
    
    public init(id: UUID, statut: String, nombre: Int) {
        self.id = id
        self.statut = statut
        self.nombre = nombre
    }
}

public struct StatistiqueDelai: Codable, Sendable {
    public let moyenneEnJours: Double
    
    public init(moyenneEnJours: Double) {
        self.moyenneEnJours = moyenneEnJours
    }
}