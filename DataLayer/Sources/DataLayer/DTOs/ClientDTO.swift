import Foundation

public struct ClientDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public var nom: String
    public var entreprise: String
    public var email: String
    public var telephone: String
    public var siret: String
    public var numeroTVA: String
    public var adresse: String
    public var adresseRue: String
    public var adresseCodePostal: String
    public var adresseVille: String
    public var adressePays: String
    
    public init(id: UUID, nom: String, entreprise: String, email: String, telephone: String, siret: String, numeroTVA: String, adresse: String, adresseRue: String, adresseCodePostal: String, adresseVille: String, adressePays: String) {
        self.id = id
        self.nom = nom
        self.entreprise = entreprise
        self.email = email
        self.telephone = telephone
        self.siret = siret
        self.numeroTVA = numeroTVA
        self.adresse = adresse
        self.adresseRue = adresseRue
        self.adresseCodePostal = adresseCodePostal
        self.adresseVille = adresseVille
        self.adressePays = adressePays
    }
    
    public var nomCompletClient: String {
        if entreprise.isEmpty {
            return nom
        } else {
            return "\(entreprise) - \(nom)"
        }
    }
    
    public var raisonSociale: String {
        entreprise.isEmpty ? nom : entreprise
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

    /// Adresse ville + code postal sur une ligne
    public var adresseVilleComplete: String {
        var result = ""
        if !adresseCodePostal.isEmpty { result += adresseCodePostal }
        if !adresseVille.isEmpty {
            if !result.isEmpty { result += " " }
            result += adresseVille
        }
        return result
    }

    /// Adresse compacte sur une seule ligne
    public var adresseCompacteLigne: String {
        adresseComplete.replacingOccurrences(of: "\n", with: ", ")
    }
    
    public func facturesCount(from factures: [FactureDTO]) -> Int {
        factures.filter { $0.clientId == self.id }.count
    }
    
    public func chiffreAffaires(from factures: [FactureDTO], lignes: [LigneFactureDTO]) -> Double {
        let clientFactures = factures.filter { 
            $0.clientId == self.id && $0.statut == "Payée"
        }
        return clientFactures.reduce(0.0) { total, facture in
            return total + facture.calculateTotalTTC(with: lignes)
        }
    }
}
// MARK: - Conversion ClientModel → ClientDTO

extension ClientDTO {
    init(from model: ClientModel) {
        self.id = model.id
        self.nom = model.nom
        self.entreprise = model.entreprise
        self.email = model.email
        self.telephone = model.telephone
        self.siret = model.siret
        self.numeroTVA = model.numeroTVA
        self.adresse = model.adresse
        self.adresseRue = model.adresseRue
        self.adresseCodePostal = model.adresseCodePostal
        self.adresseVille = model.adresseVille
        self.adressePays = model.adressePays
    }
}
