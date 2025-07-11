import Foundation
import SwiftData
import DataLayer

/// Secure DataService implementation that doesn't expose data directly
/// This service is only used internally by repositories and should not be accessed directly by Views
@MainActor
final class SecureDataService {
    
    // MARK: - Private Properties
    private let container: ModelContainer
    private let context: ModelContext
    
    // MARK: - Initialization
    init() {
        do {
            self.container = try ModelContainer(for: 
                ClientModel.self,
                FactureModel.self,
                ProduitModel.self,
                EntrepriseModel.self,
                LigneFacture.self
            )
            self.context = ModelContext(container)
        } catch {
            print("Failed to initialize ModelContainer: \(error)")
            // Fallback to in-memory storage
            self.container = try! ModelContainer(for: 
                ClientModel.self,
                FactureModel.self,
                ProduitModel.self,
                EntrepriseModel.self,
                LigneFacture.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            self.context = ModelContext(container)
        }
    }
    
    // MARK: - Client Operations
    
    func fetchClients() async throws -> [ClientDTO] {
        let descriptor = FetchDescriptor<ClientModel>()
        let clients = try context.fetch(descriptor)
        return clients.map { $0.toDTO() }
    }
    
    func addClient(_ clientDTO: ClientDTO) async throws -> Bool {
        let client = ClientModel.fromDTO(clientDTO)
        context.insert(client)
        try context.save()
        return true
    }
    
    func updateClient(_ clientDTO: ClientDTO) async throws -> Bool {
        let descriptor = FetchDescriptor<ClientModel>(
            predicate: #Predicate { $0.id == clientDTO.id }
        )
        guard let client = try context.fetch(descriptor).first else {
            throw DataServiceError.clientNotFound
        }
        
        client.updateFromDTO(clientDTO)
        try context.save()
        return true
    }
    
    func deleteClient(id: UUID) async throws -> Bool {
        let descriptor = FetchDescriptor<ClientModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let client = try context.fetch(descriptor).first else {
            throw DataServiceError.clientNotFound
        }
        
        context.delete(client)
        try context.save()
        return true
    }
    
    func searchClients(searchText: String) async throws -> [ClientDTO] {
        let descriptor = FetchDescriptor<ClientModel>(
            predicate: #Predicate { client in
                client.nom.localizedStandardContains(searchText) ||
                client.nom.localizedStandardContains(searchText) ||
                client.email.localizedStandardContains(searchText)
            }
        )
        let clients: [ClientModel] = try context.fetch(descriptor)
        return clients.map { $0.toDTO() }
    }
    
    // MARK: - Facture Operations
    
    func fetchFactures() async throws -> [FactureDTO] {
        let descriptor = FetchDescriptor<FactureModel>()
        let factures = try context.fetch(descriptor)
        return factures.map { $0.toDTO() }
    }
    
    func addFacture(_ factureDTO: FactureDTO) async throws -> Bool {
        // First, find the client
        let clientDescriptor = FetchDescriptor<ClientModel>(
            predicate: #Predicate { $0.id == factureDTO.clientId }
        )
        guard let client: ClientModel = try context.fetch(clientDescriptor).first else {
            throw DataServiceError.clientNotFound
        }
        
        let facture = FactureModel.fromDTO(factureDTO, context: context, client: client, lignes: [])
        context.insert(facture)
        try context.save()
        return true
    }
    
    func updateFacture(_ factureDTO: FactureDTO) async throws -> Bool {
        let descriptor = FetchDescriptor<FactureModel>(
            predicate: #Predicate { $0.id == factureDTO.id }
        )
        guard let facture = try context.fetch(descriptor).first else {
            throw DataServiceError.factureNotFound
        }
        
        facture.updateFromDTO(factureDTO)
        try context.save()
        return true
    }
    
    func deleteFacture(id: UUID) async throws -> Bool {
        let descriptor = FetchDescriptor<FactureModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let facture = try context.fetch(descriptor).first else {
            throw DataServiceError.factureNotFound
        }
        
        context.delete(facture)
        try context.save()
        return true
    }
    
    func genererNumeroFacture() async throws -> String {
        let entrepriseDescriptor = FetchDescriptor<EntrepriseModel>()
        let entreprises = try context.fetch(entrepriseDescriptor)
        
        if let entreprise = entreprises.first {
            let nouveauNumero = entreprise.prochainNumero
            let numeroComplet = "\(entreprise.prefixeFacture)\(String(format: "%04d", nouveauNumero))"
            
            entreprise.prochainNumero += 1
            try context.save()
            
            return numeroComplet
        } else {
            // Create default entreprise if none exists
            let defaultEntreprise = EntrepriseModel()
            
            context.insert(defaultEntreprise)
            try context.save()
            
            return "FAC0001"
        }
    }
    
    // MARK: - Produit Operations
    
    func fetchProduits() async throws -> [ProduitDTO] {
        let descriptor = FetchDescriptor<ProduitModel>()
        let produits = try context.fetch(descriptor)
        return produits.map { $0.toDTO() }
    }
    
    func addProduit(_ produitDTO: ProduitDTO) async throws -> Bool {
        let produit = ProduitModel.fromDTO(produitDTO)
        context.insert(produit)
        try context.save()
        return true
    }
    
    func updateProduit(_ produitDTO: ProduitDTO) async throws -> Bool {
        let descriptor = FetchDescriptor<ProduitModel>(
            predicate: #Predicate { $0.id == produitDTO.id }
        )
        guard let produit = try context.fetch(descriptor).first else {
            throw DataServiceError.produitNotFound
        }
        
        produit.updateFromDTO(produitDTO)
        try context.save()
        return true
    }
    
    func deleteProduit(id: UUID) async throws -> Bool {
        let descriptor = FetchDescriptor<ProduitModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let produit = try context.fetch(descriptor).first else {
            throw DataServiceError.produitNotFound
        }
        
        context.delete(produit)
        try context.save()
        return true
    }
    
    func searchProduits(searchText: String) async throws -> [ProduitDTO] {
        let descriptor = FetchDescriptor<ProduitModel>(
            predicate: #Predicate { produit in
                produit.designation.localizedStandardContains(searchText) ||
                (produit.details ?? "").localizedStandardContains(searchText)
            }
        )
        let produits: [ProduitModel] = try context.fetch(descriptor)
        return produits.map { $0.toDTO() }
    }
    
    // MARK: - Entreprise Operations
    
    func fetchEntreprise() async throws -> EntrepriseDTO? {
        let descriptor = FetchDescriptor<EntrepriseModel>()
        let entreprises = try context.fetch(descriptor)
        return entreprises.first?.toDTO()
    }
    
    func updateEntreprise(_ entrepriseDTO: EntrepriseDTO) async throws -> Bool {
        let descriptor = FetchDescriptor<EntrepriseModel>()
        let entreprises = try context.fetch(descriptor)
        
        if let entreprise = entreprises.first {
            entreprise.updateFromDTO(entrepriseDTO)
        } else {
            let nouvelleEntreprise = EntrepriseModel.fromDTO(entrepriseDTO)
            context.insert(nouvelleEntreprise)
        }
        
        try context.save()
        return true
    }
    
    // MARK: - Statistics Operations
    
    func getStatistiques() async throws -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int) {
        let facturesDescriptor = FetchDescriptor<FactureModel>()
        let factures = try context.fetch(facturesDescriptor)
        
        let totalCA = factures.reduce(0) { $0 + $1.totalTTC }
        let facturesEnAttente = factures.filter { $0.statut == StatutFacture.envoyee }.count
        let facturesEnRetard = factures.filter { $0.statut == StatutFacture.enRetard }.count
        let totalFactures = factures.count
        
        return (totalCA: totalCA, facturesEnAttente: facturesEnAttente, facturesEnRetard: facturesEnRetard, totalFactures: totalFactures)
    }
    
    // MARK: - Ligne Facture Operations
    
    func fetchLignes() async throws -> [LigneFactureDTO] {
        let descriptor = FetchDescriptor<LigneFacture>()
        let lignes: [LigneFacture] = try context.fetch(descriptor)
        return lignes.map { $0.toDTO() }
    }
    
    func addLigne(_ ligneDTO: LigneFactureDTO) async throws -> Bool {
        let ligne = LigneFacture.fromDTO(ligneDTO)
        context.insert(ligne)
        
        do {
            try context.save()
            return true
        } catch {
            throw DataServiceError.contextSaveError
        }
    }
    
    func updateLigne(_ ligneDTO: LigneFactureDTO) async throws -> Bool {
        let descriptor = FetchDescriptor<LigneFacture>(predicate: #Predicate { $0.id == ligneDTO.id })
        guard let ligne: LigneFacture = try context.fetch(descriptor).first else {
            throw DataServiceError.factureNotFound
        }
        
        ligne.updateFromDTO(ligneDTO)
        
        do {
            try context.save()
            return true
        } catch {
            throw DataServiceError.contextSaveError
        }
    }
    
    func deleteLigne(id: UUID) async throws -> Bool {
        let descriptor = FetchDescriptor<LigneFacture>(predicate: #Predicate<LigneFacture> { $0.id == id })
        guard let ligne: LigneFacture = try context.fetch(descriptor).first else {
            throw DataServiceError.factureNotFound
        }
        
        context.delete(ligne)
        
        do {
            try context.save()
            return true
        } catch {
            throw DataServiceError.contextSaveError
        }
    }
    
    // MARK: - Shared Instance
    static let shared = SecureDataService()
}

// MARK: - Custom Errors

enum DataServiceError: Error {
    case clientNotFound
    case factureNotFound
    case produitNotFound
    case entrepriseNotFound
    case contextSaveError
    
    var localizedDescription: String {
        switch self {
        case .clientNotFound:
            return "Client non trouvé"
        case .factureNotFound:
            return "Facture non trouvée"
        case .produitNotFound:
            return "Produit non trouvé"
        case .entrepriseNotFound:
            return "Entreprise non trouvée"
        case .contextSaveError:
            return "Erreur lors de la sauvegarde"
        }
    }
}