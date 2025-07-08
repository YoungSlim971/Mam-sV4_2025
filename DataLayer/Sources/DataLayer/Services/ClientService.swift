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
    
    /// Fetch all clients sorted by name
    public func fetchClients() async -> [ClientDTO] {
        logger.info("Fetching clients")
        do {
            let descriptor = FetchDescriptor<ClientModel>(sortBy: [SortDescriptor(\ClientModel.nom)])
            let models: [ClientModel] = try persistenceService.fetch(descriptor)
            let dtos = models.map { $0.toDTO() }

            await MainActor.run { self.clients = dtos }
            logger.info("Fetched clients successfully", metadata: ["count": "\(dtos.count)"])
            return dtos
        } catch {
            logger.error("Failed to fetch clients", metadata: ["error": "\(error)"])
            return []
        }
    }

    public func addClient(_ client: ClientDTO) async throws {
        logger.info("Adding client", metadata: ["clientId": "\(client.id)"])

        guard !client.siret.isEmpty, !client.numeroTVA.isEmpty else {
            logger.warning("Invalid client identifiers", metadata: ["clientId": "\(client.id)"])
            return
        }

        let model = ClientModel.fromDTO(client)
        persistenceService.insert(model)
        try persistenceService.save()
        await fetchClients()
        logger.info("Client added successfully", metadata: ["clientId": "\(client.id)"])
    }

    public func updateClient(_ client: ClientDTO) async throws {
        logger.info("Updating client", metadata: ["clientId": "\(client.id)"])

        guard !client.siret.isEmpty, !client.numeroTVA.isEmpty else {
            logger.warning("Invalid client identifiers", metadata: ["clientId": "\(client.id)"])
            return
        }

        let descriptor = FetchDescriptor<ClientModel>(predicate: #Predicate { $0.id == client.id })
        if let existing = try? persistenceService.fetch(descriptor).first {
            existing.updateFromDTO(client)
            try persistenceService.save()
            await fetchClients()
            logger.info("Client updated successfully", metadata: ["clientId": "\(client.id)"])
        } else {
            logger.warning("Client not found", metadata: ["clientId": "\(client.id)"])
        }
    }

    public func deleteClient(withId id: UUID) async throws {
        logger.info("Deleting client", metadata: ["clientId": "\(id)"])

        let clientDescriptor = FetchDescriptor<ClientModel>(predicate: #Predicate { $0.id == id })
        guard let client = try? persistenceService.fetch(clientDescriptor).first, client.isValidModel else {
            logger.warning("Client not found", metadata: ["clientId": "\(id)"])
            return
        }

        // Delete invoices associated with this client
        let factureDescriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { $0.client?.id == id })
        let factures = (try? persistenceService.fetch(factureDescriptor)) ?? []
        for facture in factures where facture.isValidModel {
            for ligne in facture.lignes { persistenceService.delete(ligne) }
            persistenceService.delete(facture)
        }

        persistenceService.delete(client)
        try persistenceService.save()
        await fetchClients()
        logger.info("Client deleted successfully", metadata: ["clientId": "\(id)"])
    }
}