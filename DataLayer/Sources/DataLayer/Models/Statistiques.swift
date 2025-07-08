//
//  Statistiques.swift
//  Facturation
//
//  Created by Gemini on 2025-07-03.
//

import Foundation

// MARK: - Structures pour les statistiques

/// Représente les statistiques aggrégées pour un client.
struct StatParClient: Identifiable, Hashable {
    public var id: UUID { client.id }
    let client: ClientModel
    let montantTotal: Double
    let facturesCount: Int
}

/// Représente les statistiques aggrégées pour un produit.
struct StatParProduit: Identifiable, Hashable {
    public var id: UUID { produit.id }
    let produit: ProduitModel
    let quantiteTotale: Double
    let montantTotal: Double
}

/// Représente une donnée d'évolution mensuelle (pour les graphiques).
struct MonthStat: Identifiable {
    let id = UUID()
    let date: Date
    let valeur: Double
}

// MARK: - Enums pour les filtres de la vue

/// Type de statistiques à afficher (par client ou par produit).
enum StatistiqueType: String, CaseIterable, Identifiable {
    case clients = "Clients"
    case produits = "Produits"
    
    public var id: String { self.rawValue }

    static func == (lhs: StatistiqueType, rhs: StatistiqueType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

/// Périodes prédéfinies pour le filtre de date.
enum PeriodePredefinie: String, CaseIterable, Identifiable {
    case uneSemaine = "1 semaine"
    case unMois = "1 mois"
    case sixMois = "6 mois"
    case unAn = "1 an"
    case personnalise = "Personnalisé"
    
    public var id: String { self.rawValue }
    
    /// Calcule l'intervalle de date correspondant à la période.
    public var dateInterval: DateInterval? {
        let now = Date()
        let calendar = Calendar.current
        switch self {
        case .uneSemaine:
            return DateInterval(start: calendar.date(byAdding: .weekOfYear, value: -1, to: now)!, end: now)
        case .unMois:
            return DateInterval(start: calendar.date(byAdding: .month, value: -1, to: now)!, end: now)
        case .sixMois:
            return DateInterval(start: calendar.date(byAdding: .month, value: -6, to: now)!, end: now)
        case .unAn:
            return DateInterval(start: calendar.date(byAdding: .year, value: -1, to: now)!, end: now)
        case .personnalise:
            return nil
        }
    }
}
