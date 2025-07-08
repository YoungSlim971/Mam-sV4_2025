import Foundation
import SwiftData
import Logging

@MainActor
public final class ClientService: ObservableObject {
    private let logger = Logger(label: "com.facturation.datalayer.client")
    private let persistenceService: PersistenceService
    
    @Published public var clients: [ClientDTO] = []
    
    public init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
    }
    
    public func fetchClients<T: PersistentModel>(_ modelType: T.Type) async -> [ClientDTO] {
        logger.info("Fetching clients")
        do {
            let descriptor = FetchDescriptor<T>(sortBy: [SortDescriptor(\T.persistentModelID)])
            let models = try persistenceService.fetch(descriptor)
            
            // Convert models to DTOs - this would need to be implemented based on actual model structure
            let dtos: [ClientDTO] = [] // TODO: Implement conversion
            
            await MainActor.run {
                self.clients = dtos
            }
            logger.info("Fetched clients successfully", metadata: ["count": "\(dtos.count)"])
            return dtos
        } catch {
            logger.error("Failed to fetch clients", metadata: ["error": "\(error)"])
            return []
        }
    }
    
    public func addClient(_ client: ClientDTO) async throws {
        logger.info("Adding client", metadata: ["clientId": "\(client.id)"])
        
        // TODO: Convert DTO to model and insert
        // This would need to be implemented based on actual model structure
        
        try persistenceService.save()
        // TODO: Refresh the list when model integration is complete
        logger.info("Client added successfully", metadata: ["clientId": "\(client.id)"])
    }
    
    public func updateClient(_ client: ClientDTO) async throws {
        logger.info("Updating client", metadata: ["clientId": "\(client.id)"])
        
        // TODO: Find existing model and update from DTO
        
        try persistenceService.save()
        // TODO: Refresh the list when model integration is complete
        logger.info("Client updated successfully", metadata: ["clientId": "\(client.id)"])
    }
    
    public func deleteClient(withId id: UUID) async throws {
        logger.info("Deleting client", metadata: ["clientId": "\(id)"])
        
        // TODO: Find and delete model
        
        try persistenceService.save()
        // TODO: Refresh the list when model integration is complete
        logger.info("Client deleted successfully", metadata: ["clientId": "\(id)"])
    }
}