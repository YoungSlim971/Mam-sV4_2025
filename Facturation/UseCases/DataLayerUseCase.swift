import Foundation
import DataLayer

/// Base use case that provides access to data layer
@MainActor
public class DataLayerUseCase: ObservableObject {
    internal let dataService: DataService
    
    public init(dataService: DataService) {
        self.dataService = dataService
    }
}

/// Use case for client operations
@MainActor
public final class ClientUseCase: DataLayerUseCase {
    public func fetchClients() async -> [ClientDTO] {
        await dataService.fetchClients()
    }
    
    public func addClient(_ client: ClientDTO) async {
        await dataService.addClientDTO(client)
    }
    
    public func updateClient(_ client: ClientDTO) async {
        await dataService.updateClientDTO(client)
    }
    
    public func deleteClient(id: UUID) async {
        await dataService.deleteClientDTO(id: id)
    }
}

/// Use case for facture operations
@MainActor
public final class FactureUseCase: DataLayerUseCase {
    public func fetchFactures() async -> [FactureDTO] {
        return dataService.factures
    }
    
    public func addFacture(_ facture: FactureDTO) async {
        await dataService.addFactureDTO(facture)
    }
    
    public func updateFacture(_ facture: FactureDTO) async {
        await dataService.updateFactureDTO(facture)
    }
    
    public func deleteFacture(id: UUID) async {
        await dataService.deleteFactureDTO(id: id)
    }
}

/// Use case for produit operations
@MainActor
public final class ProduitUseCase: DataLayerUseCase {
    public func fetchProduits() async -> [ProduitDTO] {
        return dataService.produits
    }
    
    public func addProduit(_ produit: ProduitDTO) async {
        await dataService.addProduitDTO(produit)
    }
    
    public func updateProduit(_ produit: ProduitDTO) async {
        await dataService.updateProduitDTO(produit)
    }
    
    public func deleteProduit(id: UUID) async {
        await dataService.deleteProduitDTO(id: id)
    }
}

/// Use case for entreprise operations
@MainActor
public final class EntrepriseUseCase: DataLayerUseCase {
    public func fetchEntreprise() async -> EntrepriseDTO? {
        return dataService.entreprise
    }
    
    public func updateEntreprise(_ entreprise: EntrepriseDTO) async {
        await dataService.updateEntrepriseDTO(entreprise)
    }
}

/// Use case for statistics operations
@MainActor
public final class StatistiquesUseCase: DataLayerUseCase {
    public func getStatistiques() -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int) {
        return dataService.getStatistiques()
    }
}
