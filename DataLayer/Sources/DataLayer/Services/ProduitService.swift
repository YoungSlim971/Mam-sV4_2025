import Foundation
import SwiftData
import Logging

@MainActor
public final class ProduitService: ObservableObject {
    private let logger = Logger(label: "com.facturation.datalayer.produit")
    private let persistenceService: PersistenceService
    
    @Published public var produits: [ProduitDTO] = []
    
    public init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
    }
    
    public func fetchProduits<T: PersistentModel>(_ modelType: T.Type) async -> [ProduitDTO] {
        logger.info("Fetching produits")
        do {
            let descriptor = FetchDescriptor<T>(sortBy: [SortDescriptor(\T.persistentModelID)])
            let models = try persistenceService.fetch(descriptor)
            
            // Convert models to DTOs - this would need to be implemented based on actual model structure
            let dtos: [ProduitDTO] = [] // TODO: Implement conversion
            
            await MainActor.run {
                self.produits = dtos
            }
            logger.info("Fetched produits successfully", metadata: ["count": "\(dtos.count)"])
            return dtos
        } catch {
            logger.error("Failed to fetch produits", metadata: ["error": "\(error)"])
            return []
        }
    }
    
    public func addProduit(_ produit: ProduitDTO) async throws {
        logger.info("Adding produit", metadata: ["produitId": "\(produit.id)", "designation": "\(produit.designation)"])
        
        // TODO: Convert DTO to model and insert
        
        try persistenceService.save()
        // TODO: Refresh the list when model integration is complete
        logger.info("Produit added successfully", metadata: ["produitId": "\(produit.id)"])
    }
    
    public func updateProduit(_ produit: ProduitDTO) async throws {
        logger.info("Updating produit", metadata: ["produitId": "\(produit.id)", "designation": "\(produit.designation)"])
        
        // TODO: Find existing model and update from DTO
        
        try persistenceService.save()
        // TODO: Refresh the list when model integration is complete
        logger.info("Produit updated successfully", metadata: ["produitId": "\(produit.id)"])
    }
    
    public func deleteProduit(withId id: UUID) async throws {
        logger.info("Deleting produit", metadata: ["produitId": "\(id)"])
        
        // TODO: Find and delete model
        
        try persistenceService.save()
        // TODO: Refresh the list when model integration is complete
        logger.info("Produit deleted successfully", metadata: ["produitId": "\(id)"])
    }
    
    public func findProduit(byId id: UUID) -> ProduitDTO? {
        return produits.first { $0.id == id }
    }
    
    public func searchProduits(query: String) -> [ProduitDTO] {
        guard !query.isEmpty else { return produits }
        
        let lowercaseQuery = query.lowercased()
        return produits.filter { produit in
            produit.designation.lowercased().contains(lowercaseQuery) ||
            (produit.details?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }
}