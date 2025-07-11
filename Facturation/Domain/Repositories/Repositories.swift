import Foundation
import DataLayer

/// Secure implementation of ClientRepository using SecureDataService
@MainActor
final class SecureClientRepository: ClientRepository {
    private let dataService: SecureDataService
    
    init(dataService: SecureDataService = SecureDataService.shared) {
        self.dataService = dataService
    }
    
    func fetchClients() async -> [ClientDTO] {
        do {
            return try await dataService.fetchClients()
        } catch {
            print("Error fetching clients: \(error)")
            return []
        }
    }
    
    func addClient(_ client: ClientDTO) async -> Bool {
        do {
            return try await dataService.addClient(client)
        } catch {
            print("Error adding client: \(error)")
            return false
        }
    }
    
    func updateClient(_ client: ClientDTO) async -> Bool {
        do {
            return try await dataService.updateClient(client)
        } catch {
            print("Error updating client: \(error)")
            return false
        }
    }
    
    func deleteClient(id: UUID) async -> Bool {
        do {
            return try await dataService.deleteClient(id: id)
        } catch {
            print("Error deleting client: \(error)")
            return false
        }
    }
    
    func searchClients(searchText: String) async -> [ClientDTO] {
        do {
            return try await dataService.searchClients(searchText: searchText)
        } catch {
            print("Error searching clients: \(error)")
            return []
        }
    }
    
    func getClient(id: UUID) async -> ClientDTO? {
        let clients = await fetchClients()
        return clients.first { $0.id == id }
    }
}

/// Secure implementation of FactureRepository using SecureDataService
@MainActor
final class SecureFactureRepository: FactureRepository {
    private let dataService: SecureDataService
    
    init(dataService: SecureDataService = SecureDataService.shared) {
        self.dataService = dataService
    }
    
    func fetchFactures() async -> [FactureDTO] {
        do {
            return try await dataService.fetchFactures()
        } catch {
            print("Error fetching factures: \(error)")
            return []
        }
    }
    
    func addFacture(_ facture: FactureDTO) async -> Bool {
        do {
            return try await dataService.addFacture(facture)
        } catch {
            print("Error adding facture: \(error)")
            return false
        }
    }
    
    func updateFacture(_ facture: FactureDTO) async -> Bool {
        do {
            return try await dataService.updateFacture(facture)
        } catch {
            print("Error updating facture: \(error)")
            return false
        }
    }
    
    func deleteFacture(id: UUID) async -> Bool {
        do {
            return try await dataService.deleteFacture(id: id)
        } catch {
            print("Error deleting facture: \(error)")
            return false
        }
    }
    
    func getFacture(id: UUID) async -> FactureDTO? {
        let factures = await fetchFactures()
        return factures.first { $0.id == id }
    }
    
    func genererNumeroFacture() async -> String {
        do {
            return try await dataService.genererNumeroFacture()
        } catch {
            print("Error generating facture number: \(error)")
            return "FAC0001"
        }
    }
    
    func searchFactures(searchText: String) async -> [FactureDTO] {
        let factures = await fetchFactures()
        return factures.filter { facture in
            facture.numero.localizedCaseInsensitiveContains(searchText) ||
            facture.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func getFacturesForClient(clientId: UUID) async -> [FactureDTO] {
        let factures = await fetchFactures()
        return factures.filter { $0.clientId == clientId }
    }
    
    func getFacturesByStatus(status: StatutFacture) async -> [FactureDTO] {
        let factures = await fetchFactures()
        return factures.filter { $0.statut == status.rawValue }
    }
    
    func getFacturesByDateRange(startDate: Date, endDate: Date) async -> [FactureDTO] {
        let factures = await fetchFactures()
        return factures.filter { facture in
            facture.dateFacture >= startDate && facture.dateFacture <= endDate
        }
    }
    
    // MARK: - Ligne Facture Operations
    
    func fetchLignes() async -> [LigneFactureDTO] {
        do {
            return try await dataService.fetchLignes()
        } catch {
            print("Error fetching lignes: \(error)")
            return []
        }
    }
    
    func addLigne(_ ligne: LigneFactureDTO) async -> Bool {
        do {
            return try await dataService.addLigne(ligne)
        } catch {
            print("Error adding ligne: \(error)")
            return false
        }
    }
    
    func updateLigne(_ ligne: LigneFactureDTO) async -> Bool {
        do {
            return try await dataService.updateLigne(ligne)
        } catch {
            print("Error updating ligne: \(error)")
            return false
        }
    }
    
    func deleteLigne(id: UUID) async -> Bool {
        do {
            return try await dataService.deleteLigne(id: id)
        } catch {
            print("Error deleting ligne: \(error)")
            return false
        }
    }
}

/// Secure implementation of ProduitRepository using SecureDataService
@MainActor
final class SecureProduitRepository: ProduitRepository {
    private let dataService: SecureDataService
    
    init(dataService: SecureDataService = SecureDataService.shared) {
        self.dataService = dataService
    }
    
    func fetchProduits() async -> [ProduitDTO] {
        do {
            return try await dataService.fetchProduits()
        } catch {
            print("Error fetching produits: \(error)")
            return []
        }
    }
    
    func addProduit(_ produit: ProduitDTO) async -> Bool {
        do {
            return try await dataService.addProduit(produit)
        } catch {
            print("Error adding produit: \(error)")
            return false
        }
    }
    
    func updateProduit(_ produit: ProduitDTO) async -> Bool {
        do {
            return try await dataService.updateProduit(produit)
        } catch {
            print("Error updating produit: \(error)")
            return false
        }
    }
    
    func deleteProduit(id: UUID) async -> Bool {
        do {
            return try await dataService.deleteProduit(id: id)
        } catch {
            print("Error deleting produit: \(error)")
            return false
        }
    }
    
    func searchProduits(searchText: String) async -> [ProduitDTO] {
        do {
            return try await dataService.searchProduits(searchText: searchText)
        } catch {
            print("Error searching produits: \(error)")
            return []
        }
    }
    
    func getProduit(id: UUID) async -> ProduitDTO? {
        let produits = await fetchProduits()
        return produits.first { $0.id == id }
    }
}

/// Secure implementation of EntrepriseRepository using SecureDataService
@MainActor
final class SecureEntrepriseRepository: EntrepriseRepository {
    private let dataService: SecureDataService
    
    init(dataService: SecureDataService = SecureDataService.shared) {
        self.dataService = dataService
    }
    
    func fetchEntreprise() async -> EntrepriseDTO? {
        do {
            return try await dataService.fetchEntreprise()
        } catch {
            print("Error fetching entreprise: \(error)")
            return nil
        }
    }
    
    func updateEntreprise(_ entreprise: EntrepriseDTO) async -> Bool {
        do {
            return try await dataService.updateEntreprise(entreprise)
        } catch {
            print("Error updating entreprise: \(error)")
            return false
        }
    }
    
    func createEntreprise(_ entreprise: EntrepriseDTO) async -> Bool {
        do {
            return try await dataService.updateEntreprise(entreprise)
        } catch {
            print("Error creating entreprise: \(error)")
            return false
        }
    }
}

/// Secure implementation of StatistiquesRepository using SecureDataService
@MainActor
final class SecureStatistiquesRepository: StatistiquesRepository {
    private let dataService: SecureDataService
    
    init(dataService: SecureDataService = SecureDataService.shared) {
        self.dataService = dataService
    }
    
    func getStatistiques() async -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int) {
        do {
            return try await dataService.getStatistiques()
        } catch {
            print("Error getting statistics: \(error)")
            return (totalCA: 0, facturesEnAttente: 0, facturesEnRetard: 0, totalFactures: 0)
        }
    }
    
    func getStatistiquesParPeriode(startDate: Date, endDate: Date) async -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int) {
        do {
            let factures = try await dataService.fetchFactures()
            let lignes = try await dataService.fetchLignes()
            let facturesPeriode = factures.filter { facture in
                facture.dateFacture >= startDate && facture.dateFacture <= endDate
            }
            
            let totalCA = facturesPeriode.reduce(0) { $0 + $1.calculateTotalTTC(with: lignes) }
            let facturesEnAttente = facturesPeriode.filter { $0.statut == "envoyee" }.count
            let facturesEnRetard = facturesPeriode.filter { $0.statut == StatutFacture.enRetard.rawValue }.count
            let totalFactures = facturesPeriode.count
            
            return (totalCA: totalCA, facturesEnAttente: facturesEnAttente, facturesEnRetard: facturesEnRetard, totalFactures: totalFactures)
        } catch {
            print("Error getting statistics by period: \(error)")
            return (totalCA: 0, facturesEnAttente: 0, facturesEnRetard: 0, totalFactures: 0)
        }
    }
    
    func getStatistiquesParClient(clientId: UUID) async -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int) {
        do {
            let factures = try await dataService.fetchFactures()
            let lignes = try await dataService.fetchLignes()
            let facturesClient = factures.filter { $0.clientId == clientId }
            
            let totalCA = facturesClient.reduce(0) { $0 + $1.calculateTotalTTC(with: lignes) }
            let facturesEnAttente = facturesClient.filter { $0.statut == "envoyee" }.count
            let facturesEnRetard = facturesClient.filter { $0.statut == StatutFacture.enRetard.rawValue }.count
            let totalFactures = facturesClient.count
            
            return (totalCA: totalCA, facturesEnAttente: facturesEnAttente, facturesEnRetard: facturesEnRetard, totalFactures: totalFactures)
        } catch {
            print("Error getting statistics by client: \(error)")
            return (totalCA: 0, facturesEnAttente: 0, facturesEnRetard: 0, totalFactures: 0)
        }
    }
    
    func getCAParMois(annee: Int) async -> [Double] {
        do {
            let factures = try await dataService.fetchFactures()
            let lignes = try await dataService.fetchLignes()
            let calendar = Calendar.current
            
            return (1...12).map { mois in
                let facturesMois = factures.filter { facture in
                    let dateComponents = calendar.dateComponents([.year, .month], from: facture.dateFacture)
                    return dateComponents.year == annee && dateComponents.month == mois
                }
                return facturesMois.reduce(0) { $0 + $1.calculateTotalTTC(with: lignes) }
            }
        } catch {
            print("Error getting CA by month: \(error)")
            return Array(repeating: 0, count: 12)
        }
    }
    
    func getFacturesParStatut() async -> [StatutFacture: Int] {
        do {
            let factures = try await dataService.fetchFactures()
            var result: [StatutFacture: Int] = [:]
            
            for statut in StatutFacture.allCases {
                result[statut] = factures.filter { $0.statut == statut.rawValue }.count
            }
            
            return result
        } catch {
            print("Error getting factures by status: \(error)")
            return [:]
        }
    }
    
    func getStatistiquesProduits(startDate: Date?, endDate: Date?) async -> [(produit: ProduitDTO, quantiteVendue: Double, chiffreAffaires: Double)] {
        do {
            let factures = try await dataService.fetchFactures()
            let lignes = try await dataService.fetchLignes()
            let produits = try await dataService.fetchProduits()
            
            // Filter factures by date range if provided
            let facturesFiltered = factures.filter { facture in
                guard let startDate = startDate, let endDate = endDate else { return true }
                return facture.dateFacture >= startDate && facture.dateFacture <= endDate
            }
            
            // Calculate statistics by product
            var statsParProduit: [UUID: (quantite: Double, chiffreAffaires: Double)] = [:]
            
            for facture in facturesFiltered {
                let factureLignes = lignes.filter { facture.ligneIds.contains($0.id) }
                for ligne in factureLignes {
                    if let produitId = ligne.produitId {
                        let lineTotal = ligne.quantite * ligne.prixUnitaire
                        statsParProduit[produitId, default: (0, 0)].quantite += ligne.quantite
                        statsParProduit[produitId, default: (0, 0)].chiffreAffaires += lineTotal
                    }
                }
            }
            
            // Convert to result format
            return statsParProduit.compactMap { (produitId, stats) in
                guard let produit = produits.first(where: { $0.id == produitId }) else { return nil }
                return (produit: produit, quantiteVendue: stats.quantite, chiffreAffaires: stats.chiffreAffaires)
            }.sorted { $0.chiffreAffaires > $1.chiffreAffaires }
            
        } catch {
            print("Error getting product statistics: \(error)")
            return []
        }
    }
    
    func getStatistiquesClients(startDate: Date?, endDate: Date?) async -> [(client: ClientDTO, chiffreAffaires: Double, nombreFactures: Int)] {
        do {
            let factures = try await dataService.fetchFactures()
            let lignes = try await dataService.fetchLignes()
            let clients = try await dataService.fetchClients()
            
            // Filter factures by date range if provided
            let facturesFiltered = factures.filter { facture in
                guard let startDate = startDate, let endDate = endDate else { return true }
                return facture.dateFacture >= startDate && facture.dateFacture <= endDate
            }
            
            // Calculate statistics by client
            var statsParClient: [UUID: (chiffreAffaires: Double, nombreFactures: Int)] = [:]
            
            for facture in facturesFiltered {
                let clientId = facture.clientId
                let totalFacture = facture.calculateTotalTTC(with: lignes)
                
                statsParClient[clientId, default: (0, 0)].chiffreAffaires += totalFacture
                statsParClient[clientId, default: (0, 0)].nombreFactures += 1
            }
            
            // Convert to result format
            return statsParClient.compactMap { (clientId, stats) in
                guard let client = clients.first(where: { $0.id == clientId }) else { return nil }
                return (client: client, chiffreAffaires: stats.chiffreAffaires, nombreFactures: stats.nombreFactures)
            }.sorted { $0.chiffreAffaires > $1.chiffreAffaires }
            
        } catch {
            print("Error getting client statistics: \(error)")
            return []
        }
    }
}