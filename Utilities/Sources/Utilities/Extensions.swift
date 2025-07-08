import SwiftUI
import Foundation
import Logging
import CryptoKit

// MARK: - Double Extensions
public extension Double {
    /// Formate un nombre en euros selon le format français
    var euroFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: NSNumber(value: self)) ?? "0,00 €"
    }

    /// Formate un nombre avec 2 décimales
    var formatted: String {
        return String(format: "%.2f", self)
    }

    /// Formate un pourcentage
    var percentFormatted: String {
        return String(format: "%.1f%%", self)
    }
}

// MARK: - Date Extensions
public extension Date {
    /// Formate une date selon le format français (jj/mm/aaaa)
    var frenchFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }

    /// Formate une date en format court (jj/mm/aa)
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }

    /// Formate une date avec l'heure
    var fullFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }

    /// Vérifie si la date est en retard par rapport à aujourd'hui
    var isOverdue: Bool {
        return self < Date()
    }

    /// Nombre de jours entre cette date et aujourd'hui
    var daysFromNow: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: self).day ?? 0
        return days
    }

    /// Description relative de la date (dans X jours, il y a X jours)
    var relativeDescription: String {
        let days = daysFromNow

        if days == 0 {
            return "Aujourd'hui"
        } else if days == 1 {
            return "Demain"
        } else if days == -1 {
            return "Hier"
        } else if days > 1 {
            return "Dans \(days) jours"
        } else {
            return "Il y a \(abs(days)) jours"
        }
    }

    func moisEtAnnee() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
    
    /// Formate la date en chaîne pour groupement par mois
    func formatToMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: self)
    }
    
    /// Calcule le nombre de jours entre cette date et une autre
    func daysBetween(_ date: Date) -> Double {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: self, to: date).day ?? 0
        return Double(days)
    }
}

// MARK: - String Extensions
public extension String {
    /// Capitalise la première lettre
    var capitalizedFirst: String {
        return prefix(1).capitalized + dropFirst()
    }

    /// Supprime les espaces en début et fin
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Vérifie si la chaîne est un email valide
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    /// Vérifie si la chaîne est un numéro SIRET valide (14 chiffres)
    var isValidSIRET: Bool {
        return count == 14 && allSatisfy { $0.isNumber }
    }

    /// Formate un numéro de téléphone français
    var formattedPhoneNumber: String {
        let cleaned = replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        guard cleaned.count == 10, cleaned.hasPrefix("0") else {
            return self
        }

        let formatted = cleaned.enumerated().compactMap { index, character in
            if index > 0 && index % 2 == 0 {
                return " \(character)"
            }
            return String(character)
        }.joined()

        return formatted
    }
}

// MARK: - Color Extensions
public extension Color {
    /// Couleurs personnalisées de l'application
    static let appBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let appGreen = Color(red: 0.0, green: 0.78, blue: 0.0)
    static let appOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let appRed = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let appGray = Color(red: 0.55, green: 0.55, blue: 0.57)

    /// Initialise une couleur à partir d'un hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Array Extensions
public extension Array {
    /// Accès sécurisé aux éléments du tableau
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - NumberFormatter Extensions
public extension NumberFormatter {
    /// Formatter pour les euros français
    static let euroFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    /// Formatter pour les pourcentages
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    /// Formatter pour les nombres entiers
    static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
}

// MARK: - Calendar Extensions
public extension Calendar {
    /// Calendrier français
    static let french: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "fr_FR")
        calendar.firstWeekday = 2 // Lundi
        return calendar
    }()
}

// MARK: - View Extensions
public extension View {
    /// Applique un modificateur conditionnel
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Ajoute un border conditionnel
    func border(_ color: Color, width: CGFloat, condition: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(condition ? color : Color.clear, lineWidth: width)
        )
    }

    /// Style de carte avec ombre
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    /// Applique un effet de survol
    func hoverEffect() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.2), value: false)
    }
}

// MARK: - Binding Extensions
public extension Binding {
    /// Crée un binding qui transforme la valeur
    func map<T>(
        get: @escaping (Value) -> T,
        set: @escaping (T) -> Value
    ) -> Binding<T> {
        Binding<T>(
            get: { get(self.wrappedValue) },
            set: { self.wrappedValue = set($0) }
        )
    }
}

// MARK: - Locale Extensions
public extension Locale {
    /// Locale français
    static let french = Locale(identifier: "fr_FR")
}

// MARK: - Validation Helpers
public struct ValidationHelper {
    private static let logger = Logger(label: "com.facturation.utilities.validation")
    
    /// Valide un email
    public static func isValidEmail(_ email: String) -> Bool {
        let isValid = email.isValidEmail
        logger.debug("Email validation", metadata: ["email": "\(email)", "valid": "\(isValid)"])
        return isValid
    }

    /// Valide un SIRET
    public static func isValidSIRET(_ siret: String) -> Bool {
        let isValid = siret.isValidSIRET
        logger.debug("SIRET validation", metadata: ["siret": "\(siret)", "valid": "\(isValid)"])
        return isValid
    }

    /// Valide un numéro de TVA français
    public static func isValidFrenchVAT(_ vat: String) -> Bool {
        let pattern = "^FR[0-9]{11}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: vat.count)
        let isValid = regex?.firstMatch(in: vat, options: [], range: range) != nil
        logger.debug("French VAT validation", metadata: ["vat": "\(vat)", "valid": "\(isValid)"])
        return isValid
    }

    /// Valide un IBAN
    public static func isValidIBAN(_ iban: String) -> Bool {
        let cleaned = iban.replacingOccurrences(of: " ", with: "")
        let isValid = cleaned.count >= 15 && cleaned.count <= 34 && cleaned.hasPrefix("FR")
        logger.debug("IBAN validation", metadata: ["iban": "\(iban)", "valid": "\(isValid)"])
        return isValid
    }

    /// Valide un BIC
    public static func isValidBIC(_ bic: String) -> Bool {
        let pattern = "^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: bic.count)
        let isValid = regex?.firstMatch(in: bic, options: [], range: range) != nil
        logger.debug("BIC validation", metadata: ["bic": "\(bic)", "valid": "\(isValid)"])
        return isValid
    }
}

// MARK: - Format Helpers
public struct FormatHelper {
    /// Formate un numéro SIRET avec espaces
    public static func formatSIRET(_ siret: String) -> String {
        let cleaned = siret.replacingOccurrences(of: " ", with: "")
        guard cleaned.count == 14 else { return siret }

        let first = String(cleaned.prefix(3))
        let second = String(cleaned.dropFirst(3).prefix(3))
        let third = String(cleaned.dropFirst(6).prefix(3))
        let fourth = String(cleaned.dropFirst(9).prefix(5))

        return "\(first) \(second) \(third) \(fourth)"
    }

    /// Formate un IBAN avec espaces
    public static func formatIBAN(_ iban: String) -> String {
        let cleaned = iban.replacingOccurrences(of: " ", with: "")
        var formatted = ""

        for (index, character) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }

        return formatted
    }

    /// Formate un numéro de facture
    public static func formatFactureNumber(prefix: String, year: Int, number: Int) -> String {
        return "\(prefix)\(year)-\(String(format: "%04d", number))"
    }
}

// MARK: - Constants
public struct AppConstants {
    /// Délai de paiement par défaut (en jours)
    public static let defaultPaymentDelay = 30

    /// Taux de TVA par défaut
    public static let defaultVATRate = 20.0

    /// Préfixe de facture par défaut
    public static let defaultInvoicePrefix = "F"

    /// Mentions légales obligatoires
    public static let legalMentions = [
        "TVA non applicable, art. 293 B du CGI (si micro-entreprise)",
        "Pénalités de retard: taux d'intérêt légal + 10 points",
        "Indemnité forfaitaire pour frais de recouvrement: 40 €",
        "Escompte pour paiement anticipé: néant",
        "Règlement par chèque non accepté"
    ]

    /// Formats de fichier supportés pour l'export
    public static let supportedExportFormats = ["PDF", "CSV", "JSON"]
}

// MARK: - Math Helpers
public struct MathHelper {
    /// Arrondit un nombre à n décimales
    public static func round(_ value: Double, to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (value * divisor).rounded() / divisor
    }

    /// Calcule le pourcentage entre deux valeurs
    public static func percentage(of value: Double, from total: Double) -> Double {
        guard total != 0 else { return 0 }
        return (value / total) * 100
    }

    /// Calcule la TVA sur un montant HT
    public static func calculateVAT(on amount: Double, rate: Double) -> Double {
        return amount * (rate / 100)
    }

    /// Calcule le montant TTC à partir du HT et du taux de TVA
    public static func calculateTTC(from ht: Double, vatRate: Double) -> Double {
        return ht + calculateVAT(on: ht, rate: vatRate)
    }

    /// Calcule le montant HT à partir du TTC et du taux de TVA
    public static func calculateHT(from ttc: Double, vatRate: Double) -> Double {
        return ttc / (1 + vatRate / 100)
    }
}

// MARK: - Security Helpers
public struct SecurityHelper {
    /// Génère un token de sécurité aléatoire
    public static func generateSecureToken(length: Int = 32) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    /// Hash une chaîne avec SHA256
    public static func sha256(_ input: String) -> String {
        guard let data = input.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Performance Helpers
public struct PerformanceHelper {
    private static let logger = Logger(label: "com.facturation.utilities.performance")
    
    /// Mesure le temps d'exécution d'une closure
    public static func measureTime<T>(operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Operation completed", metadata: ["duration": "\(timeElapsed)s"])
        return (result, timeElapsed)
    }

    /// Exécute une opération avec un délai
    public static func delay(_ seconds: Double, execute: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
    }
}

// MARK: - File Management Helpers
public struct FileManagerHelper {
    private static let logger = Logger(label: "com.facturation.utilities.filemanager")
    
    /// Répertoire de documents de l'application
    public static var documentsDirectory: URL {
        let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    /// Répertoire de cache de l'application
    public static var cacheDirectory: URL {
        let paths = Foundation.FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }

    /// Crée un répertoire s'il n'existe pas
    public static func createDirectoryIfNeeded(at url: URL) throws {
        if !Foundation.FileManager.default.fileExists(atPath: url.path) {
            try Foundation.FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            logger.info("Directory created", metadata: ["path": "\(url.path)"])
        }
    }

    /// Sauvegarde des données JSON dans un fichier
    public static func saveJSON<T: Codable>(_ data: T, to fileName: String) throws {
        let url = documentsDirectory.appendingPathComponent(fileName)
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: url)
        logger.info("JSON data saved", metadata: ["fileName": "\(fileName)", "size": "\(encoded.count) bytes"])
    }

    /// Charge des données JSON depuis un fichier
    public static func loadJSON<T: Codable>(_ type: T.Type, from fileName: String) throws -> T {
        let url = documentsDirectory.appendingPathComponent(fileName)
        let data = try Data(contentsOf: url)
        let result = try JSONDecoder().decode(type, from: data)
        logger.info("JSON data loaded", metadata: ["fileName": "\(fileName)", "size": "\(data.count) bytes"])
        return result
    }
}