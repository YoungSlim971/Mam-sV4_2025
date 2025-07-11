import Foundation
import Combine
import SwiftUI
import DataLayer

@MainActor
class StatistiquesService_DTO: ObservableObject {
    
    // Types pour les statistiques
    struct ClientStatistique: Identifiable {
        let id = UUID()
        let client: ClientDTO
        let chiffreAffaires: Double
        let nombreFactures: Int
    }
    
    struct ProduitStatistique: Identifiable {
        let id = UUID()
        let produit: ProduitDTO
        let quantiteVendue: Double
        let chiffreAffaires: Double
    }
    
    struct PointStatistique: Identifiable {
        let id = UUID()
        let date: Date
        let montant: Double
    }
    
    enum StatistiqueType: String, CaseIterable {
        case clients = "Clients"
        case produits = "Produits"
    }
    
    enum PeriodePredefinie: String, CaseIterable {
        case septJours = "7 derniers jours"
        case trentejours = "30 derniers jours"
        case troisMois = "3 derniers mois"
        case sixMois = "6 derniers mois"
        case unAn = "Cette année"
        
        var dateInterval: DateInterval {
            let calendar = Calendar.current
            let now = Date()
            let startDate: Date
            
            switch self {
            case .septJours:
                startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .trentejours:
                startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            case .troisMois:
                startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .sixMois:
                startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            case .unAn:
                startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            }
            
            return DateInterval(start: startDate, end: now)
        }
    }
    
    @Published var topClients: [ClientStatistique] = []
    @Published var topProduits: [ProduitStatistique] = []
    @Published var topProduitsParCA: [ProduitStatistique] = []
    @Published var topProduitsParVentes: [ProduitStatistique] = []
    @Published var evolutionVentes: [PointStatistique] = []
    @Published var delaisPaiementMoyen: Int = 0
    @Published var repartitionStatuts: [StatutFacture: [FactureDTO]] = [:]

    var caMensuel: [String: Double] {
        Dictionary(uniqueKeysWithValues: evolutionVentes.map { stat in
            let monthIndex = Calendar.current.component(.month, from: stat.date) - 1
            let monthName = Calendar.current.monthSymbols[monthIndex]
            return (monthName, stat.montant)
        })
    }
    var evolutionCAMensuel: Double = 0.0
    
    // MARK: - Computed Properties for Views
    var totalProduitsVendus: Double {
        return topProduitsParVentes.reduce(0) { $0 + $1.quantiteVendue }
    }
    
    var chiffreAffairesTotalProduits: Double {
        return topProduitsParCA.reduce(0) { $0 + $1.chiffreAffaires }
    }
    
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
            self.topProduitsParCA = calculerTopProduitsParCA(interval: interval)
            self.topProduitsParVentes = calculerTopProduitsParVentes(interval: interval)
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
    
    private func calculerTopClients(interval: DateInterval) -> [ClientStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        let stats = Dictionary(grouping: factures, by: { $0.clientId })
            .compactMap { (clientId, factures) -> ClientStatistique? in
                guard let client = dataService.clients.first(where: { $0.id == clientId }) else { return nil }
                let montantTotal = factures.reduce(0) { total, facture in
                    total + facture.calculateTotalTTC(with: dataService.lignes)
                }
                return ClientStatistique(client: client, chiffreAffaires: montantTotal, nombreFactures: factures.count)
            }
        
        return stats.sorted { $0.chiffreAffaires > $1.chiffreAffaires }
    }
    
    private func calculerTopProduits(interval: DateInterval) -> [ProduitStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var stats: [UUID: (quantite: Double, montant: Double)] = [:]
        
        for facture in factures {
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            for ligne in factureLignes {
                if let produitId = ligne.produitId {
                    let total = ligne.quantite * ligne.prixUnitaire
                    stats[produitId, default: (0, 0)].quantite += ligne.quantite
                    stats[produitId, default: (0, 0)].montant += total
                }
            }
        }
        
        return stats.compactMap { (produitId, totals) in
            guard let produit = dataService.produits.first(where: { $0.id == produitId }) else { return nil }
            return ProduitStatistique(produit: produit, quantiteVendue: totals.quantite, chiffreAffaires: totals.montant)
        }.sorted { $0.chiffreAffaires > $1.chiffreAffaires }
    }
    
    private func calculerTopProduitsParCA(interval: DateInterval) -> [ProduitStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var stats: [UUID: (quantite: Double, chiffreAffaires: Double)] = [:]
        
        for facture in factures {
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            for ligne in factureLignes {
                if let produitId = ligne.produitId {
                    let lineTotal = ligne.quantite * ligne.prixUnitaire
                    stats[produitId, default: (0, 0)].quantite += ligne.quantite
                    stats[produitId, default: (0, 0)].chiffreAffaires += lineTotal
                }
            }
        }
        
        return stats.compactMap { (produitId, totals) in
            guard let produit = dataService.produits.first(where: { $0.id == produitId }) else { return nil }
            return ProduitStatistique(produit: produit, quantiteVendue: totals.quantite, chiffreAffaires: totals.chiffreAffaires)
        }.sorted { $0.chiffreAffaires > $1.chiffreAffaires }
    }
    
    private func calculerTopProduitsParVentes(interval: DateInterval) -> [ProduitStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var stats: [UUID: (quantite: Double, chiffreAffaires: Double)] = [:]
        
        for facture in factures {
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            for ligne in factureLignes {
                if let produitId = ligne.produitId {
                    let lineTotal = ligne.quantite * ligne.prixUnitaire
                    stats[produitId, default: (0, 0)].quantite += ligne.quantite
                    stats[produitId, default: (0, 0)].chiffreAffaires += lineTotal
                }
            }
        }
        
        return stats.compactMap { (produitId, totals) in
            guard let produit = dataService.produits.first(where: { $0.id == produitId }) else { return nil }
            return ProduitStatistique(produit: produit, quantiteVendue: totals.quantite, chiffreAffaires: totals.chiffreAffaires)
        }.sorted { $0.quantiteVendue > $1.quantiteVendue }
    }
    
    private func calculerEvolutionVentesClient(clientId: UUID, interval: DateInterval) -> [PointStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.clientId == clientId &&
            facture.dateFacture >= interval.start && 
            facture.dateFacture <= interval.end
        }
        
        let monthlyData = Dictionary(grouping: factures, by: { Calendar.current.startOfMonth(for: $0.dateFacture) })
            .map { (date, factures) in
                let total = factures.reduce(0) { total, facture in
                    total + facture.calculateTotalTTC(with: dataService.lignes)
                }
                return PointStatistique(date: date, montant: total)
            }
        
        return monthlyData.sorted { $0.date < $1.date }
    }
    
    private func calculerEvolutionVentesProduit(produitId: UUID, interval: DateInterval) -> [PointStatistique] {
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
        
        return monthlyData.map { PointStatistique(date: $0.key, montant: $0.value) }.sorted { $0.date < $1.date }
    }

    private func calculerEvolutionGlobalCA(interval: DateInterval) -> [PointStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        let monthlyData = Dictionary(grouping: factures, by: { Calendar.current.startOfMonth(for: $0.dateFacture) })
            .map { (date, factures) in
                let total = factures.reduce(0) { total, facture in
                    total + facture.calculateTotalTTC(with: dataService.lignes)
                }
                return PointStatistique(date: date, montant: total)
            }
        
        return monthlyData.sorted { $0.date < $1.date }
    }

    private func calculerEvolutionGlobalQuantite(interval: DateInterval) -> [PointStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var monthlyData: [Date: Double] = [:]
        
        for facture in factures {
            let startOfMonth = Calendar.current.startOfMonth(for: facture.dateFacture)
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            let totalQuantite = factureLignes.reduce(0) { $0 + $1.quantite }
            monthlyData[startOfMonth, default: 0] += totalQuantite
        }
        
        return monthlyData.map { PointStatistique(date: $0.key, montant: $0.value) }.sorted { $0.date < $1.date }
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

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}