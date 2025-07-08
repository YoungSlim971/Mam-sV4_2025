import Foundation
import SwiftUI
import Logging

// MARK: - Enums
public enum StatutFacture: String, CaseIterable, Codable {
    case brouillon = "Brouillon"
    case envoyee = "Envoyée"
    case payee = "Payée"
    case enRetard = "En Retard"
    case annulee = "Annulée"
    
    public var color: Color {
        switch self {
        case .brouillon: return .gray
        case .envoyee: return .blue
        case .payee: return .green
        case .enRetard: return .red
        case .annulee: return .red
        }
    }

    public var systemImage: String {
        switch self {
        case .brouillon: return "doc.text"
        case .envoyee: return "paperplane"
        case .payee: return "checkmark.circle.fill"
        case .enRetard: return "clock.fill"
        case .annulee: return "xmark.circle.fill"
        }
    }
}

public enum ConditionsPaiement: String, CaseIterable, Codable {
    case virement = "Virement"
    case cheque   = "Chèque"
    case espece   = "Espèces"
    case carte    = "Carte"

    public var systemImage: String {
        switch self {
        case .virement: return "eurosign"
        case .cheque:   return "rectangle.portrait.and.arrow.right"
        case .espece:   return "banknote"
        case .carte:    return "creditcard"
        }
    }
}

// MARK: - Errors
public enum DataLayerError: LocalizedError {
    case persistenceInitializationFailed(String)
    case dataFetchFailed(String)
    case dataSaveFailed(String)
    case modelValidationFailed(String)
    case containerResetFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .persistenceInitializationFailed(let message):
            return "Erreur d'initialisation de la persistance: \(message)"
        case .dataFetchFailed(let message):
            return "Erreur de récupération des données: \(message)"
        case .dataSaveFailed(let message):
            return "Erreur de sauvegarde des données: \(message)"
        case .modelValidationFailed(let message):
            return "Erreur de validation du modèle: \(message)"
        case .containerResetFailed(let message):
            return "Erreur de réinitialisation du conteneur: \(message)"
        }
    }
}