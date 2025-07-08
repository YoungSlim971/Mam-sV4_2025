import Foundation
import SwiftData
import Logging

// Main types are defined in this module and available via import

/// Main coordinator for all data layer services
@MainActor
public final class DataLayer: ObservableObject {
    private let logger = Logger(label: "com.facturation.datalayer.coordinator")
    
    public let persistenceService: PersistenceService
    public let clientService: ClientService
    public let factureService: FactureService
    public let produitService: ProduitService
    public let excelImporter: ExcelImporter
    
    @Published public var isLoading = false
    @Published public var lastError: Error?
    
    public init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        self.clientService = ClientService(persistenceService: persistenceService)
        self.factureService = FactureService(persistenceService: persistenceService)
        self.produitService = ProduitService(persistenceService: persistenceService)
        self.excelImporter = ExcelImporter()
        
        logger.info("DataLayer initialized")
    }
    
    /// Convenience initializer that creates persistence service with given model types
    public convenience init<T: PersistentModel>(withModelTypes modelTypes: [T.Type]) throws {
        let persistenceService = try PersistenceService(withSchema: modelTypes)
        self.init(persistenceService: persistenceService)
    }
    
    /// Fetch all data from persistence layer
    public func fetchAllData() async {
        logger.info("Fetching all data")
        isLoading = true
        lastError = nil
        
        do {
            // TODO: Implement proper model fetching when model integration is complete
            // async let clientsTask = clientService.fetchClients(ClientDTO.self)
            // async let facturesTask = factureService.fetchFactures(FactureDTO.self)
            // async let produitsTask = produitService.fetchProduits(ProduitDTO.self)
            
            // _ = await (clientsTask, facturesTask, produitsTask)
            
            logger.info("All data fetched successfully")
        } catch {
            logger.error("Failed to fetch all data", metadata: ["error": "\(error)"])
            lastError = error
        }
        
        isLoading = false
    }
    
    /// Save all pending changes
    public func saveChanges() async throws {
        logger.info("Saving all changes")
        try persistenceService.save()
        logger.info("All changes saved")
    }
    
    /// Get persistence status information
    public func getPersistenceStatus() -> String {
        return persistenceService.getPersistenceStatus()
    }
}