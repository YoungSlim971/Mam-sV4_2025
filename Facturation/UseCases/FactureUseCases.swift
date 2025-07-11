import Foundation
import DataLayer

/// Use case for fetching all invoices
@MainActor
final class FetchFacturesUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<[FactureDTO], Error> {
        do {
            let factures = await repository.fetchFactures()
            return .success(factures)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for creating a new invoice
@MainActor
final class CreateFactureUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(clientId: UUID, tva: Double = 20.0) async -> Result<FactureDTO, Error> {
        do {
            let numero = await repository.genererNumeroFacture()
            let facture = FactureDTO(
                id: UUID(),
                numero: numero,
                dateFacture: Date(),
                dateEcheance: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                datePaiement: nil,
                tva: tva,
                conditionsPaiement: "virement",
                remisePourcentage: 0.0,
                statut: StatutFacture.brouillon.rawValue,
                notes: "",
                notesCommentaireFacture: nil,
                clientId: clientId,
                ligneIds: []
            )
            
            let success = await repository.addFacture(facture)
            if success {
                return .success(facture)
            } else {
                return .failure(NSError(domain: "CreateFactureUseCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create invoice"]))
            }
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for updating an invoice
@MainActor
final class UpdateFactureUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(facture: FactureDTO) async -> Result<Bool, Error> {
        do {
            let success = await repository.updateFacture(facture)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for deleting an invoice
@MainActor
final class DeleteFactureUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(factureId: UUID) async -> Result<Bool, Error> {
        do {
            let success = await repository.deleteFacture(id: factureId)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for searching invoices
@MainActor
final class SearchFacturesUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(searchText: String) async -> Result<[FactureDTO], Error> {
        do {
            let factures = await repository.searchFactures(searchText: searchText)
            return .success(factures)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for getting invoices by status
@MainActor
final class GetFacturesByStatusUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(status: StatutFacture) async -> Result<[FactureDTO], Error> {
        do {
            let factures = await repository.getFacturesByStatus(status: status)
            return .success(factures)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for getting invoices by date range
@MainActor
final class GetFacturesByDateRangeUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(startDate: Date, endDate: Date) async -> Result<[FactureDTO], Error> {
        do {
            let factures = await repository.getFacturesByDateRange(startDate: startDate, endDate: endDate)
            return .success(factures)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for getting invoices for a specific client
@MainActor
final class GetFacturesForClientUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(clientId: UUID) async -> Result<[FactureDTO], Error> {
        do {
            let factures = await repository.getFacturesForClient(clientId: clientId)
            return .success(factures)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for getting a specific invoice
@MainActor
final class GetFactureUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(id: UUID) async -> Result<FactureDTO?, Error> {
        do {
            let facture = await repository.getFacture(id: id)
            return .success(facture)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Ligne Facture Use Cases

/// Use case for fetching all ligne factures
@MainActor
final class FetchLignesUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<[LigneFactureDTO], Error> {
        do {
            let lignes = await repository.fetchLignes()
            return .success(lignes)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for adding a ligne facture
@MainActor
final class AddLigneUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(ligne: LigneFactureDTO) async -> Result<Bool, Error> {
        do {
            let success = await repository.addLigne(ligne)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for updating a ligne facture
@MainActor
final class UpdateLigneUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(ligne: LigneFactureDTO) async -> Result<Bool, Error> {
        do {
            let success = await repository.updateLigne(ligne)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for deleting a ligne facture
@MainActor
final class DeleteLigneUseCase {
    private let repository: FactureRepository
    
    init(repository: FactureRepository) {
        self.repository = repository
    }
    
    func execute(id: UUID) async -> Result<Bool, Error> {
        do {
            let success = await repository.deleteLigne(id: id)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
}