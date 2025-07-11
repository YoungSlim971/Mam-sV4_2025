import Foundation
import SwiftUI
import Logging

public struct FactureDTO: Codable, Identifiable, Equatable {
    public var id: UUID
    public var numero: String
    public var dateFacture: Date
    public var dateEcheance: Date?
    public var datePaiement: Date?
    /// TVA en pourcentage, valeur humaine saisie par l'utilisateur (ex: 20 = 20%)
    public var tva: Double
    public var conditionsPaiement: String
    public var remisePourcentage: Double
    public var statut: String
    public var notes: String
    public var notesCommentaireFacture: String?
    public var clientId: UUID
    public var ligneIds: [UUID]
    
    public init(id: UUID, numero: String, dateFacture: Date, dateEcheance: Date? = nil, datePaiement: Date? = nil, tva: Double, conditionsPaiement: String, remisePourcentage: Double, statut: String, notes: String, notesCommentaireFacture: String? = nil, clientId: UUID, ligneIds: [UUID]) {
        self.id = id
        self.numero = numero
        self.dateFacture = dateFacture
        self.dateEcheance = dateEcheance
        self.datePaiement = datePaiement
        self.tva = tva
        self.conditionsPaiement = conditionsPaiement
        self.remisePourcentage = remisePourcentage
        self.statut = statut
        self.notes = notes
        self.notesCommentaireFacture = notesCommentaireFacture
        self.clientId = clientId
        self.ligneIds = ligneIds
    }
    
    // Computed properties for totals - require lignes as parameter
    public func calculateSousTotal(with lignes: [LigneFactureDTO]) -> Double {
        let factureLignes = lignes.filter { ligneIds.contains($0.id) }
        return factureLignes.reduce(0) { $0 + ($1.quantite * $1.prixUnitaire) }
    }
    
    public func calculateMontantTVA(with lignes: [LigneFactureDTO]) -> Double {
        calculateSousTotal(with: lignes) * (tva / 100)
    }
    
    public func calculateTotalTTC(with lignes: [LigneFactureDTO]) -> Double {
        let brut = calculateSousTotal(with: lignes) + calculateSousTotal(with: lignes) * (tva / 100)
        let remise = brut * (remisePourcentage / 100)
        return brut - remise
    }
}

// MARK: - Display Helpers
public extension FactureDTO {
    var statutDisplay: String {
        switch statut {
        case StatutFacture.brouillon.rawValue: return "Brouillon"
        case StatutFacture.envoyee.rawValue: return "Envoyée"
        case StatutFacture.payee.rawValue: return "Payée"
        case StatutFacture.enRetard.rawValue: return "En retard"
        case StatutFacture.annulee.rawValue: return "Annulée"
        default: return statut.capitalized
        }
    }
    
    var statutColor: Color {
        switch statut {
        case StatutFacture.brouillon.rawValue: return .gray
        case StatutFacture.envoyee.rawValue: return .blue
        case StatutFacture.payee.rawValue: return .green
        case StatutFacture.enRetard.rawValue: return .red
        case StatutFacture.annulee.rawValue: return .red
        default: return .blue
        }
    }
}