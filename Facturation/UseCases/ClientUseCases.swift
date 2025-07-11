import Foundation
import DataLayer

/// Use case for fetching all clients
@MainActor
final class FetchClientsUseCase {
    private let repository: ClientRepository
    
    init(repository: ClientRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<[ClientDTO], Error> {
        do {
            let clients = await repository.fetchClients()
            return .success(clients)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for adding a new client
@MainActor
final class AddClientUseCase {
    private let repository: ClientRepository
    
    init(repository: ClientRepository) {
        self.repository = repository
    }
    
    func execute(nom: String, prenom: String, email: String, telephone: String, adresse: String, ville: String, codePostal: String, pays: String, siret: String?, tva: String?) async -> Result<UUID, Error> {
        let clientId = UUID()
        let client = ClientDTO(
            id: clientId,
            nom: nom,
            entreprise: prenom, // Using prenom as entreprise for simplicity
            email: email,
            telephone: telephone,
            siret: siret ?? "",
            numeroTVA: tva ?? "",
            adresse: adresse,
            adresseRue: adresse,
            adresseCodePostal: codePostal,
            adresseVille: ville,
            adressePays: pays
        )
        
        let success = await repository.addClient(client)
        if success {
            return .success(clientId)
        } else {
            return .failure(NSError(domain: "AddClientUseCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to add client"]))
        }
    }
}

/// Use case for updating a client
@MainActor
final class UpdateClientUseCase {
    private let repository: ClientRepository
    
    init(repository: ClientRepository) {
        self.repository = repository
    }
    
    func execute(client: ClientDTO) async -> Result<Bool, Error> {
        do {
            let success = await repository.updateClient(client)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for deleting a client
@MainActor
final class DeleteClientUseCase {
    private let repository: ClientRepository
    
    init(repository: ClientRepository) {
        self.repository = repository
    }
    
    func execute(clientId: UUID) async -> Result<Bool, Error> {
        do {
            let success = await repository.deleteClient(id: clientId)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for searching clients
@MainActor
final class SearchClientsUseCase {
    private let repository: ClientRepository
    
    init(repository: ClientRepository) {
        self.repository = repository
    }
    
    func execute(searchText: String) async -> Result<[ClientDTO], Error> {
        do {
            let clients = await repository.searchClients(searchText: searchText)
            return .success(clients)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for getting a specific client
@MainActor
final class GetClientUseCase {
    private let repository: ClientRepository
    
    init(repository: ClientRepository) {
        self.repository = repository
    }
    
    func execute(clientId: UUID) async -> Result<ClientDTO?, Error> {
        do {
            let client = await repository.getClient(id: clientId)
            return .success(client)
        } catch {
            return .failure(error)
        }
    }
}
