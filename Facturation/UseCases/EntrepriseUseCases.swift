import Foundation
import DataLayer

/// Use case for fetching enterprise information
@MainActor
final class FetchEntrepriseUseCase {
    private let repository: EntrepriseRepository
    
    init(repository: EntrepriseRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<EntrepriseDTO?, Error> {
        let entreprise = await repository.fetchEntreprise()
        return .success(entreprise)
    }
}

/// Use case for updating enterprise information
@MainActor
final class UpdateEntrepriseUseCase {
    private let repository: EntrepriseRepository
    
    init(repository: EntrepriseRepository) {
        self.repository = repository
    }
    
    func execute(entreprise: EntrepriseDTO) async -> Result<Bool, Error> {
        let success = await repository.updateEntreprise(entreprise)
        return .success(success)
    }
}

/// Use case for creating initial enterprise setup
@MainActor
final class CreateEntrepriseUseCase {
    private let repository: EntrepriseRepository
    
    init(repository: EntrepriseRepository) {
        self.repository = repository
    }
    
    func execute(nom: String, adresse: String, ville: String, codePostal: String, pays: String, siret: String, numeroTVA: String, email: String, telephone: String) async -> Result<Bool, Error> {
        let entreprise = EntrepriseDTO(
            id: UUID(),
            nom: nom,
            telephone: telephone,
            email: email,
            siret: siret,
            numeroTVA: numeroTVA,
            iban: "",
            adresseRue: adresse,
            adresseCodePostal: codePostal,
            adresseVille: ville,
            adressePays: pays,
            certificationTexte: "TVA NON APPLICABLE — ARTICLE 293 B du CGI",
            prefixeFacture: "FAC",
            prochainNumero: 1,
            tvaTauxDefaut: 20.0,
            delaiPaiementDefaut: 30
        )
        
        let success = await repository.createEntreprise(entreprise)
        return .success(success)
    }
}

/// Use case for getting enterprise information by ID
@MainActor
final class GetEntrepriseUseCase {
    private let repository: EntrepriseRepository
    
    init(repository: EntrepriseRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<EntrepriseDTO?, Error> {
        let entreprise = await repository.fetchEntreprise()
        return .success(entreprise)
    }
}