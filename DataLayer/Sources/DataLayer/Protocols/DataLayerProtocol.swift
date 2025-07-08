import Foundation
import SwiftData

@MainActor
public protocol DataLayerProtocol: ObservableObject {
    // MARK: - Client Operations
    func fetchClients() async -> [ClientDTO]
    func addClient(_ client: ClientDTO) async throws
    func updateClient(_ client: ClientDTO) async throws
    func deleteClient(id: UUID) async throws
    
    // MARK: - Facture Operations
    func fetchFactures() async -> [FactureDTO]
    func addFacture(_ facture: FactureDTO) async throws
    func updateFacture(_ facture: FactureDTO) async throws
    func deleteFacture(id: UUID) async throws
    func genererNumeroFacture() async throws -> String
    
    // MARK: - Produit Operations
    func fetchProduits() async -> [ProduitDTO]
    func addProduit(_ produit: ProduitDTO) async throws
    func updateProduit(_ produit: ProduitDTO) async throws
    func deleteProduit(id: UUID) async throws
    
    // MARK: - Entreprise Operations
    func fetchEntreprise() async -> EntrepriseDTO?
    func updateEntreprise(_ entreprise: EntrepriseDTO) async throws
    
    // MARK: - Statistics
    func getStatistiques() async -> StatistiquesDTO
}

// MARK: - DataLayerProtocol Implementation  
// DataService will need to implement these methods to conform to the protocol