//
//  ClientDTO.swift
//  Facturation
//
//  Created by Young Slim on 06/07/2025.
//
import Foundation

struct ClientDTO: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    var nom: String
    var entreprise: String
    var email: String
    var telephone: String
    var siret: String
    var numeroTVA: String
    var adresse: String
    var adresseRue: String
    var adresseCodePostal: String
    var adresseVille: String
    var adressePays: String
    
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

    /// Adresse ville + code postal sur une ligne
    var adresseVilleComplete: String {
        var result = ""
        if !adresseCodePostal.isEmpty { result += adresseCodePostal }
        if !adresseVille.isEmpty {
            if !result.isEmpty { result += " " }
            result += adresseVille
        }
        return result
    }

    /// Adresse compacte sur une seule ligne
    var adresseCompacteLigne: String {
        adresseComplete.replacingOccurrences(of: "\n", with: ", ")
    }
    
    func facturesCount(from factures: [FactureDTO]) -> Int {
        factures.filter { $0.clientId == self.id }.count
    }
    
    func chiffreAffaires(from factures: [FactureDTO], lignes: [LigneFactureDTO]) -> Double {
        let clientFactures = factures.filter { 
            $0.clientId == self.id && $0.statut == "Payée"
        }
        return clientFactures.reduce(0.0) { total, facture in
            return total + facture.calculateTotalTTC(with: lignes)
        }
    }
}

// DTO conversion methods are now in DataService.swift to avoid duplicates
