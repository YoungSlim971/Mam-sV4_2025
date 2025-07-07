import Foundation
import SwiftData

@Model
final class EntrepriseModel {
    @Attribute(.unique) var id: UUID = UUID()
    var nom: String = ""
    var nomContact: String? = nil
    var nomDirigeant: String? = nil
    var telephone: String = ""
    var email: String = ""
    var siret: String = ""
    var numeroTVA: String = ""
    var iban: String = ""
    var bic: String? = nil
    
    // Adresse de l'entreprise
    var adresseRue: String = ""
    var adresseCodePostal: String = ""
    var adresseVille: String = ""
    var adressePays: String = ""
    // Certification éventuelle (ex : « Certification Biologique »)
    var certificationTexte: String = ""
    
    // Logo de l'entreprise (optionnel)
    var logo: Data? = nil
    
    // Paramètres de facturation
    var prefixeFacture: String = ""
    var prochainNumero: Int = 1
    var tvaTauxDefaut: Double = 20.0
    var delaiPaiementDefaut: Int = 30 // en jours

    init() {
        self.nom = "ExoTROPIC"
        self.telephone = "0690 01 02 03"
        self.email = "entreprise@example.com"
        self.siret = "123 45 67 89"
        self.numeroTVA = "123 45 67 89"
        self.iban = "12345678901234567890"
        self.bic = "FREDEF12345"
        self.adresseRue = "1 Rue de l'Exemple"
        self.adresseCodePostal = "97 100"
        self.adresseVille = "SunCity"
        self.adressePays = "Guadeloupe"
        self.certificationTexte = "Certification Biologique"
        self.prefixeFacture = "F"
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

        if !adressePays.isEmpty {
            components.append(adressePays)
        }

        return components.joined(separator: "\n")
    }

    func genererNumeroFacture() -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let numero = String(format: "%@%04d-%04d", prefixeFacture, currentYear, prochainNumero)
        prochainNumero += 1
        return numero
    }

    func resetNumerotationAnnuelle() {
        _ = Calendar.current.component(.year, from: Date())
        // Reset si nouvelle année
        prochainNumero = 1
    }
}

// MARK: - Extension de conversion EntrepriseModel <-> EntrepriseDTO
extension EntrepriseModel {
    func toDTO() -> EntrepriseDTO {
        return EntrepriseDTO(
            id: self.id,
            nom: self.nom,
            nomContact: self.nomContact,
            nomDirigeant: self.nomDirigeant,
            telephone: self.telephone,
            email: self.email,
            siret: self.siret,
            numeroTVA: self.numeroTVA,
            iban: self.iban,
            bic: self.bic,
            adresseRue: self.adresseRue,
            adresseCodePostal: self.adresseCodePostal,
            adresseVille: self.adresseVille,
            adressePays: self.adressePays,
            certificationTexte: self.certificationTexte,
            logo: self.logo,
            prefixeFacture: self.prefixeFacture,
            prochainNumero: self.prochainNumero,
            tvaTauxDefaut: self.tvaTauxDefaut,
            delaiPaiementDefaut: self.delaiPaiementDefaut
        )
    }

    static func fromDTO(_ dto: EntrepriseDTO) -> EntrepriseModel {
        let entreprise = EntrepriseModel()
        entreprise.id = dto.id
        entreprise.nom = dto.nom
        entreprise.adresseRue = dto.adresseRue
        entreprise.adresseCodePostal = dto.adresseCodePostal
        entreprise.adresseVille = dto.adresseVille
        entreprise.adressePays = dto.adressePays
        entreprise.email = dto.email
        entreprise.telephone = dto.telephone
        entreprise.siret = dto.siret
        entreprise.numeroTVA = dto.numeroTVA
        entreprise.prefixeFacture = dto.prefixeFacture
        entreprise.iban = dto.iban
        entreprise.bic = dto.bic
        entreprise.logo = dto.logo
        return entreprise
    }

    func updateFromDTO(_ dto: EntrepriseDTO) {
        nom = dto.nom
        adresseRue = dto.adresseRue
        adresseCodePostal = dto.adresseCodePostal
        adresseVille = dto.adresseVille
        adressePays = dto.adressePays
        email = dto.email
        telephone = dto.telephone
        siret = dto.siret
        numeroTVA = dto.numeroTVA
        prefixeFacture = dto.prefixeFacture
        iban = dto.iban
        bic = dto.bic
        logo = dto.logo
    }
}