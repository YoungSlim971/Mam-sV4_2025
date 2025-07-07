//
//  StatistiquesDTO.swift
//  Facturation
//
//  Created by Young Slim on 06/07/2025.
//


import Foundation

struct StatistiquesDTO: Codable, Sendable {
    let chiffreAffairesMensuel: [StatistiqueMensuelle]
    let delaiPaiementMoyen: Double
    let repartitionParStatut: [String: Int]
}

struct StatistiqueMensuelle: Codable, Sendable, Identifiable {
    let id: UUID
    let mois: String // Exemple: "2025-07"
    let total: Double
}

struct StatistiqueStatut: Codable, Sendable, Identifiable {
    let id: UUID
    let statut: String // Ex: "Payée", "Envoyée", "En retard"
    let nombre: Int
}

struct StatistiqueDelai: Codable, Sendable {
    let moyenneEnJours: Double
}
