//
//  LigneFactureDTO.swift
//
import Foundation

struct EntrepriseDTO: Codable, Sendable, Identifiable {
    var id: UUID
    var nom: String
    var nomContact: String?
    var nomDirigeant: String?
    var telephone: String
    var email: String
    var siret: String
    var numeroTVA: String
    var iban: String
    var bic: String?
    var adresseRue: String
    var adresseCodePostal: String
    var adresseVille: String
    var adressePays: String
    var certificationTexte: String
    var logo: Data?
    var prefixeFacture: String
    var prochainNumero: Int
    var tvaTauxDefaut: Double
    var delaiPaiementDefaut: Int
    var domaine: String? // Added domaine field
}


