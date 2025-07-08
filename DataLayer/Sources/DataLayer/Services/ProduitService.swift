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
    
    /// Fetch all products sorted by designation
    public func fetchProduits() async -> [ProduitDTO] {
        logger.info("Fetching produits")
        do {
            let descriptor = FetchDescriptor<ProduitModel>(sortBy: [SortDescriptor(\ProduitModel.designation)])
            let models: [ProduitModel] = try persistenceService.fetch(descriptor)
            let dtos = models.map { $0.toDTO() }

            await MainActor.run { self.produits = dtos }
            logger.info("Fetched produits successfully", metadata: ["count": "\(dtos.count)"])
            return dtos
        } catch {
            logger.error("Failed to fetch produits", metadata: ["error": "\(error)"])
            return []
        }
    }
    
    public func addProduit(_ produit: ProduitDTO) async throws {
        logger.info("Adding produit", metadata: ["produitId": "\(produit.id)", "designation": "\(produit.designation)"])

        guard !produit.designation.trimmingCharacters(in: .whitespaces).isEmpty, produit.prixUnitaire > 0 else {
            logger.warning("Invalid product data")
            return
        }

        let model = ProduitModel.fromDTO(produit)
        persistenceService.insert(model)
        try persistenceService.save()
        await fetchProduits()
        logger.info("Produit added successfully", metadata: ["produitId": "\(produit.id)"])
    }
    
    public func updateProduit(_ produit: ProduitDTO) async throws {
        logger.info("Updating produit", metadata: ["produitId": "\(produit.id)", "designation": "\(produit.designation)"])

        let descriptor = FetchDescriptor<ProduitModel>(predicate: #Predicate { $0.id == produit.id })
        if let existing = try? persistenceService.fetch(descriptor).first {
            existing.updateFromDTO(produit)
            try persistenceService.save()
            await fetchProduits()
            logger.info("Produit updated successfully", metadata: ["produitId": "\(produit.id)"])
        } else {
            logger.warning("Produit not found", metadata: ["produitId": "\(produit.id)"])
        }
    }
    
    public func deleteProduit(withId id: UUID) async throws {
        logger.info("Deleting produit", metadata: ["produitId": "\(id)"])

        let descriptor = FetchDescriptor<ProduitModel>(predicate: #Predicate { $0.id == id })
        guard let produit = try? persistenceService.fetch(descriptor).first, produit.isValidModel else {
            logger.warning("Produit not found", metadata: ["produitId": "\(id)"])
            return
        }

        // Detach from invoice lines
        let ligneDescriptor = FetchDescriptor<LigneFacture>(predicate: #Predicate { $0.produit?.id == id })
        let lignes = (try? persistenceService.fetch(ligneDescriptor)) ?? []
        for ligne in lignes where ligne.isValidModel { ligne.produit = nil }

        persistenceService.delete(produit)
        try persistenceService.save()
        await fetchProduits()
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