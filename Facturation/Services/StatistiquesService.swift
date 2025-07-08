import Foundation
import DataLayer
import Combine
import SwiftUI

@MainActor
class StatistiquesService: ObservableObject {
    
    @Published var topClients: [ClientStatistique] = []
    @Published var topProduits: [ProduitStatistique] = []
    @Published var evolutionVentes: [PointStatistique] = []
    @Published var delaisPaiementMoyen: Int = 0
    @Published var repartitionStatuts: [StatutFacture: [FactureDTO]] = [:]

    private var dataService: DataService
    
    // Expose lignes for calculations in views
    var lignes: [LigneFactureDTO] {
        dataService.lignes
    }
    
    init(dataService: DataService? = nil) {
        self.dataService = dataService ?? DataService.shared
        
        // Observer les changements dans DataService pour mettre à jour automatiquement
        self.dataService.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Types internes
    
    struct PointStatistique: Identifiable {
        let date: Date
        let montant: Double
        var id: Date { date }
    }

    struct ClientStatistique: Identifiable {
        let id = UUID()
        let nom: String
        let total: Double
    }

    struct ProduitStatistique: Identifiable {
        let id = UUID()
        let nom: String
        let quantite: Double
        let chiffreAffaires: Double
        let nombreVentes: Int
        
        var moyennePrixVente: Double {
            guard nombreVentes > 0 else { return 0 }
            return chiffreAffaires / quantite
        }
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
        case annee = "Année complète"
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
            case .annee:
                let year = calendar.component(.year, from: now)
                let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? now
                let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)) ?? now
                return DateInterval(start: startOfYear, end: endOfYear)
            case .personnalise:
                return nil
            }
        }
    }
    
    // MARK: - Properties for UI
    
    var typesDispo: [StatistiqueType] {
        StatistiqueType.allCases
    }
    
    var periodes: [PeriodePredefinie] {
        PeriodePredefinie.allCases
    }
    
    // Nouvelles propriétés pour les statistiques produits
    var topProduitsParCA: [ProduitStatistique] {
        topProduits.sorted { $0.chiffreAffaires > $1.chiffreAffaires }
    }
    
    var topProduitsParVentes: [ProduitStatistique] {
        topProduits.sorted { $0.nombreVentes > $1.nombreVentes }
    }
    
    var totalProduitsVendus: Double {
        topProduits.reduce(0) { $0 + $1.quantite }
    }
    
    var chiffreAffairesTotalProduits: Double {
        topProduits.reduce(0) { $0 + $1.chiffreAffaires }
    }
    
    var caMensuel: [String: Double] {
        Dictionary(uniqueKeysWithValues: evolutionVentes.map { stat in
            let monthIndex = Calendar.current.component(.month, from: stat.date) - 1
            let monthName = Calendar.current.monthSymbols[monthIndex]
            return (monthName, stat.montant)
        })
    }

    var evolutionCAMensuel: Double {
        guard evolutionVentes.count >= 2 else { return 0.0 }

        let sortedEvolution = evolutionVentes.sorted { $0.date < $1.date }
        guard let lastMonthCA = sortedEvolution.last?.montant,
              let secondLastMonthCA = sortedEvolution.dropLast().last?.montant else {
            return 0.0
        }

        if secondLastMonthCA == 0 {
            return lastMonthCA == 0 ? 0.0 : 100.0
        }

        return ((lastMonthCA - secondLastMonthCA) / secondLastMonthCA) * 100.0
    }
    
    // MARK: - Fonctions principales
    
    func updateStatistiques(interval: DateInterval, type: StatistiqueType, clientId: UUID? = nil, produitId: UUID? = nil) {
        switch type {
        case .clients:
            self.topClients = calculerTopClients(interval: interval)
            if let clientId = clientId {
                self.evolutionVentes = evolutionVentesClient(clientId: clientId, interval: interval)
            } else {
                self.evolutionVentes = pointsParMois(pour: .clients, interval: interval)
            }
        case .produits:
            self.topProduits = calculerTopProduits(interval: interval)
            if let produitId = produitId {
                self.evolutionVentes = evolutionVentesProduit(produitId: produitId, interval: interval)
            } else {
                self.evolutionVentes = pointsParMois(pour: .produits, interval: interval)
            }
        }
        self.delaisPaiementMoyen = calculerDelaiPaiementMoyen(interval: interval)
        self.repartitionStatuts = calculerRepartitionStatuts(interval: interval)
    }
    
    // MARK: - Fonctions de base
    
    func chiffreAffaires(interval: DateInterval, for clientId: UUID? = nil, produitId: UUID? = nil) -> Double {
        // Récupère les factures dans l'intervalle
        var factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        // Filtre par client si spécifié
        if let clientId = clientId {
            factures = factures.filter { $0.clientId == clientId }
        }
        
        var total: Double = 0
        
        for facture in factures {
            // Récupère les lignes de cette facture
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            
            if let produitId = produitId {
                // Filtre par produit si spécifié
                let produitLignes = factureLignes.filter { $0.produitId == produitId }
                total += produitLignes.reduce(0) { $0 + ($1.quantite * $1.prixUnitaire) }
            } else {
                // Tous les produits
                total += factureLignes.reduce(0) { $0 + ($1.quantite * $1.prixUnitaire) }
            }
        }
        
        return total
    }
    
    // MARK: - Points pour les courbes
    
    func pointsParMois(pour type: StatistiqueType, interval: DateInterval) -> [PointStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var monthlyData: [Date: Double] = [:]
        
        for facture in factures {
            let startOfMonth = Calendar.current.startOfMonth(for: facture.dateFacture)
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            
            switch type {
            case .clients:
                // Total CA par mois
                let montant = factureLignes.reduce(0) { $0 + ($1.quantite * $1.prixUnitaire) }
                monthlyData[startOfMonth, default: 0] += montant
            case .produits:
                // Total quantité par mois
                let quantite = factureLignes.reduce(0) { $0 + $1.quantite }
                monthlyData[startOfMonth, default: 0] += quantite
            }
        }
        
        return monthlyData.map { PointStatistique(date: $0.key, montant: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Calculs détaillés
    
    private func calculerTopClients(interval: DateInterval) -> [ClientStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        let stats = Dictionary(grouping: factures, by: { $0.clientId })
            .compactMap { (clientId, clientFactures) -> ClientStatistique? in
                guard let client = dataService.clients.first(where: { $0.id == clientId }) else { return nil }

                var totalCA: Double = 0
                for facture in clientFactures {
                    let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
                    totalCA += factureLignes.reduce(0) { $0 + ($1.quantite * $1.prixUnitaire) }
                }

                return ClientStatistique(
                    nom: client.nomCompletClient,
                    total: totalCA
                )
            }

        return stats.sorted { $0.total > $1.total }
    }
    
    private func calculerTopProduits(interval: DateInterval) -> [ProduitStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var stats: [UUID: (ca: Double, quantite: Double, ventes: Int)] = [:]
        var lignesSansProduitId = 0
        var totalLignesAnalysees = 0
        
        print("🔍 [StatistiquesService] Début de l'analyse des produits...")
        
        for facture in factures {
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            for ligne in factureLignes {
                totalLignesAnalysees += 1
                if let produitId = ligne.produitId {
                    let montant = ligne.quantite * ligne.prixUnitaire
                    stats[produitId, default: (0, 0, 0)].ca += montant
                    stats[produitId, default: (0, 0, 0)].quantite += ligne.quantite
                    stats[produitId, default: (0, 0, 0)].ventes += 1
                } else {
                    lignesSansProduitId += 1
                    print("⚠️ Ligne sans produitId trouvée: \(ligne.designation)")
                }
            }
        }
        
        print("📊 [StatistiquesService] \(factures.count) factures analysées – \(lignesSansProduitId) erreur\(lignesSansProduitId > 1 ? "s" : "")")
        print("📈 [StatistiquesService] Total lignes: \(totalLignesAnalysees), Lignes avec produitId: \(totalLignesAnalysees - lignesSansProduitId)")
        
        return stats.compactMap { (produitId, totals) in
            guard let produit = dataService.produits.first(where: { $0.id == produitId }) else { return nil }
            return ProduitStatistique(
                nom: produit.designation,
                quantite: totals.quantite,
                chiffreAffaires: totals.ca,
                nombreVentes: totals.ventes
            )
        }.sorted { $0.quantite > $1.quantite }
    }
    
    private func evolutionVentesClient(clientId: UUID, interval: DateInterval) -> [PointStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.clientId == clientId &&
            facture.dateFacture >= interval.start &&
            facture.dateFacture <= interval.end
        }
        
        var monthlyData: [Date: Double] = [:]
        
        for facture in factures {
            let startOfMonth = Calendar.current.startOfMonth(for: facture.dateFacture)
            let factureLignes = dataService.lignes.filter { facture.ligneIds.contains($0.id) }
            let montant = factureLignes.reduce(0) { $0 + ($1.quantite * $1.prixUnitaire) }
            monthlyData[startOfMonth, default: 0] += montant
        }
        
        return monthlyData.map { PointStatistique(date: $0.key, montant: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private func evolutionVentesProduit(produitId: UUID, interval: DateInterval) -> [PointStatistique] {
        let factures = dataService.factures.filter { facture in
            facture.dateFacture >= interval.start && facture.dateFacture <= interval.end
        }
        
        var monthlyData: [Date: Double] = [:]
        
        for facture in factures {
            let startOfMonth = Calendar.current.startOfMonth(for: facture.dateFacture)
            let factureLignes = dataService.lignes.filter {
                facture.ligneIds.contains($0.id) && $0.produitId == produitId
            }
            let quantite = factureLignes.reduce(0) { $0 + $1.quantite }
            monthlyData[startOfMonth, default: 0] += quantite
        }
        
        return monthlyData.map { PointStatistique(date: $0.key, montant: $0.value) }
            .sorted { $0.date < $1.date }
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
        
        // Group factures by their StatutFacture enum value
        let grouped = Dictionary(grouping: factures) { facture in
            StatutFacture(rawValue: facture.statut) ?? .brouillon
        }
        
        return grouped
    }
}

// MARK: - Calendar extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
