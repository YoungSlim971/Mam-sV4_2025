//
//  Statistiques.swift
//  Facturation
//
//  Created by Gemini on 2025-07-03.
//

import Foundation

// MARK: - Structures pour les statistiques

/// Représente les statistiques aggrégées pour un client.
public struct StatParClient: Identifiable, Hashable {
    public var id: UUID { client.id }
    public let client: ClientModel
    public let montantTotal: Double
    public let facturesCount: Int
    
    public init(client: ClientModel, montantTotal: Double, facturesCount: Int) {
        self.client = client
        self.montantTotal = montantTotal
        self.facturesCount = facturesCount
    }
}

/// Représente les statistiques aggrégées pour un produit.
public struct StatParProduit: Identifiable, Hashable {
    public var id: UUID { produit.id }
    public let produit: ProduitModel
    public let quantiteTotale: Double
    public let montantTotal: Double
    
    public init(produit: ProduitModel, quantiteTotale: Double, montantTotal: Double) {
        self.produit = produit
        self.quantiteTotale = quantiteTotale
        self.montantTotal = montantTotal
    }
}

/// Représente une donnée d'évolution mensuelle (pour les graphiques).
public struct MonthStat: Identifiable {
    public let id = UUID()
    public let date: Date
    public let valeur: Double
    
    public init(date: Date, valeur: Double) {
        self.date = date
        self.valeur = valeur
    }
}

// MARK: - Enums pour les filtres de la vue

/// Type de statistiques à afficher (par client ou par produit).
public enum StatistiqueType: String, CaseIterable, Identifiable {
    case clients = "Clients"
    case produits = "Produits"
    
    public var id: String { self.rawValue }

    public static func == (lhs: StatistiqueType, rhs: StatistiqueType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

/// Périodes prédéfinies pour le filtre de date.
public enum PeriodePredefinie: String, CaseIterable, Identifiable {
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
