// Extensions/Client+Extensions.swift
import Foundation
import AppKit
import DataLayer

// MARK: - Extensions pour le modèle Client SwiftData
extension ClientModel {

    /// Retourne l'adresse complète sur une ligne (pour affichage compact)
    var adresseCompacteLigne: String {
        return adresseComplete.replacingOccurrences(of: "\n", with: ", ")
    }

    /// Retourne l'adresse ville + code postal formatée
    var adresseVilleComplete: String {
        var result = ""
        if !adresseCodePostal.isEmpty {
            result += adresseCodePostal
        }
        if !adresseVille.isEmpty {
            if !result.isEmpty { result += " " }
            result += adresseVille
        }
        return result
    }

    /// Vérifie si le client a une adresse valide
    var hasValidAddress: Bool {
        return !adresseRue.isEmpty || !adresseVille.isEmpty || !adresseCodePostal.isEmpty
    }

    /// Retourne les initiales du client pour l'avatar
    var initiales: String {
        let components = nom.components(separatedBy: " ")
        if components.count >= 2 {
            let firstName = String(components.first?.first ?? "?")
            let lastName = String(components.last?.first ?? "?")
            return "\(firstName)\(lastName)".uppercased()
        } else if let first = nom.first {
            return String(first).uppercased()
        }
        return "?"
    }
    
    /// Retourne les initiales du client pour la numérotation des factures
    /// Utilise prioritairement l'entreprise, sinon le nom du contact
    var initialesFacturation: String {
        let nomPourInitiales = entreprise.isEmpty ? nom : entreprise
        
        let components = nomPourInitiales.components(separatedBy: " ")
        if components.count >= 2 {
            let first = String(components.first?.first ?? "X")
            let last = String(components.last?.first ?? "X")
            return "\(first)\(last)".uppercased()
        } else if let firstChar = nomPourInitiales.first {
            // Si un seul mot, prendre la première lettre + "X"
            return "\(String(firstChar))X".uppercased()
        }
        return "XX"
    }

    /// Retourne le nom d'affichage principal (entreprise ou nom)
    var nomPrincipal: String {
        return entreprise.isEmpty ? nom : entreprise
    }

    /// Retourne le nom secondaire (nom si entreprise existe)
    var nomSecondaire: String? {
        return entreprise.isEmpty ? nil : nom
    }

    /// Vérifie si le client a des informations légales complètes
    var hasLegalInfo: Bool {
        return !siret.isEmpty || !numeroTVA.isEmpty
    }

    /// Vérifie si le client a des informations de contact complètes
    var hasContactInfo: Bool {
        return !email.isEmpty || !telephone.isEmpty
    }

    /// Retourne une description courte du client
    var descriptionCourte: String {
        var parts: [String] = []

        if !entreprise.isEmpty {
            parts.append(entreprise)
        }
        if !nom.isEmpty && entreprise != nom {
            parts.append(nom)
        }
        if !adresseVille.isEmpty {
            parts.append(adresseVille)
        }

        return parts.joined(separator: " • ")
    }

    /// Vérifie si les données du client sont complètes
    var isDataComplete: Bool {
        return !nom.isEmpty &&
        !email.isEmpty &&
        hasValidAddress &&
        hasContactInfo
    }

    /// Score de complétude des données (0-100)
    var completenessScore: Int {
        var score = 0
        let totalFields = 8

        if !nom.isEmpty { score += 1 }
        if !email.isEmpty { score += 1 }
        if !telephone.isEmpty { score += 1 }
        if !adresseRue.isEmpty { score += 1 }
        if !adresseVille.isEmpty { score += 1 }
        if !adresseCodePostal.isEmpty { score += 1 }
        if !siret.isEmpty { score += 1 }
        if !numeroTVA.isEmpty { score += 1 }

        return Int((Double(score) / Double(totalFields)) * 100)
    }
}

// MARK: - Extensions pour la validation
extension ClientModel {

    /// Valide l'email du client
    var isEmailValid: Bool {
        guard !email.isEmpty else { return true } // Email optionnel
        return email.isValidEmail
    }

    /// Valide le SIRET du client
    var isSIRETValid: Bool {
        guard !siret.isEmpty else { return true } // SIRET optionnel
        return siret.isValidSIRET
    }

    /// Valide le numéro de TVA du client
    var isTVAValid: Bool {
        guard !numeroTVA.isEmpty else { return true } // TVA optionnel
        return ValidationHelper.isValidFrenchVAT(numeroTVA)
    }

    /// Retourne les erreurs de validation
    var validationErrors: [String] {
        var errors: [String] = []

        if nom.isEmpty {
            errors.append("Le nom est obligatoire")
        }

        if !isEmailValid {
            errors.append("L'email n'est pas valide")
        }

        if !isSIRETValid {
            errors.append("Le SIRET n'est pas valide")
        }

        if !isTVAValid {
            errors.append("Le numéro de TVA n'est pas valide")
        }

        return errors
    }

    /// Vérifie si le client est valide
    var isValid: Bool {
        return validationErrors.isEmpty
    }
}

// MARK: - Extensions pour l'affichage
extension ClientModel {

    /// Couleur représentative du client (basée sur le nom)
//    var representativeColor: Color {
//        return UtilityFunctions.colorFromString(nomComplet)
//    }

    /// Icône représentative du client
    var representativeIcon: String {
        return entreprise.isEmpty ? "person.circle.fill" : "building.2"
    }

    /// Formatage du téléphone pour l'affichage
    var telephoneFormatted: String {
        return telephone.formattedPhoneNumber
    }

    /// Formatage du SIRET pour l'affichage
    var siretFormatted: String {
        return FormatHelper.formatSIRET(siret)
    }
}

// MARK: - Extensions pour les statistiques
extension ClientModel {

    /// Calcule le nombre de factures payées
    func nombreFacturesPayees() -> Int {
        return factures.filter { $0.statut == .payee }.count
    }

    /// Calcule le nombre de factures en attente
    func nombreFacturesEnAttente() -> Int {
        return factures.filter { $0.statut == .envoyee }.count
    }

    /// Calcule le nombre de factures en retard
    func nombreFacturesEnRetard() -> Int {
        return factures.filter {
            $0.statut == .envoyee && ($0.dateEcheance ?? Date.distantFuture) < Date()
        }.count
    }

    /// Calcule la facture la plus récente
    func factureLaPlusRecente() -> FactureModel? {
        return factures.max { $0.dateFacture < $1.dateFacture }
    }

    /// Calcule la moyenne des montants de factures
    func montantMoyenFactures() -> Double {
        guard !factures.isEmpty else { return 0 }
        let total = factures.reduce(0) { $0 + $1.totalTTC }
        return total / Double(factures.count)
    }

    /// Retourne le délai moyen de paiement (en jours)
    func delaiMoyenPaiement() -> Int {
        let facturesPayees = factures.filter { $0.statut == .payee }
        guard !facturesPayees.isEmpty else { return 0 }

        let totalJours = facturesPayees.reduce(0) { total, facture in
            guard let dateEcheance = facture.dateEcheance else { return total }
            let jours = Calendar.current.dateComponents([.day],
                                                      from: facture.dateFacture,
                                                      to: dateEcheance).day ?? 0
            return total + jours
        }

        return totalJours / facturesPayees.count
    }
}

// MARK: - Extensions pour l'export
extension ClientModel {

    /// Convertit le client en dictionnaire pour l'export
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "nom": nom,
            "entreprise": entreprise,
            "email": email,
            "telephone": telephone,
            "adresse_rue": adresseRue,
            "adresse_code_postal": adresseCodePostal,
            "adresse_ville": adresseVille,
            "adresse_pays": adressePays,
            "siret": siret,
            "numero_tva": numeroTVA,
            "nombre_factures": facturesCount,
            "chiffre_affaires": chiffreAffaires,
            "date_creation": Date().iso8601String
        ]
    }

    /// Convertit le client en CSV row
    func toCSVRow() -> [String] {
        return [
            nom,
            entreprise,
            email,
            telephone,
            adresseCompacteLigne,
            siret,
            numeroTVA,
            String(facturesCount),
            String(format: "%.2f", chiffreAffaires)
        ]
    }

    /// Headers CSV pour l'export
    static var csvHeaders: [String] {
        return [
            "Nom",
            "Entreprise",
            "Email",
            "Téléphone",
            "Adresse",
            "SIRET",
            "Numéro TVA",
            "Nb Factures",
            "CA Total"
        ]
    }
}

// MARK: - Extension Date pour ISO8601
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
