import Foundation
import DataLayer

/// Use case for fetching all products
@MainActor
final class FetchProduitsUseCase {
    private let repository: ProduitRepository
    
    init(repository: ProduitRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<[ProduitDTO], Error> {
        let produits = await repository.fetchProduits()
        return .success(produits)
    }
}

/// Use case for adding a new product
@MainActor
final class AddProduitUseCase {
    private let repository: ProduitRepository
    
    init(repository: ProduitRepository) {
        self.repository = repository
    }
    
    func execute(designation: String, details: String?, prixUnitaire: Double) async -> Result<Bool, Error> {
        let produit = ProduitDTO(
            id: UUID(),
            designation: designation,
            details: details,
            prixUnitaire: prixUnitaire
        )
        
        let success = await repository.addProduit(produit)
        return .success(success)
    }
}

/// Use case for updating a product
@MainActor
final class UpdateProduitUseCase {
    private let repository: ProduitRepository
    
    init(repository: ProduitRepository) {
        self.repository = repository
    }
    
    func execute(produit: ProduitDTO) async -> Result<Bool, Error> {
        let success = await repository.updateProduit(produit)
        return .success(success)
    }
}

/// Use case for deleting a product
@MainActor
final class DeleteProduitUseCase {
    private let repository: ProduitRepository
    
    init(repository: ProduitRepository) {
        self.repository = repository
    }
    
    func execute(produitId: UUID) async -> Result<Bool, Error> {
        let success = await repository.deleteProduit(id: produitId)
        return .success(success)
    }
}

/// Use case for searching products
@MainActor
final class SearchProduitsUseCase {
    private let repository: ProduitRepository
    
    init(repository: ProduitRepository) {
        self.repository = repository
    }
    
    func execute(searchText: String) async -> Result<[ProduitDTO], Error> {
        let produits = await repository.searchProduits(searchText: searchText)
        return .success(produits)
    }
}

/// Use case for getting a specific product
@MainActor
final class GetProduitUseCase {
    private let repository: ProduitRepository
    
    init(repository: ProduitRepository) {
        self.repository = repository
    }
    
    func execute(produitId: UUID) async -> Result<ProduitDTO?, Error> {
        let produit = await repository.getProduit(id: produitId)
        return .success(produit)
    }
}