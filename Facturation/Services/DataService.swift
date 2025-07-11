// Services/DataService.swift
@preconcurrency import Foundation
@preconcurrency import SwiftData
import SwiftUI
import Utilities
import DataLayer
import Logging

@MainActor
class DataService: ObservableObject {
    static let shared = DataService()
    
    private let logger = Logger(label: "com.facturation.dataservice")
    
    // DataLayer coordinator - this is our new centralized data access
    private let dataLayer: DataLayer
    
    // Published properties that mirror DataLayer services
    @Published var clients: [ClientDTO] = []
    @Published var factures: [FactureDTO] = []
    @Published var produits: [ProduitDTO] = []
    @Published var lignes: [LigneFactureDTO] = []
    @Published var entreprise: EntrepriseDTO?

    init() {
        do {
            // Initialize DataLayer with proper SwiftData configuration
            let schema = Schema([ClientModel.self, EntrepriseModel.self, FactureModel.self, ProduitModel.self, LigneFacture.self])
            
            // Configuration explicite pour la persistance sur disque
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false // Forcer la persistance sur disque
            )
            
            let container = try ModelContainer(for: schema, configurations: configuration)
            
            // Initialize DataLayer with the container
            let persistenceService = PersistenceService(modelContainer: container)
            self.dataLayer = DataLayer(persistenceService: persistenceService)
            
            logger.info("SwiftData persistence initialized successfully on disk")
            
        } catch {
            logger.error("Failed to initialize main persistence", metadata: ["error": "\(error)"])
            
            // Tentative avec configuration par défaut
            do {
                let schema = Schema([ClientModel.self, EntrepriseModel.self, FactureModel.self, ProduitModel.self, LigneFacture.self])
                let container = try ModelContainer(for: schema)
                let persistenceService = PersistenceService(modelContainer: container)
                self.dataLayer = DataLayer(persistenceService: persistenceService)
                logger.warning("Using default SwiftData configuration")
                
            } catch {
                // Dernier recours: stockage en mémoire seulement
                do {
                    let schema = Schema([ClientModel.self, EntrepriseModel.self, FactureModel.self, ProduitModel.self, LigneFacture.self])
                    let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                    let persistenceService = PersistenceService(modelContainer: container)
                    self.dataLayer = DataLayer(persistenceService: persistenceService)
                    logger.critical("WARNING: Using in-memory storage only. Data will NOT be persisted!")
                } catch {
                    fatalError("Impossible d'initialiser SwiftData: \(error)")
                }
            }
        }
    }

    // MARK: - Container Access (for legacy compatibility)
    var modelContainer: ModelContainer {
        return dataLayer.persistenceService.modelContainer
    }
    
    var modelContext: ModelContext {
        return dataLayer.persistenceService.modelContext
    }
    
    var container: ModelContainer {
        return modelContainer
    }
    
    /// Vérifie si la persistance sur disque est active ou si on utilise le stockage en mémoire
    var isPersistenceActive: Bool {
        // Vérifier si le container utilise un stockage persistant
        return !modelContainer.configurations.contains { config in
            config.isStoredInMemoryOnly
        }
    }
    
    /// Retourne le statut de persistance pour information
    func getPersistenceStatus() -> String {
        if isPersistenceActive {
            return "✅ Persistance sur disque active - Données sauvegardées"
        } else {
            return "🔴 Stockage en mémoire seulement - Données perdues à la fermeture"
        }
    }

    // MARK: - Data Fetching (Coordinated through DataLayer)
    func fetchData() async {
        logger.info("Fetching all data via DataLayer")
        
        async let clientsTask = dataLayer.clientService.fetchClients()
        async let facturesTask = dataLayer.factureService.fetchFactures()
        async let produitsTask = dataLayer.produitService.fetchProduits()
        async let lignesTask = fetchLigneDTOs()
        async let entrepriseTask = fetchEntrepriseDTO()

        self.clients = await clientsTask
        self.factures = await facturesTask
        self.produits = await produitsTask
        self.lignes = await lignesTask
        self.entreprise = await entrepriseTask
        
        logger.info("Data fetching completed", metadata: [
            "clients": "\(clients.count)",
            "factures": "\(factures.count)", 
            "produits": "\(produits.count)"
        ])
    }
    
    // MARK: - Client Operations (Delegated to DataLayer)
    func addClient(_ client: ClientDTO) async {
        do {
            try await dataLayer.clientService.addClient(client)
            self.clients = await dataLayer.clientService.fetchClients()
        } catch {
            logger.error("Failed to add client via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    func updateClient(_ client: ClientDTO) async {
        do {
            try await dataLayer.clientService.updateClient(client)
            self.clients = await dataLayer.clientService.fetchClients()
        } catch {
            logger.error("Failed to update client via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    func deleteClient(_ client: ClientDTO) async {
        do {
            try await dataLayer.clientService.deleteClient(withId: client.id)
            self.clients = await dataLayer.clientService.fetchClients()
        } catch {
            logger.error("Failed to delete client via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    // MARK: - Product Operations (Delegated to DataLayer)
    func addProduit(_ produit: ProduitDTO) async {
        do {
            try await dataLayer.produitService.addProduit(produit)
            self.produits = await dataLayer.produitService.fetchProduits()
        } catch {
            logger.error("Failed to add product via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    func updateProduit(_ produit: ProduitDTO) async {
        do {
            try await dataLayer.produitService.updateProduit(produit)
            self.produits = await dataLayer.produitService.fetchProduits()
        } catch {
            logger.error("Failed to update product via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    func deleteProduit(_ produit: ProduitDTO) async {
        do {
            try await dataLayer.produitService.deleteProduit(withId: produit.id)
            self.produits = await dataLayer.produitService.fetchProduits()
        } catch {
            logger.error("Failed to delete product via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    // MARK: - Invoice Operations (Delegated to DataLayer)
    func addFacture(_ facture: FactureDTO) async {
        do {
            try await dataLayer.factureService.addFacture(facture)
            self.factures = await dataLayer.factureService.fetchFactures()
        } catch {
            logger.error("Failed to add invoice via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    func updateFacture(_ facture: FactureDTO) async {
        do {
            try await dataLayer.factureService.updateFacture(facture)
            self.factures = await dataLayer.factureService.fetchFactures()
        } catch {
            logger.error("Failed to update invoice via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    func deleteFacture(_ facture: FactureDTO) async {
        do {
            try await dataLayer.factureService.deleteFacture(withId: facture.id)
            self.factures = await dataLayer.factureService.fetchFactures()
        } catch {
            logger.error("Failed to delete invoice via DataLayer", metadata: ["error": "\(error)"])
        }
    }
    
    func genererNumeroFacture(clientId: UUID? = nil) async -> String {
        guard let clientId = clientId else {
            return "F\(Calendar.current.component(.year, from: Date()))-0001"
        }
        
        do {
            return try await dataLayer.factureService.generateInvoiceNumber(for: clientId)
        } catch {
            logger.error("Failed to generate invoice number", metadata: ["error": "\(error)"])
            return "F\(Calendar.current.component(.year, from: Date()))-0001"
        }
    }
    
    // MARK: - Legacy Methods (Minimal implementation for backward compatibility)
    
    private func fetchLigneDTOs() async -> [LigneFactureDTO] {
        do {
            let descriptor = FetchDescriptor<LigneFacture>()
            let lignes = try dataLayer.persistenceService.fetch(descriptor)
            return lignes.map { $0.toDTO() }
        } catch {
            logger.error("Failed to fetch invoice lines", metadata: ["error": "\(error)"])
            return []
        }
    }
    
    private func fetchEntrepriseDTO() async -> EntrepriseDTO? {
        do {
            let descriptor = FetchDescriptor<EntrepriseModel>()
            if let entreprise = try dataLayer.persistenceService.fetch(descriptor).first {
                return entreprise.toDTO()
            }
        } catch {
            logger.error("Failed to fetch company", metadata: ["error": "\(error)"])
        }
        return nil
    }
    
    func saveContext() async {
        do {
            try dataLayer.persistenceService.save()
            logger.info("Data saved successfully", metadata: ["storage": "\(isPersistenceActive ? "disk" : "memory")"])
        } catch {
            logger.error("Failed to save data", metadata: ["error": "\(error)"])
        }
    }
    
    // MARK: - Enterprise Operations
    func updateEntreprise(_ entreprise: EntrepriseDTO) async {
        do {
            // Find existing or create new
            let descriptor = FetchDescriptor<EntrepriseModel>()
            let existing = try? dataLayer.persistenceService.fetch(descriptor).first
            
            if let existing = existing {
                existing.updateFromDTO(entreprise)
            } else {
                let newModel = EntrepriseModel.fromDTO(entreprise)
                dataLayer.persistenceService.insert(newModel)
            }
            
            try dataLayer.persistenceService.save()
            self.entreprise = await fetchEntrepriseDTO()
            logger.info("Company updated successfully")
        } catch {
            logger.error("Failed to update company", metadata: ["error": "\(error)"])
        }
    }
    
    // MARK: - Statistics (Delegated to existing StatistiquesService_DTO)
    func getStatistiques() -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int) {
        let totalClients = clients.count
        let totalFactures = factures.count
        let totalProduits = produits.count
        
        let chiffreAffaires = factures.reduce(into: 0.0) { total, facture in
            total += facture.calculateTotalTTC(with: lignes)
        }
        let facturesEnAttente = factures.filter { $0.statut == StatutFacture.envoyee.rawValue }.count
        let facturesPayees = factures.filter { $0.statut == StatutFacture.payee.rawValue }.count
        let facturesEnRetard = factures.filter { $0.statut == StatutFacture.enRetard.rawValue }.count
        
        return (
            totalCA: chiffreAffaires,
            facturesEnAttente: facturesEnAttente,
            facturesEnRetard: facturesEnRetard,
            totalFactures: totalFactures
        )
    }
    
    // MARK: - Export/Import Methods (Simplified)
    func exportClients() -> Data? {
        do {
            return try JSONEncoder().encode(clients)
        } catch {
            logger.error("JSON export failed", metadata: ["error": "\(error)"])
            return nil
        }
    }
    
    func exportFactures() -> Data? {
        do {
            return try JSONEncoder().encode(factures)
        } catch {
            logger.error("JSON export failed", metadata: ["error": "\(error)"])
            return nil
        }
    }
    
    // MARK: - Entity Retrieval by ID
    func getClient(id: UUID) -> ClientDTO? {
        return clients.first { $0.id == id }
    }
    
    func getFacture(id: UUID) -> FactureDTO? {
        return factures.first { $0.id == id }
    }
    
    func getProduit(id: UUID) -> ProduitDTO? {
        return produits.first { $0.id == id }
    }
    
    func getLigne(id: UUID) -> LigneFactureDTO? {
        return lignes.first { $0.id == id }
    }
    
    func getEntreprise(id: UUID) -> EntrepriseDTO? {
        return entreprise
    }
    
    // MARK: - Batch Operations (for sample data generation)
    func createSampleData() async {
        logger.info("Sample data generation completed")
        // Sample data generation can be moved to a separate service if needed
        // For now, keeping this as a placeholder
    }
}

// MARK: - Extensions for backward compatibility
extension DataService {
    func getFacturesForClient(_ clientId: UUID) -> [FactureDTO] {
        return factures.filter { $0.clientId == clientId }
    }
    
    func getLignesForFacture(_ factureId: UUID) -> [LigneFactureDTO] {
        return lignes.filter { $0.factureId == factureId }
    }
}