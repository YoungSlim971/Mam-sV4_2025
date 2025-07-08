import Foundation
import SwiftData
import Logging

@MainActor
public final class FactureService: ObservableObject {
    private let logger = Logger(label: "com.facturation.datalayer.facture")
    private let persistenceService: PersistenceService
    
    @Published public var factures: [FactureDTO] = []
    
    public init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
    }
    
    /// Fetch all invoices sorted by date (newest first)
    public func fetchFactures() async -> [FactureDTO] {
        logger.info("Fetching factures")
        do {
            let descriptor = FetchDescriptor<FactureModel>(sortBy: [SortDescriptor(\FactureModel.dateFacture, order: .reverse)])
            let models: [FactureModel] = try persistenceService.fetch(descriptor)
            let dtos = models.map { $0.toDTO() }

            await MainActor.run { self.factures = dtos }
            logger.info("Fetched factures successfully", metadata: ["count": "\(dtos.count)"])
            return dtos
        } catch {
            logger.error("Failed to fetch factures", metadata: ["error": "\(error)"])
            return []
        }
    }
    
    public func addFacture(_ facture: FactureDTO) async throws {
        logger.info("Adding facture", metadata: ["factureId": "\(facture.id)", "numero": "\(facture.numero)"])

        let clientDescriptor = FetchDescriptor<ClientModel>(predicate: #Predicate { $0.id == facture.clientId })
        let client = try? persistenceService.fetch(clientDescriptor).first

        let ligneDescriptor = FetchDescriptor<LigneFacture>(predicate: #Predicate { ligne in
            facture.ligneIds.contains(ligne.id)
        })
        let lignes = (try? persistenceService.fetch(ligneDescriptor)) ?? []

        _ = FactureModel.fromDTO(facture, context: persistenceService.modelContext, client: client, lignes: lignes)
        try persistenceService.save()
        await fetchFactures()
        logger.info("Facture added successfully", metadata: ["factureId": "\(facture.id)"])
    }
    
    public func updateFacture(_ facture: FactureDTO) async throws {
        logger.info("Updating facture", metadata: ["factureId": "\(facture.id)", "numero": "\(facture.numero)"])

        let descriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { $0.id == facture.id })
        if let existing = try? persistenceService.fetch(descriptor).first {
            existing.updateFromDTO(facture)
            try persistenceService.save()
            await fetchFactures()
            logger.info("Facture updated successfully", metadata: ["factureId": "\(facture.id)"])
        } else {
            logger.warning("Facture not found", metadata: ["factureId": "\(facture.id)"])
        }
    }
    
    public func deleteFacture(withId id: UUID) async throws {
        logger.info("Deleting facture", metadata: ["factureId": "\(id)"])

        let descriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { $0.id == id })
        guard let facture = try? persistenceService.fetch(descriptor).first, facture.isValidModel else {
            logger.warning("Facture not found", metadata: ["factureId": "\(id)"])
            return
        }

        for ligne in facture.lignes { persistenceService.delete(ligne) }
        persistenceService.delete(facture)
        try persistenceService.save()
        await fetchFactures()
        logger.info("Facture deleted successfully", metadata: ["factureId": "\(id)"])
    }
    
    public func generateInvoiceNumber(for clientId: UUID, year: Int? = nil) async throws -> String {
        let currentYear = year ?? Calendar.current.component(.year, from: Date())
        
        logger.info("Generating invoice number", metadata: ["clientId": "\(clientId)", "year": "\(currentYear)"])
        
        let descriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { facture in
            facture.client?.id == clientId && Calendar.current.component(.year, from: facture.dateFacture) == currentYear
        })
        let factures = (try? persistenceService.fetch(descriptor)) ?? []
        let nextNumber = (factures.count + 1)

        let invoiceNumber = "F\(currentYear)-\(String(format: "%04d", nextNumber))"
        logger.info("Generated invoice number", metadata: ["number": "\(invoiceNumber)"])

        return invoiceNumber
    }
    
    public func updateFactureStatus(_ factureId: UUID, to status: StatutFacture) async throws {
        logger.info("Updating facture status", metadata: ["factureId": "\(factureId)", "status": "\(status.rawValue)"])
        
        let descriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { $0.id == factureId })
        if let facture = try? persistenceService.fetch(descriptor).first {
            facture.statut = status
            try persistenceService.save()
            await fetchFactures()
            logger.info("Facture status updated successfully", metadata: ["factureId": "\(factureId)"])
        } else {
            logger.warning("Facture not found", metadata: ["factureId": "\(factureId)"])
        }
    }
}