import Foundation
import SwiftData

@Model
final class ClientModel {
    @Attribute(.unique) var id: UUID = UUID()
    var nom: String = ""
    var entreprise: String = ""
    var email: String = ""
    var telephone: String = ""
    var siret: String = ""
    var numeroTVA: String = ""
    var adresse: String = ""

    // Adresse intégrée
    var adresseRue: String = ""
    var adresseCodePostal: String = ""
    var adresseVille: String = ""
    var adressePays: String = "France"

    // Relation avec Factures
    @Relationship var factures: [FactureModel] = []
    
    init() {}

    var nomCompletClient: String {
        if entreprise.isEmpty {
            return nom
        } else {
            return "\(entreprise) - \(nom)"
        }
    }

    var adresseComplete: String {
        var components: [String] = []

        if !adresseRue.isEmpty {
            components.append(adresseRue)
        }

        var cityLine = ""
        if !adresseCodePostal.isEmpty {
            cityLine += adresseCodePostal
        }
        if !adresseVille.isEmpty {
            if !cityLine.isEmpty { cityLine += " " }
            cityLine += adresseVille
        }
        if !cityLine.isEmpty {
            components.append(cityLine)
        }

        if !adressePays.isEmpty && adressePays != "France" {
            components.append(adressePays)
        }

        return components.joined(separator: "\n")
    }

    var facturesCount: Int {
        factures.count
    }

    var chiffreAffaires: Double {
        factures.filter { $0.statut == .payee }.reduce(0.0) { $0 + $1.sousTotal + $1.montantTVA }
    }
}

// MARK: - Extension de conversion ClientModel <-> ClientDTO
extension ClientModel {
    func toDTO() -> ClientDTO {
        return ClientDTO(
            id: self.id,
            nom: self.nom,
            entreprise: self.entreprise,
            email: self.email,
            telephone: self.telephone,
            siret: self.siret,
            numeroTVA: self.numeroTVA,
            adresse: self.adresse,
            adresseRue: self.adresseRue,
            adresseCodePostal: self.adresseCodePostal,
            adresseVille: self.adresseVille,
            adressePays: self.adressePays
        )
    }

    static func fromDTO(_ dto: ClientDTO) -> ClientModel {
        let client = ClientModel()
        client.id = dto.id
        client.nom = dto.nom
        client.entreprise = dto.entreprise
        client.email = dto.email
        client.telephone = dto.telephone
        client.siret = dto.siret
        client.numeroTVA = dto.numeroTVA
        client.adresse = dto.adresse
        client.adresseRue = dto.adresseRue
        client.adresseCodePostal = dto.adresseCodePostal
        client.adresseVille = dto.adresseVille
        client.adressePays = dto.adressePays
        return client
    }

    func updateFromDTO(_ dto: ClientDTO) {
        nom = dto.nom
        entreprise = dto.entreprise
        email = dto.email
        telephone = dto.telephone
        siret = dto.siret
        numeroTVA = dto.numeroTVA
        adresse = dto.adresse
        adresseRue = dto.adresseRue
        adresseCodePostal = dto.adresseCodePostal
        adresseVille = dto.adresseVille
        adressePays = dto.adressePays
    }
}

// MARK: - Validation
extension ClientModel {
    var isValidModel: Bool {
        return !nom.isEmpty && !email.isEmpty
    }
}
