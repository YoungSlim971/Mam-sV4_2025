
import Foundation

struct Validator {

    /// Valide un numéro SIRET en utilisant l'algorithme de Luhn.
    /// - Parameter siret: Le numéro SIRET à valider.
    /// - Returns: `true` si le SIRET est valide, `false` sinon.
    static func isValidSIRET(_ siret: String) -> Bool {
        let cleanedSiret = siret.filter(\.isWholeNumber)

        guard cleanedSiret.count == 14 else {
            return false
        }

        // Algorithme de Luhn
        var sum = 0
        let reversedSiret = String(cleanedSiret.reversed())

        for (index, char) in reversedSiret.enumerated() {
            guard let digit = Int(String(char)) else { return false }

            if index % 2 == 1 { // Chiffres de rang impair (en partant de la droite, donc 2ème, 4ème, etc.)
                var doubledDigit = digit * 2
                if doubledDigit > 9 {
                    doubledDigit -= 9
                }
                sum += doubledDigit
            } else { // Chiffres de rang pair
                sum += digit
            }
        }
        return sum % 10 == 0
    }

    /// Valide un numéro de TVA intracommunautaire français (FR + 11 chiffres).
    /// - Parameter tva: Le numéro de TVA à valider.
    /// - Returns: `true` si le numéro de TVA est valide, `false` sinon.
    static func isValidTVA(_ tva: String) -> Bool {
        let cleanedTVA = tva.uppercased().filter { !$0.isWhitespace }

        // Regex pour "FR" suivi de 11 caractères (chiffres ou lettres pour la clé)
        // La clé TVA française est composée de 2 chiffres calculés à partir du SIREN.
        // Pour une validation simple, on vérifie le format FR + 11 caractères alphanumériques.
        // Une validation plus poussée nécessiterait le SIREN pour calculer la clé.
        let tvaRegex = #"^FR[0-9A-Z]{2}[0-9]{9}$"#
        
        guard cleanedTVA.range(of: tvaRegex, options: .regularExpression) != nil else {
            return false
        }
        
        // Optionnel: Vérification de la clé (plus complexe, nécessite le SIREN)
        // Pour l'instant, on se contente du format.
        // Si le SIREN est disponible, on pourrait faire:
        // let siren = String(cleanedTVA.suffix(9))
        // let key = Int(cleanedTVA[cleanedTVA.index(cleanedTVA.startIndex, offsetBy: 2)..<cleanedTVA.index(cleanedTVA.startIndex, offsetBy: 4)])
        // let calculatedKey = (siren.toLongLong() * 12 + 3) % 97
        // return key == calculatedKey
        
        return true
    }

    /// Valide un numéro IBAN en utilisant l'algorithme Modulo 97.
    /// - Parameter iban: Le numéro IBAN à valider.
    /// - Returns: `true` si l'IBAN est valide, `false` sinon.
    static func isValidIBAN(_ iban: String) -> Bool {
        let cleanedIBAN = iban.uppercased().filter { !$0.isWhitespace }

        guard cleanedIBAN.count >= 15 else { // IBAN minimum length is 15 (e.g., QA21 QNBA 0000 0000 0000 0000 0000 00)
            return false
        }

        // Déplacer les 4 premiers caractères à la fin
        let rearrangedIBAN = String(cleanedIBAN.dropFirst(4)) + String(cleanedIBAN.prefix(4))

        // Convertir les lettres en chiffres (A=10, B=11, ..., Z=35)
        var numericString = ""
        for char in rearrangedIBAN {
            if char.isLetter {
                if let asciiValue = char.asciiValue {
                    numericString += String(asciiValue - 55) // 'A' is 65, so 65-55 = 10
                }
            } else {
                numericString += String(char)
            }
        }

        // Effectuer l'opération modulo 97
        // On traite la chaîne numérique par blocs pour éviter les dépassements d'entiers
        var remainder = 0
        for digitChar in numericString {
            guard let digit = Int(String(digitChar)) else { return false }
            remainder = (remainder * 10 + digit) % 97
        }

        return remainder == 1
    }
}
