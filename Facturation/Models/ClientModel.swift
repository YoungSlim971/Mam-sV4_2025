import Foundation
import SwiftData
import DataLayer

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

// MARK: - Validation
extension ClientModel {
    var isValidModel: Bool {
        return !nom.isEmpty && !email.isEmpty
    }
}
