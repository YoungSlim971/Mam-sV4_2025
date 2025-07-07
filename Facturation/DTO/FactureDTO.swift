import Foundation
import SwiftData

struct FactureDTO: Codable, Identifiable, Equatable {
    var id: UUID
    var numero: String
    var dateFacture: Date
    var dateEcheance: Date?
    var datePaiement: Date?
    var tva: Double
    var conditionsPaiement: String
    var remisePourcentage: Double
    var statut: String
    var notes: String
    var notesCommentaireFacture: String?
    var clientId: UUID
    var ligneIds: [UUID]
    
    // Computed properties for totals - require lignes as parameter
    func calculateSousTotal(with lignes: [LigneFactureDTO]) -> Double {
        let factureLignes = lignes.filter { ligneIds.contains($0.id) }
        return factureLignes.reduce(0) { $0 + ($1.quantite * $1.prixUnitaire) }
    }
    
    func calculateMontantTVA(with lignes: [LigneFactureDTO]) -> Double {
        calculateSousTotal(with: lignes) * (tva / 100)
    }
    
    func calculateTotalTTC(with lignes: [LigneFactureDTO]) -> Double {
        let brut = calculateSousTotal(with: lignes) + calculateMontantTVA(with: lignes)
        let remise = brut * (remisePourcentage / 100)
        return brut - remise
    }
}

extension FactureDTO {
    init(from facture: FactureModel) {
        self.id = facture.id
        self.numero = facture.numero
        self.dateFacture = facture.dateFacture
        self.dateEcheance = facture.dateEcheance
        self.datePaiement = facture.datePaiement
        self.tva = facture.tva
        self.conditionsPaiement = facture.conditionsPaiement.rawValue
        self.remisePourcentage = facture.remisePourcentage
        self.statut = facture.statut.rawValue
        self.notes = facture.notes
        self.notesCommentaireFacture = facture.notesCommentaireFacture
        self.clientId = facture.client?.id ?? UUID()
        self.ligneIds = facture.lignes.map { $0.id }
    }
}

// MARK: - Helpers d'affichage pour FactureDTO
import SwiftUI

extension FactureDTO {
    var statutDisplay: String {
        switch statut {
        case "brouillon": return "Brouillon"
        case "envoyee": return "Envoyée"
        case "payee": return "Payée"
        case "en_retard": return "En retard"
        case "annulee": return "Annulée"
        default: return statut.capitalized
        }
    }
    
    var statutColor: Color {
        switch statut {
        case "brouillon": return AppTheme.Colors.statusDraft
        case "envoyee": return AppTheme.Colors.statusSent
        case "payee": return AppTheme.Colors.statusPaid
        case "en_retard": return AppTheme.Colors.statusOverdue
        case "annulee": return AppTheme.Colors.statusCancelled
        default: return AppTheme.Colors.primary
        }
    }
}

// DTO conversion methods are now in DataService.swift to avoid duplicates
