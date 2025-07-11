import Foundation
import DataLayer

// MARK: - Extensions for Secure Architecture

extension Double {
    var formattedEuros: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: NSNumber(value: self)) ?? "0,00 €"
    }
}

extension ClientDTO {
    var nomCompletClient: String {
        return "\(nom) \(entreprise)"
    }
    
    var displayName: String {
        return nomCompletClient
    }
    
    func facturesCount(from factures: [FactureDTO]) -> Int {
        return factures.filter { $0.clientId == self.id }.count
    }
    
    func chiffreAffaires(from factures: [FactureDTO], lignes: [LigneFactureDTO]) -> Double {
        let clientFactures = factures.filter { $0.clientId == self.id }
        return clientFactures.reduce(0.0) { $0 + $1.calculateTotalTTC(with: lignes) }
    }
}

extension FactureDTO {
    func calculateTotalTTC(with lignes: [LigneFactureDTO]) -> Double {
        let factureLignes = lignes.filter { ligneIds.contains($0.id) }
        let totalHT = factureLignes.reduce(0.0) { total, ligne in
            total + (ligne.quantite * ligne.prixUnitaire)
        }
        let totalTVA = totalHT * (tva / 100.0)
        let remise = totalHT * (remisePourcentage / 100.0)
        return totalHT + totalTVA - remise
    }
    
    var statutDisplay: String {
        switch statut {
        case "brouillon": return "Brouillon"
        case "envoyee": return "Envoyée"
        case "payee": return "Payée"
        case StatutFacture.enRetard.rawValue: return "En retard"
        case "annulee": return "Annulée"
        default: return statut.capitalized
        }
    }
    
    var statutColor: Color {
        switch statut {
        case "brouillon": return AppTheme.Colors.statusDraft
        case "envoyee": return AppTheme.Colors.statusSent
        case "payee": return AppTheme.Colors.statusPaid
        case StatutFacture.enRetard.rawValue: return AppTheme.Colors.statusOverdue
        case "annulee": return AppTheme.Colors.statusCancelled
        default: return .gray
        }
    }
}

extension StatutFacture {
    var displayName: String {
        switch self {
        case .brouillon: return "Brouillon"
        case .envoyee: return "Envoyée"
        case .payee: return "Payée"
        case .enRetard: return "En retard"
        case .annulee: return "Annulée"
        }
    }
    
    var color: Color {
        switch self {
        case .brouillon: return AppTheme.Colors.statusDraft
        case .envoyee: return AppTheme.Colors.statusSent
        case .payee: return AppTheme.Colors.statusPaid
        case .enRetard: return AppTheme.Colors.statusOverdue
        case .annulee: return AppTheme.Colors.statusCancelled
        }
    }
}

extension ConditionsPaiement {
    var displayName: String {
        switch self {
        case .virement: return "Virement"
        case .cheque: return "Chèque"
        case .espece: return "Espèces"
        case .carte: return "Carte"
        }
    }
}

// Import SwiftUI for Color
import SwiftUI