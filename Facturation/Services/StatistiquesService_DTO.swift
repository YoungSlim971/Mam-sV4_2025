import Foundation
import Combine
import SwiftUI

@MainActor
class StatistiquesService: ObservableObject {
    
    @Published var topClients: [StatParClient] = []
    @Published var topProduits: [StatParProduit] = []
    @Published var evolutionVentes: [MonthStat] = []
    @Published var delaisPaiementMoyen: Int = 0
    @Published var repartitionStatuts: [StatutFacture: [FactureDTO]] = [:]

    var caMensuel: [String: Double] {
        Dictionary(uniqueKeysWithValues: evolutionVentes.map { stat in
            let monthIndex = Calendar.current.component(.month, from: stat.date) - 1
            let monthName = Calendar.current.monthSymbols[monthIndex]
            return (monthName, stat.valeur)
        })
    }
    var evolutionCAMensuel: Double = 0.0
    
    private var dataService: DataService

    init(dataService: DataService = DataService.shared) {
        self.dataService = dataService
    }
    
    // MARK: - Fonctions de calcul principales
    
    func updateStatistiques(interval: DateInterval, type: StatistiqueType, clientId: UUID? = nil, produitId: UUID? = nil) {
        switch type {
        case .clients:
            self.topClients = calculerTopClients(interval: interval)
            if let clientId = clientId {
                self.evolutionVentes = calculerEvolutionVentesClient(clientId: clientId, interval: interval)
            } else {
                self.evolutionVentes = calculerEvolutionGlobalCA(interval: interval)
            }
        case .produits:
            self.topProduits = calculerTopProduits(interval: interval)
            if let produitId = produitId {
                self.evolutionVentes = calculerEvolutionVentesProduit(produitId: produitId, interval: interval)
            } else {
                self.evolutionVentes = calculerEvolutionGlobalQuantite(interval: interval)
            }
        }
        self.delaisPaiementMoyen = calculerDelaiPaiementMoyen(interval: interval)
        self.repartitionStatuts = calculerRepartitionStatuts(interval: interval)
        self.evolutionCAMensuel = calculerEvolutionCAMensuel()
    }
    
    // MARK: - Méthodes de calcul des statistiques (DTO-based)
    
    private func calculerTopClients(interval: DateInterval) -> [StatParClient] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        let stats = Dictionary(grouping: factures, by: { $0.clientId })
            .compactMap { (clientId, factures) -> StatParClient? in
                guard let client = dataService.clients.first(where: { $0.id == clientId }) else { return nil }
                let montantTotal = factures.reduce(0) { $0 + $1.totalTTC }
                return StatParClient(clientDTO: client, montantTotal: montantTotal, facturesCount: factures.count)
            }
        
        return stats.sorted { $0.montantTotal > $1.montantTotal }
    }
    
    private func calculerTopProduits(interval: DateInterval) -> [StatParProduit] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var stats: [UUID: (quantite: Double, montant: Double)] = [:]
        
        for facture in factures {
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            for ligne in factureLignes {
                if let produitId = ligne.produitId {
                    stats[produitId, default: (0, 0)].quantite += ligne.quantite
                    stats[produitId, default: (0, 0)].montant += ligne.total
                }
            }
        }
        
        return stats.compactMap { (produitId, totals) in
            guard let produit = dataService.produits.first(where: { $0.id == produitId }) else { return nil }
            return StatParProduit(produitDTO: produit, quantiteTotale: totals.quantite, montantTotal: totals.montant)
        }.sorted { $0.montantTotal > $1.montantTotal }
    }
    
    private func calculerEvolutionVentesClient(clientId: UUID, interval: DateInterval) -> [MonthStat] {
        let factures = dataService.factures.filter { facture in
            facture.clientId == clientId &&
            facture.dateFacture >= interval.start && 
            facture.dateFacture <= interval.end
        }
        
        let monthlyData = Dictionary(grouping: factures, by: { Calendar.current.startOfMonth(for: $0.dateFacture) })
            .map { (date, factures) in
                MonthStat(date: date, valeur: factures.reduce(0) { $0 + $1.totalTTC })
            }
        
        return monthlyData.sorted { $0.date < $1.date }
    }
    
    private func calculerEvolutionVentesProduit(produitId: UUID, interval: DateInterval) -> [MonthStat] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var monthlyData: [Date: Double] = [:]
        
        for facture in factures {
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            for ligne in factureLignes {
                if ligne.produitId == produitId {
                    let startOfMonth = Calendar.current.startOfMonth(for: facture.dateFacture)
                    monthlyData[startOfMonth, default: 0] += ligne.quantite
                }
            }
        }
        
        return monthlyData.map { MonthStat(date: $0.key, valeur: $0.value) }.sorted { $0.date < $1.date }
    }

    private func calculerEvolutionGlobalCA(interval: DateInterval) -> [MonthStat] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        let monthlyData = Dictionary(grouping: factures, by: { Calendar.current.startOfMonth(for: $0.dateFacture) })
            .map { (date, factures) in
                MonthStat(date: date, valeur: factures.reduce(0) { $0 + $1.totalTTC })
            }
        
        return monthlyData.sorted { $0.date < $1.date }
    }

    private func calculerEvolutionGlobalQuantite(interval: DateInterval) -> [MonthStat] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var monthlyData: [Date: Double] = [:]
        
        for facture in factures {
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            let startOfMonth = Calendar.current.startOfMonth(for: facture.dateFacture)
            monthlyData[startOfMonth, default: 0] += factureLignes.reduce(0) { $0 + $1.quantite }
        }
        
        return monthlyData.map { MonthStat(date: $0.key, valeur: $0.value) }.sorted { $0.date < $1.date }
    }

    private func calculerDelaiPaiementMoyen(interval: DateInterval) -> Int {
        let facturesPayees = dataService.factures.filter { facture in
            facture.statut == StatutFacture.payee.rawValue &&
            facture.dateFacture >= interval.start && 
            facture.dateFacture <= interval.end &&
            facture.datePaiement != nil
        }
        
        guard !facturesPayees.isEmpty else { return 0 }
        
        let totalDelais = facturesPayees.compactMap { facture -> Int? in
            guard let datePaiement = facture.datePaiement else { return nil }
            return Calendar.current.dateComponents([.day], from: facture.dateFacture, to: datePaiement).day
        }
        
        return totalDelais.isEmpty ? 0 : totalDelais.reduce(0, +) / totalDelais.count
    }

    private func calculerRepartitionStatuts(interval: DateInterval) -> [StatutFacture: [FactureDTO]] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        return Dictionary(grouping: factures) { facture in
            StatutFacture(rawValue: facture.statut) ?? .brouillon
        }
    }

    private func calculerEvolutionCAMensuel() -> Double {
        // Simplified implementation
        return 0.0
    }
}

// MARK: - Support structures for DTO compatibility

struct StatParClient {
    let client: ClientDTO
    let montantTotal: Double
    let facturesCount: Int
    
    init(clientDTO: ClientDTO, montantTotal: Double, facturesCount: Int) {
        self.client = clientDTO
        self.montantTotal = montantTotal
        self.facturesCount = facturesCount
    }
}

struct StatParProduit {
    let produit: ProduitDTO
    let quantiteTotale: Double
    let montantTotal: Double
    
    init(produitDTO: ProduitDTO, quantiteTotale: Double, montantTotal: Double) {
        self.produit = produitDTO
        self.quantiteTotale = quantiteTotale
        self.montantTotal = montantTotal
    }
}

struct MonthStat {
    let date: Date
    let valeur: Double
}

enum StatistiqueType: String, CaseIterable, Identifiable {
    case clients = "Clients"
    case produits = "Produits"
    
    var id: String { rawValue }
}

enum PeriodePredefinie: String, CaseIterable, Identifiable {
    case septJours = "7 derniers jours"
    case trentejours = "30 derniers jours"
    case troisMois = "3 derniers mois"
    case sixMois = "6 derniers mois"
    case anneeEnCours = "Année en cours"
    case anneePrecedente = "Année précédente"
    case personnalise = "Période personnalisée"
    
    var id: String { rawValue }
    
    var dateInterval: DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .septJours:
            return DateInterval(start: calendar.date(byAdding: .day, value: -7, to: now) ?? now, end: now)
        case .trentejours:
            return DateInterval(start: calendar.date(byAdding: .day, value: -30, to: now) ?? now, end: now)
        case .troisMois:
            return DateInterval(start: calendar.date(byAdding: .month, value: -3, to: now) ?? now, end: now)
        case .sixMois:
            return DateInterval(start: calendar.date(byAdding: .month, value: -6, to: now) ?? now, end: now)
        case .anneeEnCours:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return DateInterval(start: startOfYear, end: now)
        case .anneePrecedente:
            let lastYear = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            let startOfLastYear = calendar.dateInterval(of: .year, for: lastYear)?.start ?? lastYear
            let endOfLastYear = calendar.dateInterval(of: .year, for: lastYear)?.end ?? lastYear
            return DateInterval(start: startOfLastYear, end: endOfLastYear)
        case .personnalise:
            return nil
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}