import Foundation
import SwiftData

@Model
public final class EntrepriseModel {
    @Attribute(.unique) public var id: UUID = UUID()
    public var nom: String = ""
    public var nomContact: String? = nil
    public var nomDirigeant: String? = nil
    public var telephone: String = ""
    public var email: String = ""
    public var siret: String = ""
    public var numeroTVA: String = ""
    public var iban: String = ""
    public var bic: String? = nil
    
    // Adresse de l'entreprise
    public var adresseRue: String = ""
    public var adresseCodePostal: String = ""
    public var adresseVille: String = ""
    public var adressePays: String = ""
    // Certification éventuelle (ex : « Certification Biologique »)
    public var certificationTexte: String = ""
    // Domaine d'activité de l'entreprise
    public var domaine: String? = nil
    
    // Logo de l'entreprise (optionnel)
    public var logo: Data? = nil
    
    // Paramètres de facturation
    public var prefixeFacture: String = ""
    public var prochainNumero: Int = 1
    public var tvaTauxDefaut: Double = 20.0
    public var delaiPaiementDefaut: Int = 30 // en jours

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

        if !adressePays.isEmpty {
            components.append(adressePays)
        }

        return components.joined(separator: "\n")
    }

    public func genererNumeroFacture(client: ClientModel) -> String {
        let currentDate = Date()
        let currentMonth = Calendar.current.component(.month, from: currentDate)
        let currentYear = Calendar.current.component(.year, from: currentDate) % 100 // Derniers 2 chiffres de l'année
        
        let monthStr = String(format: "%02d", currentMonth)
        let yearStr = String(format: "%02d", currentYear)
        let numeroStr = String(format: "%04d", prochainNumero)
        let clientInitials = client.initialesFacturation
        
        let numero = "\(monthStr)/\(yearStr)-\(numeroStr)-\(clientInitials)"
        prochainNumero += 1
        return numero
    }

    public func resetNumerotationAnnuelle() {
        _ = Calendar.current.component(.year, from: Date())
        // Reset si nouvelle année
        prochainNumero = 1
    }
}

