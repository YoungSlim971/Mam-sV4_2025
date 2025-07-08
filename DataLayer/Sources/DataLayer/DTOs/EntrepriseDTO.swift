import Foundation

public struct EntrepriseDTO: Codable, Sendable, Identifiable {
    public var id: UUID
    public var nom: String
    public var nomContact: String?
    public var nomDirigeant: String?
    public var telephone: String
    public var email: String
    public var siret: String
    public var numeroTVA: String
    public var iban: String
    public var bic: String?
    public var adresseRue: String
    public var adresseCodePostal: String
    public var adresseVille: String
    public var adressePays: String
    public var certificationTexte: String
    public var logo: Data?
    public var prefixeFacture: String
    public var prochainNumero: Int
    public var tvaTauxDefaut: Double
    public var delaiPaiementDefaut: Int
    public var domaine: String?
    
    public init(id: UUID, nom: String, nomContact: String? = nil, nomDirigeant: String? = nil, telephone: String, email: String, siret: String, numeroTVA: String, iban: String, bic: String? = nil, adresseRue: String, adresseCodePostal: String, adresseVille: String, adressePays: String, certificationTexte: String, logo: Data? = nil, prefixeFacture: String, prochainNumero: Int, tvaTauxDefaut: Double, delaiPaiementDefaut: Int, domaine: String? = nil) {
        self.id = id
        self.nom = nom
        self.nomContact = nomContact
        self.nomDirigeant = nomDirigeant
        self.telephone = telephone
        self.email = email
        self.siret = siret
        self.numeroTVA = numeroTVA
        self.iban = iban
        self.bic = bic
        self.adresseRue = adresseRue
        self.adresseCodePostal = adresseCodePostal
        self.adresseVille = adresseVille
        self.adressePays = adressePays
        self.certificationTexte = certificationTexte
        self.logo = logo
        self.prefixeFacture = prefixeFacture
        self.prochainNumero = prochainNumero
        self.tvaTauxDefaut = tvaTauxDefaut
        self.delaiPaiementDefaut = delaiPaiementDefaut
        self.domaine = domaine
    }
}