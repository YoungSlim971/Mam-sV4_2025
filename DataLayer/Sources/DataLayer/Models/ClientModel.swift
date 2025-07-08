import Foundation
import SwiftData
import Utilities

@Model
public final class ClientModel {
    @Attribute(.unique) public var id: UUID = UUID()
    public var nom: String = ""
    public var entreprise: String = ""
    public var email: String = ""
    public var telephone: String = ""
    public var siret: String = ""
    public var numeroTVA: String = ""
    public var adresse: String = ""

    // Adresse intégrée
    public var adresseRue: String = ""
    public var adresseCodePostal: String = ""
    public var adresseVille: String = ""
    public var adressePays: String = "France"

    // Relation avec Factures
    @Relationship public var factures: [FactureModel] = []
    
    init() {}

    public var nomCompletClient: String {
        if entreprise.isEmpty {
            return nom
        } else {
            return "\(entreprise) - \(nom)"
        }
    }

    public var adresseComplete: String {
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

    public var facturesCount: Int {
        factures.count
    }

    public var chiffreAffaires: Double {
        factures.filter { $0.statut == .payee }.reduce(0.0) { $0 + $1.sousTotal + $1.montantTVA }
    }
    
    public var initialesFacturation: String {
        let nomInitial = nom.isEmpty ? "" : String(nom.prefix(1)).uppercased()
        let entrepriseInitial = entreprise.isEmpty ? "" : String(entreprise.prefix(1)).uppercased()
        
        if !entrepriseInitial.isEmpty {
            return entrepriseInitial + (nomInitial.isEmpty ? "" : nomInitial)
        } else {
            return nomInitial.isEmpty ? "XX" : nomInitial
        }
    }
}

// MARK: - Validation
extension ClientModel {
    public var isValidModel: Bool {
        return !nom.isEmpty && !email.isEmpty
    }
}
