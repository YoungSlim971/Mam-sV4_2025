import Foundation
import DataLayer

/// Repository public protocol for client operations
public protocol ClientRepository {
    func fetchClients() async -> [ClientDTO]
    func addClient(_ client: ClientDTO) async -> Bool
    func updateClient(_ client: ClientDTO) async -> Bool
    func deleteClient(id: UUID) async -> Bool
    func searchClients(searchText: String) async -> [ClientDTO]
    func getClient(id: UUID) async -> ClientDTO?
}

/// Repository public protocol for invoice operations
public protocol FactureRepository {
    func fetchFactures() async -> [FactureDTO]
    func addFacture(_ facture: FactureDTO) async -> Bool
    func updateFacture(_ facture: FactureDTO) async -> Bool
    func deleteFacture(id: UUID) async -> Bool
    func getFacture(id: UUID) async -> FactureDTO?
    func genererNumeroFacture() async -> String
    func searchFactures(searchText: String) async -> [FactureDTO]
    func getFacturesForClient(clientId: UUID) async -> [FactureDTO]
    func getFacturesByStatus(status: StatutFacture) async -> [FactureDTO]
    func getFacturesByDateRange(startDate: Date, endDate: Date) async -> [FactureDTO]
    
    // Ligne facture operations
    func fetchLignes() async -> [LigneFactureDTO]
    func addLigne(_ ligne: LigneFactureDTO) async -> Bool
    func updateLigne(_ ligne: LigneFactureDTO) async -> Bool
    func deleteLigne(id: UUID) async -> Bool
}

/// Repository public protocol for product operations
public protocol ProduitRepository {
    func fetchProduits() async -> [ProduitDTO]
    func addProduit(_ produit: ProduitDTO) async -> Bool
    func updateProduit(_ produit: ProduitDTO) async -> Bool
    func deleteProduit(id: UUID) async -> Bool
    func searchProduits(searchText: String) async -> [ProduitDTO]
    func getProduit(id: UUID) async -> ProduitDTO?
}

/// Repository public protocol for enterprise operations
public protocol EntrepriseRepository {
    func fetchEntreprise() async -> EntrepriseDTO?
    func updateEntreprise(_ entreprise: EntrepriseDTO) async -> Bool
    func createEntreprise(_ entreprise: EntrepriseDTO) async -> Bool
}

/// Repository public protocol for statistics operations
public protocol StatistiquesRepository {
    func getStatistiques() async -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int)
    func getStatistiquesParPeriode(startDate: Date, endDate: Date) async -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int)
    func getStatistiquesParClient(clientId: UUID) async -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int)
    func getCAParMois(annee: Int) async -> [Double]
    func getFacturesParStatut() async -> [StatutFacture: Int]
    func getStatistiquesProduits(startDate: Date?, endDate: Date?) async -> [(produit: ProduitDTO, quantiteVendue: Double, chiffreAffaires: Double)]
    func getStatistiquesClients(startDate: Date?, endDate: Date?) async -> [(client: ClientDTO, chiffreAffaires: Double, nombreFactures: Int)]
}